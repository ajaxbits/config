"""Exercise Paperless host/guest network policy in fresh namespaces."""

import json
import ipaddress
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


def tcp(ns, address, port, allowed=True, uid=None, source=None):
    code = """
import socket, sys
s = socket.socket()
s.settimeout(0.5)
if sys.argv[3]: s.bind((sys.argv[3], 0))
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
    s.sendall(b'paperless-policy')
    result = s.recv(100).decode()
except OSError:
    result = 'blocked'
print(result)
"""
    prefix = ["ip", "netns", "exec", ns] if ns else []
    result = subprocess.run(
        prefix + [sys.executable, "-c", code, address, str(port), source or ""],
        text=True,
        capture_output=True,
        user=uid,
    )
    if result.returncode:
        raise RuntimeError(f"TCP probe failed:\n{result.stderr}")
    check(f"{ns or 'host'} -> {address}:{port} {'allowed' if allowed else 'blocked'}", result.stdout.strip() == ("paperless-policy" if allowed else "blocked"))


SERVER = """
import socket, sys, threading
for port in map(int, sys.argv[1:]):
    sock = socket.socket()
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('0.0.0.0', port))
    sock.listen()
    def serve(listener):
        while True:
            conn, _ = listener.accept()
            threading.Thread(target=lambda c: (c.sendall(c.recv(100)), c.close()), args=(conn,), daemon=True).start()
    threading.Thread(target=serve, args=(sock,), daemon=True).start()
    print('ready', flush=True)
threading.Event().wait()
"""

SERVER6 = """
import socket, threading
s = socket.socket(socket.AF_INET6)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('::', 9998))
s.listen()
print('ready', flush=True)
while True:
    conn, _ = s.accept()
    threading.Thread(target=lambda c: (c.sendall(c.recv(100)), c.close()), args=(conn,), daemon=True).start()
"""


def server6():
    process = subprocess.Popen([sys.executable, "-u", "-c", SERVER6], stdout=subprocess.PIPE, text=True)
    if process.stdout.readline().strip() != "ready":
        raise RuntimeError("IPv6 test server failed to start")
    return process


def tcp6(ns, address, port, allowed=True):
    code = """
import socket, sys
s = socket.socket(socket.AF_INET6)
s.settimeout(0.5)
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
    s.sendall(b'paperless-policy')
    result = s.recv(100).decode()
except OSError:
    result = 'blocked'
print(result)
"""
    result = run(sys.executable, "-c", code, address, str(port), ns=ns)
    check(f"{ns} IPv6 -> {address}:{port} {'allowed' if allowed else 'blocked'}", result.stdout.strip() == ("paperless-policy" if allowed else "blocked"))


def server(ns, *ports):
    prefix = ["ip", "netns", "exec", ns] if ns else []
    process = subprocess.Popen(
        prefix + [sys.executable, "-u", "-c", SERVER, *map(str, ports)],
        stdout=subprocess.PIPE,
        text=True,
    )
    for _ in ports:
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

    cidr = net["cidr"]
    guest_subnet = ipaddress.ip_network(f"{net['ip']}/{cidr}", strict=False)
    spoofed_ip = str(ipaddress.ip_address(net["ip"]) + 1)
    for bridge, address in [
        (net["bridge"], f"{net['gateway']}/{cidr}"),
        ("lanbr0", "172.22.0.10/24"),
    ]:
        ip("link", "add", bridge, "type", "bridge")
        ip("address", "add", address, "dev", bridge)
        ip("link", "set", bridge, "up")

    for name, tap, bridge, address in [
        ("guest", net["tap"], net["bridge"], f"{net['ip']}/{cidr}"),
        ("lan", "lan-link", "lanbr0", "172.22.0.20/24"),
    ]:
        ip("netns", "add", name)
        ip("link", "add", tap, "type", "veth", "peer", "name", "eth0", "netns", name)
        ip("link", "set", tap, "master", bridge)
        ip("link", "set", tap, "up")
        ip("link", "set", "lo", "up", ns=name)
        ip("link", "set", "eth0", "up", ns=name)
        ip("address", "add", address, "dev", "eth0", ns=name)

    Path("/proc/sys/net/ipv4/ip_forward").write_text("1")
    ip("route", "add", "default", "via", net["gateway"], ns="guest")
    ip("route", "add", str(guest_subnet), "via", "172.22.0.10", ns="lan")
    ip("address", "add", "fd00:84::1/64", "dev", net["bridge"], "nodad")
    ip("-6", "address", "add", "fd00:84::2/64", "dev", "eth0", "nodad", ns="guest")
    ip("address", "add", f"{spoofed_ip}/{cidr}", "dev", "eth0", ns="guest")
    return spoofed_ip


def main():
    rules, cleanup, settings_path = sys.argv[1:]
    settings = json.loads(Path(settings_path).read_text())
    net = settings["net"]
    proxy_uid = int(settings["proxyUid"])
    guest_ip = net["ip"]
    guest_port = int(net["port"])
    gateway = net["gateway"]
    spoofed_ip = topology(net)
    for name in ["DOCKER", "KUBE_SERVICES"]:
        run("nft", "-f", "-", input=f"table ip {name} {{\n chain sentinel {{\n ip saddr 10.0.0.99 drop\n }}\n}}\n")
    before = {name: run("nft", "list", "table", "ip", name).stdout for name in ["DOCKER", "KUBE_SERVICES"]}

    def preserved():
        check("unrelated nftables tables preserved", all(run("nft", "list", "table", "ip", name).stdout == text for name, text in before.items()))

    servers = []
    try:
        servers.extend([server(None, 9999), server6(), server("guest", guest_port, guest_port + 1), server("lan", 9999)])
        # Prove these routes/listeners work before the policy is installed.
        tcp(None, guest_ip, guest_port, uid=proxy_uid)
        tcp(None, guest_ip, guest_port, uid=65534)
        tcp("guest", gateway, 9999)
        tcp6("guest", "fd00:84::1", 9998)
        tcp("guest", "172.22.0.20", 9999)
        tcp("lan", guest_ip, guest_port)

        run("nft", "--check", "--file", rules)
        run("nft", "--file", rules)
        preserved()
        tcp(None, guest_ip, guest_port, uid=proxy_uid)
        tcp(None, guest_ip, guest_port, allowed=False, uid=65534)
        tcp(None, guest_ip, guest_port, allowed=False, uid=0)
        tcp(None, guest_ip, guest_port + 1, allowed=False, uid=proxy_uid)
        tcp("guest", gateway, 9999, allowed=False)
        tcp6("guest", "fd00:84::1", 9998, allowed=False)
        tcp("guest", "172.22.0.20", 9999, allowed=False)
        tcp("lan", guest_ip, guest_port, allowed=False)
        tcp("guest", gateway, 9999, allowed=False, source=spoofed_ip)

        bad_reload = subprocess.run(
            ["nft", "-f", "-"],
            input=Path(rules).read_text() + "\nthis is not valid nft syntax\n",
            text=True,
            capture_output=True,
        )
        check("invalid firewall reload rejected", bad_reload.returncode != 0)
        tcp(None, guest_ip, guest_port, uid=proxy_uid)
        preserved()
        for _ in range(2):
            run("nft", "--file", cleanup)
        check("paperless nftables table cleaned up", "paperless" not in run("nft", "list", "tables").stdout)
        preserved()
    finally:
        for process in servers:
            process.terminate()
        for process in servers:
            process.wait(timeout=5)

if __name__ == "__main__":
    main()
