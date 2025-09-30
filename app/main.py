"""Simple FastAPI application providing key management endpoints.

This API is designed to support the Roblox GUI scripts in this
repository by offering a small backend for distributing and verifying
keys.  It stores data inside ``data/keys.json`` so it can be inspected
or edited manually during a school project demo.
"""
from __future__ import annotations

import json
import threading
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

DATA_FILE = Path(__file__).resolve().parent.parent / "data" / "keys.json"
DATA_FILE.parent.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Aurora Key API", version="1.0.0")


def _utcnow() -> datetime:
    """Return timezone-aware UTC datetime."""

    return datetime.now(timezone.utc)


class KeyRecord(BaseModel):
    key: str
    owner: Optional[str] = Field(
        default=None, description="Optional identifier for who the key belongs to"
    )
    created_at: datetime = Field(default_factory=_utcnow)
    expires_at: Optional[datetime] = Field(
        default=None, description="When the key will become invalid"
    )
    revoked: bool = Field(default=False, description="Whether the key has been revoked")

    def is_valid(self) -> bool:
        if self.revoked:
            return False
        if self.expires_at and self.expires_at <= _utcnow():
            return False
        return True


class KeyStore:
    """Tiny JSON backed key storage with thread-safety."""

    def __init__(self, file_path: Path) -> None:
        self.file_path = file_path
        self._lock = threading.RLock()
        if not self.file_path.exists():
            self._write({})

    # Internal helpers -------------------------------------------------
    def _read(self) -> Dict[str, Dict]:
        with self.file_path.open("r", encoding="utf-8") as fp:
            raw = json.load(fp)
        if not isinstance(raw, dict):
            raise ValueError("Key store is corrupted: expected mapping at top level")
        return raw

    def _write(self, data: Dict[str, Dict]) -> None:
        self.file_path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")

    # Public operations ------------------------------------------------
    def issue(self, owner: Optional[str], lifespan_hours: Optional[int]) -> KeyRecord:
        with self._lock:
            data = self._read()
            new_key = self._generate_key(data)
            expires_at = (
                _utcnow() + timedelta(hours=lifespan_hours)
                if lifespan_hours is not None
                else None
            )
            record = KeyRecord(key=new_key, owner=owner, expires_at=expires_at)
            data[new_key] = record.model_dump()
            self._write(data)
            return record

    def verify(self, key: str) -> KeyRecord:
        with self._lock:
            data = self._read()
            payload = data.get(key)
            if not payload:
                raise KeyError("Key not found")
            record = KeyRecord(**payload)
            if not record.is_valid():
                raise ValueError("Key is revoked or expired")
            return record

    def revoke(self, key: str) -> KeyRecord:
        with self._lock:
            data = self._read()
            payload = data.get(key)
            if not payload:
                raise KeyError("Key not found")
            record = KeyRecord(**payload)
            record.revoked = True
            data[key] = record.model_dump()
            self._write(data)
            return record

    def get(self, key: str) -> KeyRecord:
        with self._lock:
            data = self._read()
            payload = data.get(key)
            if not payload:
                raise KeyError("Key not found")
            return KeyRecord(**payload)

    @staticmethod
    def _generate_key(existing: Dict[str, Dict]) -> str:
        base = _utcnow().strftime("%Y%m%d%H%M%S%f")
        counter = 0
        candidate = base
        while candidate in existing:
            counter += 1
            candidate = f"{base}-{counter}"
        return candidate


STORE = KeyStore(DATA_FILE)


class IssueRequest(BaseModel):
    owner: Optional[str] = Field(None, description="Who the key is for")
    lifespan_hours: Optional[int] = Field(
        None, ge=1, le=24 * 30, description="How long the key should stay valid"
    )


class VerifyRequest(BaseModel):
    key: str = Field(..., min_length=1)


class VerifyResponse(BaseModel):
    key: str
    owner: Optional[str]
    expires_at: Optional[datetime]
    created_at: datetime
    valid: bool


@app.get("/health", summary="Health check endpoint")
def health() -> Dict[str, str]:
    return {"status": "ok", "time": _utcnow().isoformat()}


@app.post("/keys", response_model=KeyRecord, summary="Issue a new key")
def issue_key(payload: IssueRequest) -> KeyRecord:
    return STORE.issue(owner=payload.owner, lifespan_hours=payload.lifespan_hours)


@app.post("/keys/verify", response_model=VerifyResponse, summary="Validate a key")
def verify_key(payload: VerifyRequest) -> VerifyResponse:
    try:
        record = STORE.verify(payload.key)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    return VerifyResponse(
        key=record.key,
        owner=record.owner,
        expires_at=record.expires_at,
        created_at=record.created_at,
        valid=True,
    )


@app.post("/keys/revoke", response_model=KeyRecord, summary="Revoke an existing key")
def revoke_key(payload: VerifyRequest) -> KeyRecord:
    try:
        return STORE.revoke(payload.key)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get("/keys/{key}", response_model=KeyRecord, summary="Look up a key without validation")
def get_key(key: str) -> KeyRecord:
    try:
        return STORE.get(key)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
