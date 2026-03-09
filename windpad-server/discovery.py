import socket
import sys
import platform
import threading
import time
from zeroconf import ServiceInfo, Zeroconf

UDP_PORT = 8766

def _udp_broadcast_loop(local_ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    hostname = socket.gethostname()
    os_name = platform.system().lower()
    
    # Message format: WINDPAD:IP:PORT:HOSTNAME:OS
    msg = f"WINDPAD:{local_ip}:{port}:{hostname}:{os_name}".encode('utf-8')
    
    while True:
        try:
            s.sendto(msg, ('255.255.255.255', UDP_PORT))
        except:
            pass
        time.sleep(2)

def register_service(port=8765):
    zeroconf = None
    try:
        hostname = socket.gethostname()
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
        except Exception:
            local_ip = "127.0.0.1"

        # 1. Start UDP Fallback in background
        udp_thread = threading.Thread(target=_udp_broadcast_loop, args=(local_ip, port), daemon=True)
        udp_thread.start()

        # 2. Start mDNS
        zeroconf = Zeroconf()
        info = ServiceInfo(
            "_windpad._tcp.local.",
            f"{hostname}._windpad._tcp.local.",
            addresses=[socket.inet_aton(local_ip)],
            port=port,
            server=f"{hostname}.local.",
            properties={
                "version": "1.0",
                "hostname": hostname,
                "os": platform.system().lower()
            }
        )
        zeroconf.register_service(info)
        return zeroconf  # keep alive
    except Exception as e:
        print(f"Error starting discovery: {e}")
        return zeroconf
