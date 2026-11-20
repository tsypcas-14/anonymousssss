"""Accounts, sessions and greenhouse settings, stored on the Pi in SQLite (no cloud).

Sign up needs the greenhouse code: 6 digits generated on the first start and written to
app/server/data/greenhouse_code.txt (also printed in the logs). Anyone on the Wi-Fi can open the app,
but only people who have read that code on the Pi can create an account and control the pump.
"""
import hashlib
import hmac
import re
import secrets
import sqlite3
import threading
import time
from functools import wraps
from pathlib import Path

SESSION_DAYS = 30
PBKDF2_ROUNDS = 120_000           # ~0.3 s on a Pi 3B: slow enough for guessing, fast enough to sign in
EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
DEFAULTS = {"name": "My greenhouse", "crop": "tomatoes", "contact_name": "", "contact_phone": ""}


class AuthError(ValueError):
    pass


def locked(fn):
    """One SQLite connection is shared by the server's threads: let only one of them use it at a time."""
    @wraps(fn)
    def run(self, *a, **k):
        with self._lock:
            return fn(self, *a, **k)
    return run


def _hash(password: str, salt: bytes) -> str:
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, PBKDF2_ROUNDS).hex()


class Auth:
    def __init__(self, path: Path, code: str | None = None):
        path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self.db = sqlite3.connect(path, check_same_thread=False)
        self.db.row_factory = sqlite3.Row
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE COLLATE NOCASE, pw TEXT NOT NULL, salt TEXT NOT NULL,
                notify TEXT NOT NULL DEFAULT 'important', created REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id INTEGER NOT NULL,
                expires REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);""")
        if code:
            self._set("code", code)
        elif not self._get("code"):
            self._set("code", f"{secrets.randbelow(10**6):06d}")
        (path.parent / "greenhouse_code.txt").write_text(self.code + "\n")
        self.db.commit()

    # ---- settings ------------------------------------------------------------------------------
    def _get(self, key):
        row = self.db.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
        return row["value"] if row else None

    def _set(self, key, value):
        self.db.execute("INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                        (key, str(value)))

    @property
    @locked
    def code(self) -> str:
        return self._get("code")

    @locked
    def settings(self) -> dict:
        return {k: self._get(k) if self._get(k) is not None else v for k, v in DEFAULTS.items()}

    @locked
    def update_settings(self, **changes) -> dict:
        for k, v in changes.items():
            if k in DEFAULTS and v is not None:
                v = str(v).strip()[:60]
                if k == "name" and not v:
                    raise AuthError("The greenhouse needs a name.")
                self._set(k, v)
        self.db.commit()
        return self.settings()

    # ---- accounts ------------------------------------------------------------------------------
    @locked
    def user_count(self) -> int:
        return self.db.execute("SELECT COUNT(*) FROM users").fetchone()[0]

    @locked
    def signup(self, name: str, email: str, password: str, code: str) -> tuple[dict, str]:
        name, email = (name or "").strip(), (email or "").strip().lower()
        if not hmac.compare_digest((code or "").strip(), self.code):
            time.sleep(0.5)
            raise AuthError("Wrong greenhouse code. Read it on the Pi (greenhouse_code.txt or the logs).")
        if not name:
            raise AuthError("Please enter your first name.")
        if not EMAIL.match(email):
            raise AuthError("This email address does not look right.")
        if len(password or "") < 8:
            raise AuthError("The password needs at least 8 characters.")
        if self.db.execute("SELECT 1 FROM users WHERE email=?", (email,)).fetchone():
            raise AuthError("An account already exists with this email. Sign in instead.")
        salt = secrets.token_bytes(16)
        cur = self.db.execute("INSERT INTO users(name, email, pw, salt, created) VALUES(?,?,?,?,?)",
                              (name[:40], email, _hash(password, salt), salt.hex(), time.time()))
        self.db.commit()
        return self.user(cur.lastrowid), self._session(cur.lastrowid)

    @locked
    def login(self, email: str, password: str) -> tuple[dict, str]:
        row = self.db.execute("SELECT * FROM users WHERE email=?", ((email or "").strip().lower(),)).fetchone()
        if not row or not hmac.compare_digest(_hash(password or "", bytes.fromhex(row["salt"])), row["pw"]):
            time.sleep(0.5)                                  # slows down password guessing
            raise AuthError("Wrong email or password.")
        return self.user(row["id"]), self._session(row["id"])

    def _session(self, user_id: int) -> str:
        token = secrets.token_urlsafe(32)
        now = time.time()
        self.db.execute("DELETE FROM sessions WHERE expires < ?", (now,))
        self.db.execute("INSERT INTO sessions VALUES(?,?,?)", (token, user_id, now + SESSION_DAYS * 86400))
        self.db.commit()
        return token

    @locked
    def user(self, user_id: int) -> dict | None:
        row = self.db.execute("SELECT id, name, email, notify, created FROM users WHERE id=?", (user_id,)).fetchone()
        return dict(row) if row else None

    @locked
    def user_for(self, token: str | None) -> dict | None:
        if not token:
            return None
        row = self.db.execute("SELECT user_id FROM sessions WHERE token=? AND expires > ?", (token, time.time())).fetchone()
        return self.user(row["user_id"]) if row else None

    @locked
    def logout(self, token: str):
        self.db.execute("DELETE FROM sessions WHERE token=?", (token,))
        self.db.commit()

    @locked
    def update_user(self, user_id: int, name: str | None = None, notify: str | None = None) -> dict:
        if name is not None:
            if not name.strip():
                raise AuthError("Please enter your first name.")
            self.db.execute("UPDATE users SET name=? WHERE id=?", (name.strip()[:40], user_id))
        if notify is not None:
            if notify not in ("important", "all"):
                raise AuthError("notify must be 'important' or 'all'.")
            self.db.execute("UPDATE users SET notify=? WHERE id=?", (notify, user_id))
        self.db.commit()
        return self.user(user_id)
