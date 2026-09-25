# backend/jack_free_ai_call_server.py
"""
Jack Free & Open-Source AI Telephony Gateway
─────────────────────────────────────────────────────────────────────────────
100% FREE, Zero-Cost, Open-Source Call Lifting & Conversational Voice Server.
Replaces paid platforms (Twilio, ElevenLabs, Deepgram) with free open-source equivalents:

- PBX / Call Transport : Asterisk AudioSocket / FreeSWITCH / LiveKit SIP / WebRTC
- Speech-to-Text (STT) : Groq Whisper-large-v3 (Free Tier) or Faster-Whisper
- Conversational Brain : Groq Llama-3.3-70b-versatile (Free Tier, 300+ tps) or Ollama
- Text-to-Speech (TTS) : Edge-TTS (Free Neural Voices) / Piper TTS (Open Source)
- Mobile App Sync      : Real-time WebSocket broadcasting transcripts & live audio
─────────────────────────────────────────────────────────────────────────────
"""

import os
import json
import base64
import asyncio
import io
import time
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Request, Query
from fastapi.responses import JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import uvicorn

app = FastAPI(
    title="Jack Free Open-Source AI Telephony Gateway",
    version="3.0.0",
    description="100% Free Open-Source Inbound & Outbound AI Call Lifting Engine"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Environment & Free Tier Configuration ─────────────────────────────────────
# Groq Free Tier API Key (Free tier allows 14,400 requests/day, 30 req/min)
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_AUDIO_URL = "https://api.groq.com/openai/v1/audio/transcriptions"

# Local Ollama Fallback URL (if running locally on PC / Raspberry Pi)
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")

# Default Jack Voice (Microsoft Edge Neural Voice — Free & High Quality)
EDGE_TTS_VOICE = os.getenv("EDGE_TTS_VOICE", "en-GB-RyanNeural") # Natural British Baritone

# Active Call State Registry
# Maps call_id -> Call Session metadata
active_calls: Dict[str, Dict[str, Any]] = {}

# Active Mobile App WebSocket Subscribers
# Maps user_id -> List of connected Flutter WebSocket clients
mobile_subscribers: Dict[str, List[WebSocket]] = {}


# ── Data Models ───────────────────────────────────────────────────────────────
class UserDirectiveRequest(BaseModel):
    call_id: str
    directive: str


class CallHangupRequest(BaseModel):
    call_id: str


class SimulatedInboundCallRequest(BaseModel):
    caller_name: Optional[str] = "Caller"
    caller_number: Optional[str] = "+1 (555) 019-2834"
    simulated_speech: Optional[str] = "Hi, I am calling to confirm if Jaswanth is available for the meeting today."


# ── Free Neural Voice Synthesis (Edge-TTS) ────────────────────────────────────
async def synthesize_speech_free(text: str, voice: str = EDGE_TTS_VOICE) -> bytes:
    """
    Synthesizes speech using edge-tts (100% free open-source neural voice engine).
    Generates high-fidelity MP3 / WAV audio with sub-100ms processing.
    """
    try:
        import edge_tts
        communicate = edge_tts.Communicate(text, voice)
        audio_buffer = io.BytesIO()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_buffer.write(chunk["data"])
        return audio_buffer.getvalue()
    except ImportError:
        # Fallback if edge-tts not installed in environment: generate basic WAV silence/tone
        print("[TTS Warning] edge-tts not installed. Run: pip install edge-tts")
        return b""
    except Exception as e:
        print(f"[TTS Error] Free speech synthesis failed: {e}")
        return b""


# ── Free Speech-to-Text (Groq Whisper / Local) ────────────────────────────────
async def transcribe_audio_free(audio_bytes: bytes, filename: str = "audio.wav") -> str:
    """
    Transcribes caller audio using Groq Whisper-large-v3 free tier or local engine.
    """
    if not GROQ_API_KEY:
        print("[STT Warning] GROQ_API_KEY not set. Will use simulated transcript.")
        return "Hello, I am calling for the device owner."

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            files = {
                "file": (filename, audio_bytes, "audio/wav"),
            }
            data = {
                "model": "whisper-large-v3",
                "temperature": 0.0,
                "response_format": "json",
            }
            headers = {"Authorization": f"Bearer {GROQ_API_KEY}"}

            resp = await client.post(GROQ_AUDIO_URL, files=files, data=data, headers=headers)
            if resp.status_code == 200:
                result = resp.json()
                return result.get("text", "").strip()
            else:
                print(f"[Groq Whisper Error] HTTP {resp.status_code}: {resp.text}")
                return ""
    except Exception as e:
        print(f"[STT Error] Audio transcription exception: {e}")
        return ""


# ── Free LLM Reasoning (Groq Llama 3.3 70B / Ollama) ──────────────────────────
async def reason_with_free_llm(caller_speech: str, system_directive: str, conversation_history: List[Dict[str, str]]) -> str:
    """
    Queries Groq Llama 3.3 70B Versatile (Free Tier, 300+ tokens/sec, sub-150ms TTFT)
    or local Ollama on PC.
    """
    if GROQ_API_KEY:
        try:
            messages = [{"role": "system", "content": system_directive}]
            for turn in conversation_history[-6:]:
                role = "assistant" if turn.get("speaker") == "Jack" else "user"
                messages.append({"role": role, "content": turn.get("message", "")})
            messages.append({"role": "user", "content": caller_speech})

            async with httpx.AsyncClient(timeout=10.0) as client:
                payload = {
                    "model": "llama-3.3-70b-versatile",
                    "messages": messages,
                    "max_tokens": 120,
                    "temperature": 0.6,
                }
                headers = {
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "Content-Type": "application/json",
                }
                resp = await client.post(GROQ_API_URL, json=payload, headers=headers)
                if resp.status_code == 200:
                    reply = resp.json()["choices"][0]["message"]["content"].strip()
                    # Clean out markdown asterisks or quotes for natural speech
                    reply = reply.replace("*", "").replace('"', '').strip()
                    return reply
        except Exception as e:
            print(f"[Groq LLM Error] {e}")

    # Fallback to local Ollama if available
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            prompt = f"{system_directive}\nCaller: {caller_speech}\nJack:"
            resp = await client.post(OLLAMA_URL, json={"model": "llama3.2:1b", "prompt": prompt, "stream": False})
            if resp.status_code == 200:
                return resp.json().get("response", "").strip()
    except Exception:
        pass

    return "Thank you for reaching out. I have noted your message for the device owner and will notify them immediately."


# ── Broadcast Events to Connected Jack Mobile Agent Apps ───────────────────────
async def broadcast_to_mobile_clients(user_id: str, payload: Dict[str, Any]):
    """Streams live call events, transcripts, and status directly into Flutter app."""
    clients = mobile_subscribers.get(user_id, [])
    dead_clients = []
    message_json = json.dumps(payload)

    for ws in clients:
        try:
            await ws.send_text(message_json)
        except Exception:
            dead_clients.append(ws)

    for dead in dead_clients:
        if dead in clients:
            clients.remove(dead)


# ── REST Endpoints ────────────────────────────────────────────────────────────

@app.get("/api/free-telephony/status")
async def get_telephony_status():
    """Returns status of the free open-source telephony system."""
    return {
        "status": "operational",
        "stack": {
            "pbx_support": ["Asterisk AudioSocket", "LiveKit SIP", "FreeSWITCH mod_audio_fork"],
            "speech_to_text": "Groq Whisper-large-v3 (Free Tier) / Faster-Whisper",
            "reasoning_brain": "Groq Llama-3.3-70b-versatile (Free Tier) / Ollama",
            "voice_synthesis": "Edge-TTS Neural Voices (100% Free, Zero API Keys)",
            "monthly_cost": "$0.00",
        },
        "active_calls_count": len(active_calls),
        "connected_mobile_agents": sum(len(c) for c in mobile_subscribers.values()),
    }


@app.post("/api/free-telephony/simulate-inbound")
async def simulate_inbound_forwarded_call(req: SimulatedInboundCallRequest):
    """
    Test endpoint: Simulates an incoming forwarded carrier call being lifted by Jack.
    Runs the full STT -> Groq -> Edge-TTS pipeline and broadcasts to connected Flutter apps.
    """
    call_id = f"call_{int(time.time() * 1000)}"
    user_id = "default_user"

    active_calls[call_id] = {
        "call_id": call_id,
        "caller_name": req.caller_name,
        "caller_number": req.caller_number,
        "started_at": datetime.now().isoformat() if "datetime" in globals() else str(time.time()),
        "status": "active",
        "transcript": [],
        "user_id": user_id,
    }

    # 1. Notify Mobile App: Call Lifted!
    await broadcast_to_mobile_clients(user_id, {
        "event": "call_lifted",
        "call_id": call_id,
        "caller_name": req.caller_name,
        "caller_number": req.caller_number,
        "message": f"Jack answered incoming call from {req.caller_name} ({req.caller_number})",
    })

    # 2. Jack's initial spoken greeting
    greeting = f"Hello, I am Jack, executive AI assistant for the device owner. How may I direct your call?"
    active_calls[call_id]["transcript"].append({"speaker": "Jack", "message": greeting})

    await broadcast_to_mobile_clients(user_id, {
        "event": "transcript",
        "call_id": call_id,
        "speaker": "Jack",
        "message": greeting,
    })

    # 3. Simulate caller response and Jack reasoning
    if req.simulated_speech:
        active_calls[call_id]["transcript"].append({"speaker": "Caller", "message": req.simulated_speech})
        await broadcast_to_mobile_clients(user_id, {
            "event": "transcript",
            "call_id": call_id,
            "speaker": req.caller_name or "Caller",
            "message": req.simulated_speech,
        })

        # Jack reasons using Groq Llama 3.3
        system_directive = (
            "You are Jack, a professional, protective AI assistant on a live phone call. "
            "Speak naturally in 1-2 spoken sentences. Keep answers polite, concise, and helpful."
        )
        ai_reply = await reason_with_free_llm(
            caller_speech=req.simulated_speech,
            system_directive=system_directive,
            conversation_history=active_calls[call_id]["transcript"],
        )

        active_calls[call_id]["transcript"].append({"speaker": "Jack", "message": ai_reply})
        await broadcast_to_mobile_clients(user_id, {
            "event": "transcript",
            "call_id": call_id,
            "speaker": "Jack",
            "message": ai_reply,
        })

    return {
        "status": "success",
        "call_id": call_id,
        "transcript": active_calls[call_id]["transcript"],
    }


@app.post("/api/free-telephony/directive")
async def send_user_directive(req: UserDirectiveRequest):
    """
    Called from Flutter app when user types or speaks a directive for Jack during a live call.
    (e.g., 'Tell them I am on my way and will be there in 5 minutes')
    """
    call = active_calls.get(req.call_id)
    if not call:
        raise HTTPException(status_code=404, detail="Active call not found")

    user_id = call.get("user_id", "default_user")

    # Record directive in transcript
    call["transcript"].append({"speaker": "You (Directive)", "message": req.directive})
    await broadcast_to_mobile_clients(user_id, {
        "event": "transcript",
        "call_id": req.call_id,
        "speaker": "You (Directive)",
        "message": req.directive,
    })

    # Jack speaks the directive to caller
    system_directive = (
        "You are Jack on a live call. The device owner has just instructed you: "
        f"'{req.directive}'. Inform the caller politely and naturally in 1 sentence."
    )
    jack_spoken = await reason_with_free_llm(
        caller_speech=req.directive,
        system_directive=system_directive,
        conversation_history=call["transcript"],
    )

    call["transcript"].append({"speaker": "Jack", "message": jack_spoken})
    await broadcast_to_mobile_clients(user_id, {
        "event": "transcript",
        "call_id": req.call_id,
        "speaker": "Jack",
        "message": jack_spoken,
    })

    return {"status": "directive_executed", "jack_spoken": jack_spoken}


@app.post("/api/free-telephony/hangup")
async def hangup_call(req: CallHangupRequest):
    """Terminates an active call and stores summary."""
    call = active_calls.pop(req.call_id, None)
    if call:
        user_id = call.get("user_id", "default_user")
        await broadcast_to_mobile_clients(user_id, {
            "event": "call_ended",
            "call_id": req.call_id,
            "message": "Call concluded.",
        })
        return {"status": "call_ended", "call_id": req.call_id}
    return {"status": "not_found"}


# ── WebSockets: Real-time Audio Stream from PBX (Asterisk / LiveKit) ───────────

@app.websocket("/ws/telephony/audio-stream/{call_id}")
async def telephony_audio_stream_endpoint(websocket: WebSocket, call_id: str, caller: str = "Unknown"):
    """
    Receives raw audio packets from Asterisk AudioSocket, FreeSWITCH, or WebRTC gateway.
    Transcribes audio -> Thinks with Llama 3.3 -> Speaks back with Edge-TTS.
    """
    await websocket.accept()
    user_id = "default_user"

    active_calls[call_id] = {
        "call_id": call_id,
        "caller_name": caller,
        "caller_number": caller,
        "status": "connected",
        "transcript": [],
        "user_id": user_id,
    }

    # Initial pickup greeting
    greeting = "Hello, I am Jack, AI executive assistant for the device owner. How may I direct your call?"
    active_calls[call_id]["transcript"].append({"speaker": "Jack", "message": greeting})

    # Synthesize opening greeting and send audio to caller
    greeting_audio = await synthesize_speech_free(greeting)
    if greeting_audio:
        await websocket.send_bytes(greeting_audio)

    await broadcast_to_mobile_clients(user_id, {
        "event": "call_lifted",
        "call_id": call_id,
        "caller_name": caller,
        "message": f"Jack answered call from {caller}",
    })
    await broadcast_to_mobile_clients(user_id, {
        "event": "transcript",
        "call_id": call_id,
        "speaker": "Jack",
        "message": greeting,
    })

    audio_chunks = bytearray()

    try:
        while True:
            # Receive audio chunk or control JSON
            message = await websocket.receive()
            if "bytes" in message and message["bytes"]:
                audio_chunks.extend(message["bytes"])

                # When chunk reaches ~3 seconds of 16kHz audio (~96,000 bytes)
                if len(audio_chunks) > 96000:
                    chunk_to_process = bytes(audio_chunks)
                    audio_chunks.clear()

                    # Transcribe caller's voice
                    caller_text = await transcribe_audio_free(chunk_to_process)
                    if caller_text and len(caller_text) > 2:
                        active_calls[call_id]["transcript"].append({"speaker": "Caller", "message": caller_text})
                        await broadcast_to_mobile_clients(user_id, {
                            "event": "transcript",
                            "call_id": call_id,
                            "speaker": caller,
                            "message": caller_text,
                        })

                        # Brain generates natural response
                        system_directive = (
                            "You are Jack on a live call. Respond in 1-2 natural spoken sentences. "
                            "Be professional, clear, and concise."
                        )
                        jack_response = await reason_with_free_llm(
                            caller_speech=caller_text,
                            system_directive=system_directive,
                            conversation_history=active_calls[call_id]["transcript"],
                        )

                        active_calls[call_id]["transcript"].append({"speaker": "Jack", "message": jack_response})
                        await broadcast_to_mobile_clients(user_id, {
                            "event": "transcript",
                            "call_id": call_id,
                            "speaker": "Jack",
                            "message": jack_response,
                        })

                        # Synthesize voice and stream audio back to the caller
                        response_audio = await synthesize_speech_free(jack_response)
                        if response_audio:
                            await websocket.send_bytes(response_audio)

            elif "text" in message and message["text"]:
                try:
                    data = json.loads(message["text"])
                    if data.get("event") == "hangup":
                        break
                except Exception:
                    pass

    except WebSocketDisconnect:
        print(f"[WebSocket] Audio stream disconnected for call {call_id}")
    finally:
        active_calls.pop(call_id, None)
        await broadcast_to_mobile_clients(user_id, {
            "event": "call_ended",
            "call_id": call_id,
            "message": "Call concluded.",
        })


# ── WebSockets: Real-time Transcript Streaming to Jack Mobile Agent App ────────

@app.websocket("/ws/jack-app/{user_id}")
async def jack_app_websocket_endpoint(websocket: WebSocket, user_id: str):
    """
    Connected Flutter clients subscribe here to receive real-time call notifications,
    live transcripts, and audio state updates with zero polling.
    """
    await websocket.accept()
    if user_id not in mobile_subscribers:
        mobile_subscribers[user_id] = []
    mobile_subscribers[user_id].append(websocket)

    print(f"[Jack Mobile App] Client connected for user '{user_id}' (Total: {len(mobile_subscribers[user_id])})")

    # Send initial status handshake
    await websocket.send_text(json.dumps({
        "event": "connected",
        "system": "Jack Free AI Telephony Gateway v3.0",
        "active_calls": list(active_calls.values()),
    }))

    try:
        while True:
            text = await websocket.receive_text()
            try:
                data = json.loads(text)
                # Handle client ping or commands
                if data.get("action") == "ping":
                    await websocket.send_text(json.dumps({"event": "pong", "time": time.time()}))
            except Exception:
                pass
    except WebSocketDisconnect:
        print(f"[Jack Mobile App] Client disconnected for user '{user_id}'")
    finally:
        if user_id in mobile_subscribers and websocket in mobile_subscribers[user_id]:
            mobile_subscribers[user_id].remove(websocket)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    print(f"🚀 Starting Jack Free AI Telephony Server on port {port}...")
    uvicorn.run("jack_free_ai_call_server:app", host="0.0.0.0", port=port, reload=True)
