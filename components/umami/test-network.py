"""Exercise the Umami host/guest network policy in fresh namespaces.

Adapted from components/documents/paperless/test-network.py.
"""

import ipaddress
import json
import os
from pathlib import Path
import subprocess
import sys


def run(*args, input=None, ns=None, ok=True):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    result = subprocess.run(prefix + list(args), input=input, text=True, capture_output=True)
    if ok and result.returncode:
        raise RuntimeError(f"{prefix + list(args)} failed:\n{result.stderr}")
    return result


def ip(*args, ns=None):
    return run("ip", *args, ns=ns).stdout


def check(label, condition):
    if not condition:
        raise AssertionError(label)
    print(f"PASS: {label}", flush=True)


PROBE = """
import socket, sys
family = socket.AF_INET6 if ':' in sys.argv[1] else socket.AF_INET
s = socket.socket(family)
s.settimeout(0.5)
if sys.argv[3]: s.bind((sys.argv[3], 0))
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
    s.sendall(b'umami-policy')
    result = s.recv(100).decode()
except OSError:
    result = 'blocked'
print(result)
"""


def tcp(ns, address, port, allowed=True, uid=None, source=None):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    result = subprocess.run(
        prefix + [sys.executable, "-c", PROBE, address, str(port), source or ""],
        text=True, capture_output=True, user=uid,
    )
    if result.returncode:
        raise RuntimeError(f"TCP probe failed:\n{result.stderr}")
    who = f"{ns or 'host'}{f' uid {uid}' if uid is not None else ''}{f' from {source}' if source else ''}"
    check(f"{who} -> {address}:{port} {'allowed' if allowed else 'blocked'}",
          result.stdout.strip() == ("umami-policy" if allowed else "blocked"))


SERVER = """
import socket, sys, threading
def serve(listener):
    while True:
        conn, _ = listener.accept()
        threading.Thread(target=lambda c: (c.sendall(c.recv(100)), c.close()), args=(conn,), daemon=True).start()
for spec in sys.argv[1:]:
    address, port = spec.rsplit(':', 1)
    sock = socket.socket(socket.AF_INET6 if ':' in address else socket.AF_INET)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((address, int(port)))
    sock.listen()
    threading.Thread(target=serve, args=(sock,), daemon=True).start()
    print('ready', flush=True)
threading.Event().wait()
"""


def server(ns, *specs):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    process = subprocess.Popen(prefix + [sys.executable, "-u", "-c", SERVER, *specs], stdout=subprocess.PIPE, text=True)
    for _ in specs:
        if process.stdout.readline().strip() != "ready":
            raise RuntimeError("TCP test server failed to start")
    return process


def topology(net):
    links = json.loads(ip("-j", "link"))
    kernel_links = {"lo", "tunl0", "gre0", "gretap0", "erspan0", "ip_vti0", "ip6_vti0", "sit0", "ip6tnl0", "ip6gre0"}
    check("fresh isolated network namespace", all(link["ifname"] in kernel_links and "UP" not in link["flags"] for link in links))
    check("fresh isolated PID namespace", os.getpid() == 1)
    run("mount", "--make-rprivate", "/")
    run("mount", "-t", "tmpfs", "tmpfs", "/run")
    Path("/run/netns").mkdir()
    ip("link", "set", "lo", "up")

    # umami bridge, LAN bridge (br0), tailscale0 and a docker-ish bridge.
    for bridge, address in [
        (net["bridge"], f"{net['gateway']}/{net['cidr']}"),
        ("br0", "172.22.0.10/24"),
        ("tailscale0", "100.122.241.27/24"),
        ("docker0", "172.23.0.1/24"),
    ]:
        ip("link", "add", bridge, "type", "bridge")
        ip("address", "add", address, "dev", bridge)
        ip("link", "set", bridge, "up")
    ip("-6", "address", "add", "fd00:85::1/64", "dev", net["bridge"], "nodad")

    for name, link, bridge, address in [
        ("guest", net["tap"], net["bridge"], f"{net['ip']}/{net['cidr']}"),
        ("lan", "lan-link", "br0", "172.22.0.20/24"),
        ("tail", "tail-link", "tailscale0", "100.122.241.20/24"),
        ("docker", "docker-link", "docker0", "172.23.0.20/24"),
    ]:
        ip("netns", "add", name)
        ip("link", "add", link, "type", "veth", "peer", "name", "eth0", "netns", name)
        ip("link", "set", link, "master", bridge)
        ip("link", "set", link, "up")
        ip("link", "set", "lo", "up", ns=name)
        ip("link", "set", "eth0", "up", ns=name)
        ip("address", "add", address, "dev", "eth0", ns=name)
    ip("-6", "address", "add", "fd00:85::2/64", "dev", "eth0", "nodad", ns="guest")

    Path("/proc/sys/net/ipv4/ip_forward").write_text("1")
    # A compromised guest adds a default route and tries to get out.
    ip("route", "add", "default", "via", net["gateway"], ns="guest")
    # Route the whole /30 so fixtures can reach both the guest and the gateway.
    subnet = str(ipaddress.ip_network(f"{net['ip']}/{net['cidr']}", strict=False))
    for ns, via in [("lan", "172.22.0.10"), ("tail", "100.122.241.27"), ("docker", "172.23.0.1")]:
        ip("route", "add", subnet, "via", via, ns=ns)
    ip("route", "add", "172.22.0.10/32", "via", "172.23.0.1", ns="docker")
    # Spoofers: a container claims a LAN address, a LAN host claims a tailnet
    # address. Host routes send replies back so the pre-policy probes succeed.
    ip("address", "add", "172.22.0.99/32", "dev", "eth0", ns="docker")
    ip("route", "add", "172.22.0.99/32", "dev", "docker0")
    ip("address", "add", "100.64.0.99/32", "dev", "eth0", ns="lan")
    ip("route", "add", "100.64.0.99/32", "dev", "br0")


def main():
    rules, cleanup, settings_path = sys.argv[1:]
    settings = json.loads(Path(settings_path).read_text())
    net = settings["net"]
    tunnel, caddy = int(settings["cloudflaredUid"]), int(settings["caddyUid"])
    guest, gw = net["ip"], net["gateway"]
    collector, app, spoa = int(net["collectorPort"]), int(net["port"]), int(net["spoaPort"])
    topology(net)

    for name in ["DOCKER", "KUBE_SERVICES"]:
        run("nft", "-f", "-", input=f"table ip {name} {{\n chain sentinel {{\n ip saddr 10.0.0.99 drop\n }}\n}}\n")
    before = {name: run("nft", "list", "table", "ip", name).stdout for name in ["DOCKER", "KUBE_SERVICES"]}

    def preserved():
        check("unrelated nftables tables preserved",
              all(run("nft", "list", "table", "ip", name).stdout == text for name, text in before.items()))

    servers = []
    try:
        servers += [
            server(None, f"0.0.0.0:{spoa}", "0.0.0.0:18080", "0.0.0.0:443", "::9998".replace("::", ":::")),
            server("guest", f"0.0.0.0:{collector}", f"0.0.0.0:{app}", "0.0.0.0:5432"),
            server("lan", "0.0.0.0:9999"),
            server("tail", "0.0.0.0:9999"),
        ]

        # Everything works before the policy is installed.
        tcp(None, guest, collector, uid=caddy)
        tcp("guest", gw, 18080)
        tcp("guest", "172.22.0.20", 9999)
        tcp("guest", "fd00:85::1", 9998)
        tcp("lan", guest, collector)
        tcp("lan", gw, spoa)
        tcp("docker", "172.22.0.10", 443, source="172.22.0.99")
        tcp("lan", "172.22.0.10", 443, source="100.64.0.99")

        run("nft", "--check", "--file", rules)
        run("nft", "--file", rules)
        preserved()

        # Only cloudflared -> HAProxy and Caddy -> Umami.
        tcp(None, guest, collector, uid=tunnel)
        tcp(None, guest, app, uid=caddy)
        tcp(None, guest, app, allowed=False, uid=tunnel)
        tcp(None, guest, collector, allowed=False, uid=caddy)
        for uid in (0, 65534):
            tcp(None, guest, collector, allowed=False, uid=uid)
            tcp(None, guest, app, allowed=False, uid=uid)
        tcp(None, guest, 5432, allowed=False, uid=caddy)
        tcp("lan", guest, collector, allowed=False)
        tcp("lan", guest, app, allowed=False)

        # The guest may only call the bouncer.
        tcp("guest", gw, spoa)
        tcp("guest", gw, 18080, allowed=False)
        tcp("guest", gw, 443, allowed=False)
        tcp("guest", "172.22.0.20", 9999, allowed=False)
        tcp("guest", "100.122.241.20", 9999, allowed=False)
        tcp("guest", "fd00:85::1", 9998, allowed=False)
        ip("address", "add", "10.85.0.3/32", "dev", "eth0", ns="guest")
        tcp("guest", gw, spoa, allowed=False, source="10.85.0.3")

        # Nobody else may reach the bouncer.
        tcp("lan", gw, spoa, allowed=False)
        tcp("tail", gw, spoa, allowed=False)
        tcp("docker", gw, spoa, allowed=False)
        tcp(None, gw, spoa, allowed=False)

        # Host :443 anti-spoofing for the private dashboard.
        tcp("lan", "172.22.0.10", 443)
        tcp("tail", "100.122.241.27", 443)
        tcp("docker", "172.22.0.10", 443, allowed=False, source="172.22.0.99")
        tcp("lan", "172.22.0.10", 443, allowed=False, source="100.64.0.99")

        bad = subprocess.run(["nft", "-f", "-"], input=Path(rules).read_text() + "\nnot valid nft\n",
                             text=True, capture_output=True)
        check("invalid firewall reload rejected", bad.returncode != 0)
        tcp(None, guest, collector, uid=tunnel)
        tcp("guest", gw, 18080, allowed=False)
        run("nft", "--file", rules)
        check("atomic reload keeps policy", run("nft", "list", "tables").stdout.count("inet umami") == 1)
        preserved()

        for _ in range(2):
            run("nft", "--file", cleanup)
        check("umami nftables table cleaned up", "umami" not in run("nft", "list", "tables").stdout)
        preserved()
    finally:
        for process in servers:
            process.terminate()
        for process in servers:
            process.wait(timeout=5)


if __name__ == "__main__":
    main()
