# 📞 Jack Free Open-Source AI Telephony (Zero Cost Setup)

This directory provides the complete setup to let Jack **answer real phone calls and talk to callers in real-time**, completely **free of cost ($0.00)** using open-source software.

---

## 🏗️ Architecture

```
[ Incoming Call to Your Phone ]
             │
   (You decline or 2 rings pass)
             │
             ▼
[ Carrier Forwards Call for FREE (*004*) ]
             │
             ▼
[ Asterisk PBX / LiveKit SIP Gateway ]
             │
             ▼ (AudioSocket / RTP Audio)
[ Jack Free AI Server (backend/jack_free_ai_call_server.py) ]
    ├─ Faster-Whisper / Groq Whisper (STT)
    ├─ Groq Llama 3.3 70B (LLM Reasoning)
    └─ Edge-TTS Neural Voice (British Baritone TTS)
             │
             ▼ (WebSocket)
[ Jack Mobile Agent Flutter App ]
  • Shows live transcript
  • Displays caller details
  • Allows 1-tap "Take Over" or "Whisper Directive"
```

---

## 🚀 Quick Start Guide (5 Minutes)

### Step 1: Run the Free AI Server
```bash
# In the repository root:
cd backend
pip install fastapi uvicorn httpx websockets edge-tts
python jack_free_ai_call_server.py
```
Server starts on port `8000`.

### Step 2: Start Asterisk PBX (Docker)
```bash
cd backend/asterisk_setup
docker compose -f docker-compose.telephony.yml up -d
```

### Step 3: Forward Calls to Your Free DID
On your smartphone dial pad:
- Dial `*004*<YOUR_FREE_DID_NUMBER>#` and tap Call.
- Your mobile carrier (Jio, Airtel, T-Mobile, AT&T, Verizon) will display: **"Call forwarding registration was successful"**.
- This is **100% free** under unlimited calling mobile plans.

### To Deactivate Call Forwarding Anytime:
- Dial `##004#` on your phone dial pad and tap Call.

---

## 🆓 What Makes This 100% Free?
1. **Asterisk PBX**: 100% Free, open source (GPL).
2. **Groq Llama 3.3 70B & Whisper**: Free Tier with 14,400 requests/day, 30 req/min.
3. **Edge-TTS**: Open source library for Microsoft's high-fidelity neural voices, zero cost, zero API keys.
4. **Call Forwarding**: Standard GSM feature included free in mobile plans.
