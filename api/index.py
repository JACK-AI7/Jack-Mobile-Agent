import os
import sys

# Ensure repository root and backend directory are in sys.path for Vercel Serverless
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
backend_dir = os.path.join(root_dir, "backend")
for d in (root_dir, backend_dir):
    if d not in sys.path:
        sys.path.insert(0, d)

from backend.server import app

# Vercel ASGI application handler
handler = app
