"""The 3 decision trees of edge_ai, as data: structure for the AI page and the path behind each decision.

The trees are read from edge_ai/edge/edge_models.py (the exact code that runs on the Pi), by parsing
its if/else with `ast`. So what the app shows can never drift from what the farm executes.
"""
import ast
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EDGE = ROOT / "edge_ai" / "edge"
BUILD = ROOT / "edge_ai" / "build"
sys.path.insert(0, str(EDGE))
sys.path.insert(0, str(ROOT / "edge_ai" / "training"))
import edge_models  # noqa: E402

FUNCS = {"irrigation": "predict_irrigation", "climate": "predict_climate", "anomaly": "predict_anomaly"}
METRIC_KEYS = {"irrigation": "tree_irrigation", "climate": "tree_climate", "anomaly": "tree_anomaly"}


def _node(stmt):
    if isinstance(stmt, ast.Return):
        return {"leaf": stmt.value.value}
    test = stmt.test                                   # always "feature <= threshold" (see train._gen)
    return {"f": test.left.id, "t": test.comparators[0].value,
            "l": _node(stmt.body[0]), "r": _node(stmt.orelse[0])}


def load_trees() -> dict:
    src = Path(edge_models.__file__).read_text(encoding="utf-8")
    fns = {f.name: f for f in ast.parse(src).body if isinstance(f, ast.FunctionDef)}
    return {name: {"features": [a.arg for a in fns[fn].args.args], "root": _node(fns[fn].body[0])}
            for name, fn in FUNCS.items()}


TREES = load_trees()


def explain(name: str, inputs: dict) -> dict:
    """Walk the tree like the Pi does and return every test on the way: [{f, t, v, le}], plus the leaf."""
    node, path = TREES[name]["root"], []
    while "leaf" not in node:
        v = inputs[node["f"]]
        le = v <= node["t"]
        path.append({"f": node["f"], "t": node["t"], "v": v, "le": le})
        node = node["l"] if le else node["r"]
    return {"label": node["leaf"], "path": path}


def model_card() -> dict:
    """Everything the AI page needs: trees, test metrics, readable rules, and the agronomist policy."""
    metrics = json.loads((BUILD / "metrics.json").read_text(encoding="utf-8"))
    from settings import DEFAULT_PROFILE                # pure Python, no scikit-learn needed
    return {
        "trees": {n: {**TREES[n], "metrics": metrics[METRIC_KEYS[n]]} for n in FUNCS},
        "policy": {"irrigation": DEFAULT_PROFILE["irrigation"], "climate": DEFAULT_PROFILE["climate"]},
        "crop": DEFAULT_PROFILE["name"],
    }
