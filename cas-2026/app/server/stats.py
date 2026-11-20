"""Statistics for the Stats tab, computed from the 5-minute history kept by the controller."""
from collections import Counter, defaultdict
from datetime import datetime

from config import model_cm_to_liters

from controller import HISTORY_EVERY_S, STRESS_RAW

TEMP_OK = (18.0, 28.0)              # comfortable air range for tomato


def _summary(vals):
    vals = [v for v in vals if v is not None]
    if not vals:
        return None
    return {"min": round(min(vals), 1), "mean": round(sum(vals) / len(vals), 1), "max": round(max(vals), 1)}


def _histogram(vals, lo, hi, bins):
    w = (hi - lo) / bins
    counts = [0] * bins
    for v in vals:
        if v is not None:
            counts[min(bins - 1, max(0, int((v - lo) // w)))] += 1
    return {"edges": [round(lo + i * w, 1) for i in range(bins + 1)], "counts": counts}


def compute(ctrl, hours: int) -> dict:
    pts = list(ctrl.history)[-int(hours * 3600 / HISTORY_EVERY_S):]
    since = pts[0]["t"] if pts else ""
    diags = [d for d in ctrl.diagnoses if d["time"] >= since]
    soil_raw = [p["soil_raw"] for p in pts if p["soil_raw"] is not None]
    temps = [p["temp"] for p in pts if p["temp"] is not None]

    # Per day and per hour of day
    days, by_hour = defaultdict(list), defaultdict(list)
    for p in pts:
        days[p["t"][:10]].append(p)
        by_hour[int(p["t"][11:13])].append(p)
    water_by_day = Counter()
    for d in diags:
        water_by_day[d["time"][:10]] += max(0.0, model_cm_to_liters(d["inputs"]["water_drop_cm"]))
    daily = []
    for day, ps in sorted(days.items()):
        t = _summary([p["temp"] for p in ps]) or {}
        daily.append({
            "date": day, "label": datetime.fromisoformat(day).strftime("%a %d %b"),
            "pulses": sum(p["pump"] for p in ps), "water_l": round(water_by_day[day], 2),
            "fan_h": round(sum(p["fan"] for p in ps) * HISTORY_EVERY_S / 3600, 1),
            "temp_min": t.get("min"), "temp_mean": t.get("mean"), "temp_max": t.get("max"),
            "soil_mean": (_summary([p["soil"] for p in ps]) or {}).get("mean"),
            "hum_mean": (_summary([p["hum"] for p in ps]) or {}).get("mean"),
            "light_max": max((p["light"] or 0 for p in ps), default=0),
            "complete": len(ps) >= 0.9 * 86400 / HISTORY_EVERY_S,
        })

    n = len(pts) or 1
    return {
        "hours": hours, "points": len(pts), "since": since,
        "kpi": {
            "pulses": sum(p["pump"] for p in pts),
            "water_l": round(sum(water_by_day.values()), 2),
            "fan_pct": round(100 * sum(p["fan"] for p in pts) / n, 1),
            "fan_h": round(sum(p["fan"] for p in pts) * HISTORY_EVERY_S / 3600, 1),
            "soil_ok_pct": round(100 * sum(v <= STRESS_RAW for v in soil_raw) / (len(soil_raw) or 1), 1),
            "temp_ok_pct": round(100 * sum(TEMP_OK[0] <= v <= TEMP_OK[1] for v in temps) / (len(temps) or 1), 1),
            "soil": _summary([p["soil"] for p in pts]), "soil_raw": _summary(soil_raw),
            "temp": _summary(temps), "hum": _summary([p["hum"] for p in pts]),
            "light_max": max((p["light"] or 0 for p in pts), default=0),
            "tank_now": pts[-1]["tank"] if pts else None,
            "efficiency_pct": round(100 * sum(d["label"] == "NORMAL" for d in diags) / len(diags), 1) if diags else None,
        },
        "decisions": {"irrigation": dict(Counter(p["irr"] for p in pts if p["irr"])),
                      "climate": dict(Counter(p["clim"] for p in pts if p["clim"]))},
        "anomalies": dict(Counter(d["label"] for d in diags)),
        "daily": daily,
        "by_hour": {
            "pulses": [sum(p["pump"] for p in by_hour[h]) for h in range(24)],
            "temp": [_summary([p["temp"] for p in by_hour[h]]) for h in range(24)],
            "soil": [(_summary([p["soil"] for p in by_hour[h]]) or {}).get("mean") for h in range(24)],
        },
        "hist": {"soil": _histogram([p["soil"] for p in pts], 0, 100, 10),
                 "temp": _histogram(temps, 10, 40, 15)},
        "diagnoses": diags[:20],
        "thresholds": {"stress_raw": STRESS_RAW, "temp_ok": TEMP_OK},
    }
