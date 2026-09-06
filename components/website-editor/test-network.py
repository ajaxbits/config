"""Packet-level regression tests for the component's default network settings.

Invoked by check-grace-editor-network inside NEW mount/network/PID namespaces.
No real network, Docker, Kubernetes, or Tailscale services are contacted.
"""

import json
import os
from pathlib import Path
import subprocess
import sys


def run(*args, input=None, ns=None):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    result = subprocess.run(prefix + list(args), input=input, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f"{prefix + list(args)} failed:\n{result.stderr}")
    return result.stdout


def ip(*args, ns=None):
    return run("ip", *args, ns=ns)


def check(label, condition):
    if not condition:
        raise AssertionError(label)
    print(f"PASS: {label}", flush=True)


def tcp(ns, address, port, allowed=True, source=None, payload="hello", expected="hello"):
    code = """
import socket, sys
s = socket.socket()
s.settimeout(0.6)
if sys.argv[3]: s.bind((sys.argv[3], 0))
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
    s.sendall(sys.argv[4].encode())
    result = s.recv(100).decode()
except OSError:
    result = 'blocked'
print(result)
"""
    result = run(sys.executable, "-c", code, address, str(port), source or "", payload, ns=ns).strip()
    check(
        f"{ns or 'host'} -> {address}:{port} {'allowed' if allowed else 'blocked'}"
        + (f" (source {source})" if source else ""),
        result == (expected if allowed else "blocked"),
    )


SERVER = """
import socket, sys, threading
def serve(port):
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', port))
    s.listen()
    def reply(conn):
        with conn:
            while data := conn.recv(100):
                response = sys.argv[1].encode() if data == b'who' else conn.getpeername()[0].encode() if data == b'peer' else data
                conn.sendall(response)
    def accept():
        while True:
            conn, _ = s.accept()
            threading.Thread(target=reply, args=(conn,), daemon=True).start()
    threading.Thread(target=accept, daemon=True).start()
for port in map(int, sys.argv[2:]):
    serve(port)
    print('ready', flush=True)
threading.Event().wait()
"""


def server(ns, *ports):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    process = subprocess.Popen(
        prefix + [sys.executable, "-u", "-c", SERVER, ns or "host", *map(str, ports)],
        stdout=subprocess.PIPE, text=True,
    )
    for _ in ports:
        if process.stdout.readline().strip() != "ready":
            raise RuntimeError("echo server failed to start")
    return process


def topology():
    # Fail rather than run against a populated (potentially host) namespace.
    links = json.loads(ip("-j", "link"))
    check("fresh isolated network namespace", [link["ifname"] for link in links] == ["lo"])
    check("fresh isolated PID namespace", os.getpid() == 1)
    run("mount", "--make-rprivate", "/")
    run("mount", "-t", "tmpfs", "tmpfs", "/run")
    Path("/run/netns").mkdir()
    ip("link", "set", "lo", "up")
    for bridge, address in [("br0", "172.22.0.10/15"), ("agentbr0", "192.168.83.1/24")]:
        ip("link", "add", bridge, "type", "bridge")
        ip("address", "add", address, "dev", bridge)
        ip("link", "set", bridge, "up")

    # guest uses the actual agent-grace bridge port; the other namespaces
    # represent LAN, the upstream router/Internet, and a VPN peer.
    for ns, tap, bridge, address in [
        ("guest", "agent-grace", "agentbr0", "192.168.83.2/24"),
        ("lan", "lan-link", "br0", "172.22.0.20/15"),
        ("wan", "wan-link", "br0", "172.22.0.1/15"),
        ("vpn", "tailscale0", None, "100.64.0.2/30"),
    ]:
        ip("netns", "add", ns)
        ip("link", "add", tap, "type", "veth", "peer", "name", "eth0", "netns", ns)
        if bridge:
            ip("link", "set", tap, "master", bridge)
        else:
            ip("address", "add", "100.64.0.1/30", "dev", tap)
        ip("link", "set", tap, "up")
        ip("link", "set", "lo", "up", ns=ns)
        ip("link", "set", "eth0", "up", ns=ns)
        ip("address", "add", address, "dev", "eth0", ns=ns)

    Path("/proc/sys/net/ipv4/ip_forward").write_text("1")
    ip("route", "add", "default", "via", "172.22.0.1")
    for ns, gateway in [("guest", "192.168.83.1"), ("lan", "172.22.0.10"), ("vpn", "100.64.0.1")]:
        ip("route", "add", "default", "via", gateway, ns=ns)
    # These public IPs exist ONLY in the test. No Internet traffic escapes.
    for address in ["1.1.1.1/32", "8.8.8.8/32"]:
        ip("address", "add", address, "dev", "lo", ns="wan")
    ip("address", "add", "9.9.9.9/32", "dev", "lo", ns="vpn")
    ip("route", "add", "9.9.9.9/32", "via", "100.64.0.2")
    ip("address", "add", "192.168.83.3/24", "dev", "eth0", ns="guest")
    ip("-6", "address", "add", "fd00:83::1/64", "dev", "agentbr0", "nodad")
    ip("-6", "address", "add", "fd00:83::2/64", "dev", "eth0", "nodad", ns="guest")


def main():
    rules, cleanup = sys.argv[1:]
    topology()
    # Emulate unrelated owners' tables. Compare the full contents, not just
    # table names, across first install, reloads, and removal of our table.
    for name in ["DOCKER", "KUBE_SERVICES", "ts_forward"]:
        run("nft", "-f", "-", input=f"table ip {name} {{\n chain sentinel {{\n ip saddr 10.0.0.99 drop\n }}\n}}\n")
    before = {name: run("nft", "list", "table", "ip", name) for name in ["DOCKER", "KUBE_SERVICES", "ts_forward"]}

    def preserved():
        check("other owners' tables preserved", all(run("nft", "list", "table", "ip", name) == text for name, text in before.items()))

    servers = []
    try:
        for ns, ports in [(None, [9999]), ("guest", [4096, 4321, 9999]), ("lan", [9999]), ("wan", [4096, 443, 9999]), ("vpn", [9999])]:
            servers.append(server(ns, *ports))
        # Sanity: without the policy, all the prohibited test endpoints really
        # are reachable. Failure below must not be due to missing routes.
        tcp("guest", "172.22.0.20", 9999)
        tcp("guest", "100.64.0.2", 9999)
        tcp("lan", "192.168.83.2", 9999)

        run("nft", "--check", "--file", rules)
        run("nft", "--file", rules)
        preserved()
        for port in [4096, 4321]:
            tcp("lan", "172.22.0.10", port)
        tcp("guest", "1.1.1.1", 443)
        tcp("guest", "1.1.1.1", 443, payload="peer", expected="172.22.0.10")
        tcp(None, "192.168.83.2", 9999)  # host-initiated administration
        tcp("guest", "172.22.0.10", 9999, allowed=False)
        tcp("guest", "192.168.83.1", 9999, allowed=False)
        tcp("guest", "172.22.0.20", 9999, allowed=False)
        tcp("guest", "100.64.0.2", 9999, allowed=False)
        tcp("guest", "9.9.9.9", 9999, allowed=False)  # public address routed via VPN
        tcp("guest", "1.1.1.1", 443, allowed=False, source="192.168.83.3")
        tcp("lan", "192.168.83.2", 4096, allowed=False)
        tcp("lan", "192.168.83.2", 9999, allowed=False)
        tcp("vpn", "192.168.83.2", 4096, allowed=False)
        tcp("wan", "172.22.0.10", 4096, allowed=False, source="8.8.8.8")
        # LAN transit to somebody else's port 4096 must not be DNATed.
        tcp("lan", "8.8.8.8", 4096, payload="who", expected="wan")
        tcp("lan", "172.22.0.10", 9999)  # ordinary host access unchanged
        tcp("vpn", "172.22.0.10", 9999)

        udp_code = """
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(('1.1.1.1', 53))
print('ready', flush=True)
while True:
    data, peer = s.recvfrom(100)
    s.sendto(data, peer)
"""
        udp_server = subprocess.Popen(["ip", "netns", "exec", "wan", sys.executable, "-u", "-c", udp_code], stdout=subprocess.PIPE, text=True)
        servers.append(udp_server)
        check("UDP server ready", udp_server.stdout.readline().strip() == "ready")
        run(sys.executable, "-c", "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(2); s.sendto(b'dns',('1.1.1.1',53)); assert s.recv(100)==b'dns'", ns="guest")
        print("PASS: guest UDP DNS request and reply", flush=True)
        ipv6 = subprocess.run(["ip", "netns", "exec", "guest", "ip", "-6", "route", "get", "fd00:83::1"], capture_output=True)
        check("IPv6 test route exists", ipv6.returncode == 0)
        # An IPv6 ping would otherwise succeed on this directly connected link.
        run(sys.executable, "-c", "import socket; s=socket.socket(socket.AF_INET6,socket.SOCK_DGRAM); s.sendto(b'ipv6',('fd00:83::1',9999))", ns="guest")
        # Read the drop counter to prove the packet reached the IPv6 rule.
        import time
        time.sleep(0.1)
        chain = json.loads(run("nft", "-j", "list", "chain", "inet", "grace_editor", "from_guest_to_host"))
        ipv6_rule = next(item["rule"] for item in chain["nftables"] if "rule" in item)
        check("guest IPv6 dropped on host", any(expr.get("counter", {}).get("packets", 0) > 0 for expr in ipv6_rule["expr"]))

        # Keep an editor connection alive across an atomic policy replacement.
        client = subprocess.Popen(["ip", "netns", "exec", "lan", sys.executable, "-u", "-c", "import socket,sys; s=socket.create_connection(('172.22.0.10',4096)); s.settimeout(2); print('ready',flush=True); sys.stdin.readline(); s.sendall(b'alive'); assert s.recv(100)==b'alive'"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        servers.append(client)
        check("editor connection established before reload", client.stdout.readline().strip() == "ready")
        for _ in range(2):
            run("nft", "--file", rules)
            preserved()
        client.communicate("continue\n", timeout=5)
        check("editor connection survives reload", client.returncode == 0)

        # A failed nft transaction must leave the working isolation in place.
        invalid = Path(rules).read_text() + "\nthis is not valid nft syntax\n"
        result = subprocess.run(["nft", "-f", "-"], input=invalid, text=True, capture_output=True)
        check("invalid reload rejected", result.returncode != 0)
        tcp("guest", "172.22.0.10", 9999, allowed=False)
        tcp("lan", "172.22.0.10", 4096)
        for _ in range(2):
            run("nft", "--file", cleanup)
            preserved()
        check("our table removed", "grace_editor" not in run("nft", "list", "tables"))
    finally:
        for process in servers:
            process.terminate()
        for process in servers:
            process.wait(timeout=5)


if __name__ == "__main__":
    main()
