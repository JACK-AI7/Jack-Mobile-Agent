import os
import sys

# Ensure backend and root directories are in sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
for d in (current_dir, parent_dir):
    if d not in sys.path:
        sys.path.insert(0, d)

try:
    from server import app
except (ImportError, ModuleNotFoundError):
    from backend.server import app

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    print(f"[INFO] Booting Jack Multi-Tenant Telephony API on 0.0.0.0:{port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
