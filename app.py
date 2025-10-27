# app.py
from fastapi import FastAPI, HTTPException
import subprocess
import ipaddress
import socket
import json
import time
from urllib.parse import urlencode
from urllib.request import urlopen, Request

app = FastAPI(title="Simple Network API Checker")

@app.get("/ping/{ip}")
def ping_ip(ip: str):
    """
    ping the given IP from the server.
    returns HTTP 200 with {"status":"ok", "ip":...} if reachable,
    otherwise returns an error with a clear message.
    """
    # validate IP
    try:
        ipaddress.ip_address(ip)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid IP address")

    # try ping (1 packet, 2s wait)
    try:
        res = subprocess.run(
            ["ping", "-c", "1", "-W", "2", ip],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=6,
        )
    except subprocess.TimeoutExpired:
        # ping binary took too long
        raise HTTPException(status_code=504, detail=f"Ping to {ip} timed out")

    if res.returncode == 0:
        # reachable -> HTTP 200
        return {
            "status": "ok",
            "ip": ip,
            "message": "host is reachable",
            "raw_output": res.stdout.decode(errors="ignore").strip()
        }
    else:
        # not reachable -> error (choose 502 as proxy/remote failure)
        raise HTTPException(
            status_code=502,
            detail={
                "status": "error",
                "ip": ip,
                "message": "host not reachable or didn't respond to ping",
                "ping_stdout": res.stdout.decode(errors="ignore").strip(),
                "ping_stderr": res.stderr.decode(errors="ignore").strip(),
            }
        )

@app.get("/tcp/{ip}")
def tcp_check(ip: str, port: int = 443, timeout: float = 3.0):
    """
    Check if a TCP connection can actually be established to the given IP and port.
    Returns success only if handshake + minimal send is successful.
    """
    # Validate IP
    try:
        ipaddress.ip_address(ip)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid IP address")

    # Create TCP socket
    try:
        # Force IPv4; for IPv6 use AF_INET6
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)

            # Try to connect (TCP handshake)
            sock.connect((ip, port))

            # Minimal send to confirm connection is fully established
            try:
                sock.send(b'\x00')  # ارسال یک بایت تستی
            except Exception as e:
                raise HTTPException(
                    status_code=502,
                    detail={
                        "status": "error",
                        "ip": ip,
                        "port": port,
                        "message": f"Connection established but send failed: {e}",
                    },
                )

            return {
                "status": "ok",
                "ip": ip,
                "port": port,
                "message": "TCP connection fully established",
            }

    except socket.timeout:
        raise HTTPException(
            status_code=504,
            detail={
                "status": "error",
                "ip": ip,
                "port": port,
                "message": "Connection timed out",
            },
        )
    except (ConnectionRefusedError, OSError) as e:
        raise HTTPException(
            status_code=502,
            detail={
                "status": "error",
                "ip": ip,
                "port": port,
                "message": f"Connection failed: {e}",
            },
        )