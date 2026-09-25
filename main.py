import os
import sys
import uvicorn

# Ensure repository root and backend directory are in sys.path
root_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.join(root_dir, "backend")
for d in (root_dir, backend_dir):
    if d not in sys.path:
        sys.path.insert(0, d)

from backend.server import app

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
