# app.py
from fastapi import FastAPI, HTTPException
import subprocess
import ipaddress

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
