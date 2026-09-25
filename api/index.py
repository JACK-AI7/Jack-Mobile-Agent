import os
import sys
import traceback
from fastapi import FastAPI
from fastapi.responses import JSONResponse

# Ensure repository root and backend directory are in sys.path for Vercel Serverless
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
backend_dir = os.path.join(root_dir, "backend")
for d in (root_dir, backend_dir):
    if d not in sys.path:
        sys.path.insert(0, d)

try:
    from backend.server import app
except Exception as e:
    tb = traceback.format_exc()
    app = FastAPI(title="Jack Serverless Diagnostic")

    @app.api_route("/{full_path:path}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"])
    async def catch_all_error(full_path: str):
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": "Backend server initialization error on Vercel Serverless",
                "exception": str(e),
                "traceback": tb,
            },
        )

handler = app
