-- backend/database_schema.sql
-- Multi-Tenant Telephony & AI Agent Database Schema
-- Production PostgreSQL DDL compatible with Railway, Supabase, Neon, and AWS RDS.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 1. Users Table ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ── 2. Telephony Profiles Table (Auto-linking SIM & Agent Persona) ────────────
CREATE TABLE IF NOT EXISTS telephony_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    personal_sim_number VARCHAR(32) NOT NULL, -- E.164 format, e.g. +14158920199
    is_caller_id_verified BOOLEAN DEFAULT FALSE,
    telephony_validation_sid VARCHAR(64), -- Twilio ValidationRequest SID
    target_forwarding_number VARCHAR(32) NOT NULL, -- System inbound DID dedicated/mapped to user
    agent_system_prompt TEXT NOT NULL DEFAULT 'You are Jack, a professional AI executive assistant answering calls for the device owner. Be polite, concise, and protect the owner from spam.',
    voice_engine VARCHAR(64) DEFAULT 'cartesia', -- 'cartesia' | 'elevenlabs' | 'deepgram'
    voice_id VARCHAR(128) DEFAULT 'british-baritone-jarvis',
    stt_model VARCHAR(64) DEFAULT 'deepgram-nova-2',
    llm_model VARCHAR(64) DEFAULT 'groq-llama-3.3-70b',
    ccf_activated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for fast call routing lookups
CREATE INDEX IF NOT EXISTS idx_telephony_sim ON telephony_profiles(personal_sim_number);
CREATE INDEX IF NOT EXISTS idx_telephony_forwarding ON telephony_profiles(target_forwarding_number);

-- ── 3. Call Sessions & Transcripts Table ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS call_sessions (
    call_id VARCHAR(64) PRIMARY KEY, -- Twilio Call SID or generated UUID
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    direction VARCHAR(20) NOT NULL, -- 'inbound_forwarded' | 'outbound_command'
    from_number VARCHAR(32) NOT NULL,
    to_number VARCHAR(32) NOT NULL,
    status VARCHAR(30) DEFAULT 'initiated', -- 'initiated', 'ringing', 'in_progress', 'completed', 'failed'
    duration_seconds INTEGER DEFAULT 0,
    transcript_json JSONB DEFAULT '[]'::jsonb,
    summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_call_user_id ON call_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_call_status ON call_sessions(status);
