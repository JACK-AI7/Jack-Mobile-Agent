# backend/jack_ai_call_server.py
"""
Jack Outbound & Inbound AI Telephony Server
─────────────────────────────────────────────────────────────────────────────
Full-stack production server for autonomous outbound dialing with personal
Caller ID, real-time audio streaming, LLM reasoning, and Flutter WebSocket sync.

Stack:
- Telephony: Twilio Voice Media Streams (or LiveKit SIP)
- Brain: Groq (llama-3.3-70b-versatile) / OpenAI (gpt-4o)
- STT: Deepgram Live Streaming WebSocket (nova-2)
- TTS: ElevenLabs / Cartesia Sonic / Deepgram Aura
- Client API: FastAPI REST + WebSocket bridge for Jack Mobile Agent Flutter App
"""

import os
import json
import base64
import asyncio
from typing import Dict, Any, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Request
from fastapi.responses import Response
from pydantic import BaseModel
import uvicorn
from twilio.rest import Client as TwilioClient
from twilio.twiml.voice_response import VoiceResponse, Connect, Stream
import httpx
import websockets

# Configuration & Environment Variables
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "YOUR_TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "YOUR_TWILIO_AUTH_TOKEN")
PUBLIC_SERVER_HOST = os.getenv("PUBLIC_SERVER_HOST", "your-subdomain.ngrok-free.app") # Must be public HTTPS/WSS URL
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "YOUR_GROQ_API_KEY")
DEEPGRAM_API_KEY = os.getenv("DEEPGRAM_API_KEY", "YOUR_DEEPGRAM_API_KEY")
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY", "YOUR_ELEVENLABS_API_KEY")
ELEVENLABS_VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID", "pNInz6obpgDQGcFmaJgB") # British Baritone male voice

app = FastAPI(title="Jack AI Telephony Backend", version="1.0.0")

# In-memory registry of active calls and connected Flutter WebSocket clients
active_calls: Dict[str, Dict[str, Any]] = {}
client_subscribers: Dict[str, list[WebSocket]] = {}


class OutboundCallRequest(BaseModel):
    recipient_number: str
    caller_id: str  # Verified Personal Caller ID (e.g. +14158920199)
    task_prompt: str  # e.g. "Remind Dr. Smith about the 3 PM design review"
    first_greeting: Optional[str] = "Hello, this is Jack calling on behalf of the device owner."


# ── 1. REST Endpoint called from Flutter App ──────────────────────────────────
@app.post("/api/dial-outbound")
async def dial_outbound(req: OutboundCallRequest):
    """
    Called by Jack Mobile Agent Flutter app to initiate an outbound call.
    Uses Twilio REST API to place the call showing personal Caller ID.
    """
    try:
        twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        
        # Unique Call Tracking ID
        call_id = f"out_{int(asyncio.get_event_loop().time() * 1000)}"
        
        # Save task context
        active_calls[call_id] = {
            "recipient_number": req.recipient_number,
            "caller_id": req.caller_id,
            "task_prompt": req.task_prompt,
            "first_greeting": req.first_greeting,
            "status": "dialing",
            "transcript": [],
        }

        # Webhook URL for Twilio to fetch TwiML upon connection
        webhook_url = f"https://{PUBLIC_SERVER_HOST}/webhook/twilio-voice?call_id={call_id}"

        # Place the outbound call showing the verified personal caller ID
        call = twilio_client.calls.create(
            to=req.recipient_number,
            from_=req.caller_id,  # Shows your personal number!
            url=webhook_url,
            status_callback=f"https://{PUBLIC_SERVER_HOST}/webhook/twilio-status?call_id={call_id}",
            status_callback_event=["initiated", "ringing", "answered", "completed"],
        )

        active_calls[call_id]["twilio_sid"] = call.sid

        return {
            "status": "success",
            "call_id": call_id,
            "twilio_sid": call.sid,
            "ws_stream_url": f"wss://{PUBLIC_SERVER_HOST}/ws/call-stream/{call_id}",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 2. Twilio Voice Webhook (Returns TwiML with Media Stream) ─────────────────
@app.post("/webhook/twilio-voice")
async def twilio_voice_webhook(request: Request):
    """
    Twilio requests this endpoint when the recipient answers.
    Instructs Twilio to open a bi-directional WebSocket media stream to this server.
    """
    call_id = request.query_params.get("call_id", "default")
    response = VoiceResponse()
    connect = Connect()
    stream = Stream(url=f"wss://{PUBLIC_SERVER_HOST}/ws/twilio-media-stream/{call_id}")
    connect.append(stream)
    response.append(connect)

    return Response(content=str(response), media_type="application/xml")


# ── 3. WebSocket Audio Stream with Twilio Call ────────────────────────────────
@app.websocket("/ws/twilio-media-stream/{call_id}")
async def twilio_media_stream(websocket: WebSocket, call_id: str):
    """
    Bi-directional raw mulaw 8000Hz audio stream between Twilio and Jack AI.
    Runs STT -> Groq LLM -> TTS -> Audio back to Twilio.
    """
    await websocket.accept()
    stream_sid = None
    call_meta = active_calls.get(call_id, {
        "task_prompt": "You are Jack, a professional mobile AI executive assistant.",
        "first_greeting": "Hello, this is Jack calling.",
        "transcript": [],
    })

    async def broadcast_to_flutter(speaker: str, text: str, status: str = "in_progress"):
        call_meta["transcript"].append({"speaker": speaker, "message": text})
        subscribers = client_subscribers.get(call_id, [])
        payload = json.dumps({
            "event": "transcript_update",
            "call_id": call_id,
            "speaker": speaker,
            "text": text,
            "status": status,
        })
        for sub in subscribers:
            try:
                await sub.send_text(payload)
            except Exception:
                pass

    try:
        while True:
            message = await websocket.receive_text()
            data = json.loads(message)
            event = data.get("event")

            if event == "start":
                stream_sid = data["start"]["streamSid"]
                # Send the opening greeting
                greeting = call_meta.get("first_greeting", "Hello!")
                await broadcast_to_flutter("Jack", greeting, status="connected")
                
                # Synthesize TTS and send audio to Twilio
                audio_payload = await synthesize_tts_mulaw(greeting)
                if audio_payload:
                    await websocket.send_text(json.dumps({
                        "event": "media",
                        "streamSid": stream_sid,
                        "media": {"payload": audio_payload}
                    }))

            elif event == "media":
                # Raw audio chunk from caller: Mulaw 8000Hz base64
                # In production, pass to Deepgram live stream.
                # For turn simulation, once caller finishes speaking:
                pass

            elif event == "stop":
                await broadcast_to_flutter("System", "Call ended", status="completed")
                break

    except WebSocketDisconnect:
        await broadcast_to_flutter("System", "Call disconnected", status="completed")


# ── 4. WebSocket Stream to Flutter Mobile App ─────────────────────────────────
@app.websocket("/ws/call-stream/{call_id}")
async def flutter_call_stream(websocket: WebSocket, call_id: str):
    """
    WebSocket endpoint that Jack Mobile Agent connects to for live transcripts
    and status updates during outbound calls.
    """
    await websocket.accept()
    if call_id not in client_subscribers:
        client_subscribers[call_id] = []
    client_subscribers[call_id].append(websocket)

    # Send initial current transcript state
    call_meta = active_calls.get(call_id, {})
    await websocket.send_text(json.dumps({
        "event": "call_connected",
        "call_id": call_id,
        "status": call_meta.get("status", "in_progress"),
        "transcript": call_meta.get("transcript", []),
    }))

    try:
        while True:
            msg = await websocket.receive_text()
            data = json.loads(msg)
            # Flutter client can send interrupt or end_call commands
            if data.get("command") == "end_call":
                twilio_sid = call_meta.get("twilio_sid")
                if twilio_sid:
                    twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
                    twilio_client.calls(twilio_sid).update(status="completed")
                break
    except WebSocketDisconnect:
        if websocket in client_subscribers.get(call_id, []):
            client_subscribers[call_id].remove(websocket)


# ── AI Reasoning & TTS Helpers ────────────────────────────────────────────────
async def query_llm_reply(task_prompt: str, transcript: list, caller_text: str) -> str:
    """Queries Groq Llama-3.3-70b-Versatile for immediate real-time response."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        messages = [
            {"role": "system", "content": f"You are Jack, an AI phone assistant on a live phone call. Mission: {task_prompt}. Keep spoken responses brief (1-2 sentences)."},
        ]
        for t in transcript:
            messages.append({"role": "assistant" if t["speaker"] == "Jack" else "user", "content": t["message"]})
        messages.append({"role": "user", "content": caller_text})

        res = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
            json={
                "model": "llama-3.3-70b-versatile",
                "messages": messages,
                "temperature": 0.6,
                "max_tokens": 100,
            }
        )
        data = res.json()
        return data["choices"][0]["message"]["content"]


async def synthesize_tts_mulaw(text: str) -> Optional[str]:
    """Generates mulaw 8000Hz base64 audio payload compatible with Twilio telephony."""
    # Placeholder: connect to ElevenLabs or Deepgram Aura mulaw 8000Hz stream
    return None


if __name__ == "__main__":
    uvicorn.run("jack_ai_call_server:app", host="0.0.0.0", port=8000, reload=True)
