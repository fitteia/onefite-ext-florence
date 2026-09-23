#!/usr/bin/env python3
"""Merge base and external per-model metadata with duplicate-name checks."""
import json
import pathlib
import sys

if len(sys.argv) < 4:
    raise SystemExit("usage: merge-meta.py BASE MODEL... OUTPUT")
base_path = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[-1])
model_paths = [pathlib.Path(p) for p in sys.argv[2:-1]]
base = json.loads(base_path.read_text()) if base_path.exists() else {}
if not isinstance(base, dict):
    raise SystemExit(f"{base_path}: metadata root must be an object")
merged = dict(base)
for model_path in model_paths:
    model = json.loads(model_path.read_text())
    functions = model.get("functions", {})
    if not isinstance(functions, dict):
        raise SystemExit(f"{model_path}: functions must be an object")
    for name, entry in functions.items():
        # BASE and OUTPUT are the same file (in-place update), so after the
        # first successful install this extension's own functions are
        # already present in `merged` on every later re-run - only treat
        # this as a genuine conflict when a DIFFERENT model defines the
        # same name with a different entry, not when it's this same
        # extension being reapplied unchanged.
        if name in merged and merged[name] != entry:
            raise SystemExit(f"duplicate external model function: {name} ({model_path})")
        merged[name] = entry
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(merged, indent=4, ensure_ascii=False) + "\n")
