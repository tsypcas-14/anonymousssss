"""SmartFarm server: runs the autonomous agent (3 decision trees, 100 % local) and serves the web app.

Simulation on a PC:  python -m uvicorn app.server.main:app --host 0.0.0.0 --port 8000
Raspberry Pi 3B:     SMARTFARM_MODE=real SMARTFARM_TRANSPLANT_DATE=2026-11-01 \
                     python -m uvicorn app.server.main:app --host 0.0.0.0 --port 8000
Then open http://<ip-of-this-machine>:8000 on a phone or PC on the same Wi-Fi.

Optional: SMARTFARM_VISION=1 also runs the YOLO camera watch (heavy; planned for phase 2, not for a Pi 3B).
"""
import asyncio
import json
import os
import sys
import time
from contextlib import asynccontextmanager
from datetime import datetime
from importlib.util import find_spec
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
import trees  # noqa: E402  (also puts edge_ai/edge on sys.path)
import stats  # noqa: E402
from auth import Auth, AuthError  # noqa: E402
from controller import Controller  # noqa: E402
from farm_sim import FAULTS, STEP_S, SimulatedFarm  # noqa: E402

WEB = HERE.parent / "web"
MODE = os.environ.get("SMARTFARM_MODE", "sim")
VISION = os.environ.get("SMARTFARM_VISION", "1" if MODE == "sim" and find_spec("ultralytics") else "0") == "1"
STATE_FILE = HERE / "data" / "state_real.json"
DB_FILE = HERE / "data" / ("smartfarm.db" if MODE == "real" else "smartfarm_sim.db")
CAPTURES = HERE / "data" / "captures"
REAL_PERIOD_S = 2.0
SPEEDS = [0, 1, 60, 600, 3600, 14400]          # virtual seconds per real second (0 = paused)
PREFILL_DAYS = 3                               # simulation starts with 3 days of history


class Runtime:
    def __init__(self):
        self.clients: set[WebSocket] = set()
        self.speed = 600
        self.acc = 0.0
        self.vision = None
        self.build()

    def build(self):
        if MODE == "real":
            from real_farm import RealFarm
            date = os.environ.get("SMARTFARM_TRANSPLANT_DATE")
            if not date:
                raise SystemExit("Set SMARTFARM_TRANSPLANT_DATE=YYYY-MM-DD (day the tomatoes were planted).")
            self.farm = RealFarm(datetime.fromisoformat(date))
            self.ctrl = Controller(self.farm)
            if STATE_FILE.exists():
                self.ctrl.restore(json.loads(STATE_FILE.read_text()))
        else:
            self.farm = SimulatedFarm()
            self.ctrl = Controller(self.farm)
            for _ in range(int(PREFILL_DAYS * 86400 / STEP_S)):
                self.sim_tick()
        if not VISION:
            self.ctrl.vision = {"status": "disabled", "detections": [], "image": None, "time": None,
                                "message": "Camera watch is off (planned for phase 2). Fire is watched by the flame sensor."}

    def sim_tick(self):
        self.farm.step(STEP_S)
        self.ctrl.step(self.farm.read())
        if self.farm.auto_refilled:
            self.farm.auto_refilled = False
            self.ctrl.log("info", "Reservoir refilled (simulated caretaker)",
                          "In the simulation the tank is refilled after 6 h empty. On the real farm you refill it.")

    def save(self):
        STATE_FILE.parent.mkdir(exist_ok=True)
        tmp = STATE_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.ctrl.dump()))
        tmp.replace(STATE_FILE)                     # atomic: a power cut never leaves half a file

    def snapshot(self) -> dict:
        extra = {"mode": MODE}
        if MODE == "sim":
            extra["sim"] = {"speed": self.speed, "speeds": SPEEDS, "fault": self.farm.fault,
                            "flame": self.farm.flame, "scene": self.vision.scene if self.vision else None}
        return self.ctrl.snapshot(extra)


rt: Runtime | None = None
auth: Auth | None = None


async def broadcast():
    msg = json.dumps(rt.snapshot())
    for ws in list(rt.clients):
        try:
            await ws.send_text(msg)
        except Exception:
            rt.clients.discard(ws)


async def sim_loop():
    last, last_push = time.monotonic(), 0.0
    while True:
        await asyncio.sleep(0.25)
        now = time.monotonic()
        rt.acc = min(rt.acc + (now - last) * rt.speed, 2000 * STEP_S)    # never fall more than 2000 ticks behind
        last = now
        while rt.acc >= STEP_S:
            rt.acc -= STEP_S
            rt.sim_tick()
        if now - last_push >= 0.5:
            last_push = now
            await broadcast()


async def real_loop():
    last_save = time.monotonic()
    while True:
        t0 = time.monotonic()
        try:
            reading = await asyncio.to_thread(rt.farm.read)
            rt.ctrl.step(reading)
        except Exception as e:                       # a sensor crash must never stop the agent: pump off, retry
            rt.farm.set_pump(False)
            rt.ctrl.log("warn", "Read error", str(e)[:160])
        await broadcast()
        if time.monotonic() - last_save >= 300:
            last_save = time.monotonic()
            await asyncio.to_thread(rt.save)
        await asyncio.sleep(max(0.05, REAL_PERIOD_S - (time.monotonic() - t0)))


async def vision_loop():
    from vision import Vision
    rt.vision = Vision(simulated=MODE != "real")
    await asyncio.to_thread(rt.vision.load)
    while True:
        try:
            result = await asyncio.to_thread(rt.vision.analyse_once)
        except Exception as e:                       # one bad frame must not stop the camera watch
            result = {"status": "unavailable", "detections": [], "image": None, "time": None,
                      "message": f"Camera error: {e}"}
        prev = rt.ctrl.vision.get("status")
        rt.ctrl.vision = result
        if result["status"] == "leaf_anomaly" and prev != "leaf_anomaly":
            rt.ctrl.log("warn", "Leaf anomaly seen by the camera", "A leaf looks diseased or damaged. Check the plants.")
        await asyncio.sleep(30 if result["status"] == "unavailable" else rt.vision.period())


@asynccontextmanager
async def lifespan(app: FastAPI):
    global rt, auth
    auth = Auth(DB_FILE, os.environ.get("SMARTFARM_CODE") or ("123456" if MODE == "sim" else None))
    print(f"\n  SmartFarm greenhouse code (needed to create an account): {auth.code}\n", flush=True)
    rt = Runtime()
    tasks = [asyncio.create_task(real_loop() if MODE == "real" else sim_loop())]
    if VISION:
        tasks.append(asyncio.create_task(vision_loop()))
    yield
    for t in tasks:
        t.cancel()
    if MODE == "real":
        rt.save()
        rt.farm.close()


app = FastAPI(title="SmartFarm", lifespan=lifespan)
# The Flutter app (and its browser build during development) calls this API from another origin.
# Sessions travel in the Authorization header, never in cookies, so allowing any origin is safe here.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class SimCmd(BaseModel):
    speed: float | None = None
    event: str | None = None     # flame | dry | refill | reset | leak | blocked | sensor | fix | camera_fire | leaf_anomaly | normal


class SignupIn(BaseModel):
    name: str
    email: str
    password: str
    code: str


class LoginIn(BaseModel):
    email: str
    password: str


class MeIn(BaseModel):
    name: str | None = None
    notify: str | None = None


class SettingsIn(BaseModel):
    name: str | None = None
    crop: str | None = None
    contact_name: str | None = None
    contact_phone: str | None = None


class WaterIn(BaseModel):
    seconds: int


class FanIn(BaseModel):
    on: bool


class ModeIn(BaseModel):
    equipment: str               # irrigation | fan
    mode: str                    # auto | manual


def bearer(authorization: str | None) -> str | None:
    if authorization and authorization.lower().startswith("bearer "):
        return authorization[7:].strip()
    return None


async def current_user(authorization: str | None = Header(default=None)) -> dict:
    user = auth.user_for(bearer(authorization))
    if not user:
        raise HTTPException(401, "Please sign in.")
    return user


# ---- public -----------------------------------------------------------------------------------
@app.get("/api/info")
async def get_info():
    """What the app needs before signing in: is this a SmartFarm, its name, does it have accounts yet."""
    st = auth.settings()
    return {"app": "smartfarm", "version": "1.0", "name": st["name"], "crop": st["crop"], "mode": MODE,
            "has_accounts": auth.user_count() > 0}


@app.post("/api/auth/signup")
async def post_signup(body: SignupIn):
    try:
        user, token = await asyncio.to_thread(auth.signup, body.name, body.email, body.password, body.code)
    except AuthError as e:
        raise HTTPException(400, str(e))
    rt.ctrl.log("info", f"{user['name']} joined the greenhouse", "New account created on the Pi.", kind="system")
    return {"user": user, "token": token}


@app.post("/api/auth/login")
async def post_login(body: LoginIn):
    try:
        user, token = await asyncio.to_thread(auth.login, body.email, body.password)
    except AuthError as e:
        raise HTTPException(401, str(e))
    return {"user": user, "token": token}


# ---- signed in ---------------------------------------------------------------------------------
@app.post("/api/auth/logout")
async def post_logout(authorization: str | None = Header(default=None), user: dict = Depends(current_user)):
    auth.logout(bearer(authorization))
    return {"ok": True}


@app.get("/api/me")
async def get_me(user: dict = Depends(current_user)):
    return {"user": user, "greenhouse": auth.settings(), "code": auth.code}


@app.patch("/api/me")
async def patch_me(body: MeIn, user: dict = Depends(current_user)):
    try:
        return {"user": auth.update_user(user["id"], body.name, body.notify)}
    except AuthError as e:
        raise HTTPException(400, str(e))


@app.get("/api/settings")
async def get_settings(user: dict = Depends(current_user)):
    return auth.settings()


@app.patch("/api/settings")
async def patch_settings(body: SettingsIn, user: dict = Depends(current_user)):
    try:
        return auth.update_settings(**body.model_dump())
    except AuthError as e:
        raise HTTPException(400, str(e))


@app.get("/api/state")
async def get_state(user: dict = Depends(current_user)):
    return rt.snapshot()


@app.get("/api/history")
async def get_history(hours: int = 24, user: dict = Depends(current_user)):
    pts = list(rt.ctrl.history)[-hours * 12:]
    stride = max(1, len(pts) // 400)
    return {"points": pts[::stride], "watered": [p["t"] for p in pts if p["pump"]]}


@app.get("/api/stats")
async def get_stats(hours: int = 24, user: dict = Depends(current_user)):
    if hours not in (24, 72, 168):
        raise HTTPException(400, "hours must be 24, 72 or 168")
    return stats.compute(rt.ctrl, hours)


@app.get("/api/ai")
async def get_ai(user: dict = Depends(current_user)):
    return {**trees.model_card(), "live": {"decision": rt.ctrl.decision, "last_diagnosis": rt.ctrl.last_diag,
                                           "sensors": rt.ctrl.sensors}}


@app.get("/api/events")
async def get_events(limit: int = 200, user: dict = Depends(current_user)):
    return list(rt.ctrl.events)[:max(1, min(limit, 400))]


def _real_time_for_demo():
    """In simulation, a command from the app slows time to real time so its steps can be watched."""
    if MODE == "sim" and rt.speed > 1:
        rt.speed = 1


@app.post("/api/water")
async def post_water(body: WaterIn, user: dict = Depends(current_user)):
    try:
        cmd = rt.ctrl.request("water", user["name"], seconds=body.seconds)
    except ValueError as e:
        raise HTTPException(400, str(e))
    _real_time_for_demo()
    await broadcast()
    return cmd


@app.post("/api/water/stop")
async def post_water_stop(user: dict = Depends(current_user)):
    rt.ctrl.stop_watering(user["name"])
    await broadcast()
    return rt.ctrl.command or {}


@app.post("/api/fan")
async def post_fan(body: FanIn, user: dict = Depends(current_user)):
    cmd = rt.ctrl.request("fan", user["name"], on=body.on)
    _real_time_for_demo()
    await broadcast()
    return cmd


@app.post("/api/mode")
async def post_mode(body: ModeIn, user: dict = Depends(current_user)):
    try:
        rt.ctrl.set_mode(body.equipment, body.mode, user["name"])
    except ValueError as e:
        raise HTTPException(400, str(e))
    await broadcast()
    return rt.snapshot()["modes"]


@app.post("/api/pump/unlock")
async def post_unlock(user: dict = Depends(current_user)):
    if not rt.ctrl.locked:
        return {"ok": False, "message": "The pump is not locked."}
    rt.ctrl.unlock_pump(user["name"])
    if MODE == "real":
        await asyncio.to_thread(rt.save)
    await broadcast()
    return {"ok": True, "message": "Pump unlocked. The next watering will be checked again."}


@app.post("/api/sim")
async def post_sim(cmd: SimCmd, user: dict = Depends(current_user)):
    if MODE != "sim":
        raise HTTPException(400, "Only available in simulation mode.")
    f, c, ev = rt.farm, rt.ctrl, cmd.event
    if cmd.speed is not None:
        if cmd.speed not in SPEEDS:
            raise HTTPException(400, f"speed must be one of {SPEEDS}")
        rt.speed = cmd.speed
    if ev == "flame":
        f.flame = not f.flame
        c.log("user", "Demo: flame sensor " + ("triggered" if f.flame else "cleared"), "Simulated from the app.", kind="safety")
    elif ev in FAULTS:
        f.fault = ev
        c.log("user", f"Demo: fault injected ({ev})", "The next watering will show it. Tree 3 should diagnose it.")
    elif ev == "fix":
        f.fault = None
        c.log("user", "Demo: hardware repaired", "Faults removed. Unlock the pump if it was locked.")
    elif ev == "refill":
        f.refill()
        c.log("user", "Demo: tank filled", "Simulated refill from the app.", kind="tank")
    elif ev == "dry":
        f.dry_out()
        c.log("user", "Demo: soil dried out", "Soil set to 700 raw. Tree 1 should ask for water.", kind="irrigation")
    elif ev in ("camera_fire", "leaf_anomaly", "normal"):
        if not (rt.vision and rt.vision.model):
            raise HTTPException(400, "Camera model not available on this machine.")
        rt.vision.scene, rt.vision.fire_streak = ("fire" if ev == "camera_fire" else ev), 0
    elif ev == "reset":
        rt.build()
    elif ev is not None:
        raise HTTPException(400, "unknown event")
    await broadcast()
    return rt.snapshot()


@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket, token: str | None = None):
    if not auth.user_for(token):                    # browsers cannot send headers on a WebSocket: token in the URL
        await ws.close(code=4401)
        return
    await ws.accept()
    rt.clients.add(ws)
    try:
        await ws.send_text(json.dumps(rt.snapshot()))
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        rt.clients.discard(ws)


CAPTURES.mkdir(parents=True, exist_ok=True)
app.mount("/captures", StaticFiles(directory=CAPTURES), name="captures")


@app.get("/")
async def index():
    return FileResponse(WEB / "index.html", headers={"Cache-Control": "no-cache"})


app.mount("/", StaticFiles(directory=WEB), name="web")
