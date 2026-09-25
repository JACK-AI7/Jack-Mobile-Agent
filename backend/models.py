# backend/models.py
"""
SQLAlchemy Async ORM Models for Multi-Tenant Telephony & AI Agent Orchestration.
Supports PostgreSQL (Railway / Supabase / Neon / RDS) and SQLite fallback.
"""

import uuid
from datetime import datetime
from typing import Optional, List, Any
from sqlalchemy import (
    Column,
    String,
    Boolean,
    DateTime,
    Text,
    Integer,
    ForeignKey,
    JSON,
)
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    user_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    telephony_profile = relationship("TelephonyProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    calls = relationship("CallSession", back_populates="user", cascade="all, delete-orphan")


class TelephonyProfile(Base):
    __tablename__ = "telephony_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.user_id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    personal_sim_number = Column(String(32), nullable=False, index=True) # e.g. +14158920199
    is_caller_id_verified = Column(Boolean, default=False)
    telephony_validation_sid = Column(String(64), nullable=True)
    target_forwarding_number = Column(String(32), nullable=False, index=True) # Twilio DID
    agent_system_prompt = Column(
        Text,
        nullable=False,
        default="You are Jack, a professional AI executive assistant answering calls for the device owner. Be polite, concise, and protect the owner from spam.",
    )
    voice_engine = Column(String(64), default="cartesia")
    voice_id = Column(String(128), default="british-baritone-jarvis")
    stt_model = Column(String(64), default="deepgram-nova-2")
    llm_model = Column(String(64), default="groq-llama-3.3-70b")
    ccf_activated = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="telephony_profile")


class CallSession(Base):
    __tablename__ = "call_sessions"

    call_id = Column(String(64), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False, index=True)
    direction = Column(String(20), nullable=False) # 'inbound_forwarded' | 'outbound_command'
    from_number = Column(String(32), nullable=False)
    to_number = Column(String(32), nullable=False)
    status = Column(String(30), default="initiated")
    duration_seconds = Column(Integer, default=0)
    transcript_json = Column(JSON, default=list) # [{'speaker': 'Jack', 'message': '...', 'timestamp': '...'}]
    summary = Column(Text, nullable=True)
    recording_url = Column(String(512), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="calls")
