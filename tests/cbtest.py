"""Shared helpers for the Crystal Ball test suite (stdlib only).

Locates the built Immolate binary and the Lua interpreter, and wraps the two
operations every backend test needs:
    run_immolate(query)  -> list of matching seeds over a range
    seed_matches(seed, query) -> bool   (re-checks one seed; self-verifying)
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
IMMOLATE_DIR = REPO_ROOT / "Immolate"
WATCHER = REPO_ROOT / "CrystalBall" / "linux" / "watcher.py"

# CI builds to Immolate/build/Immolate; a manual `cp` may place it beside the source.
_IMMOLATE_CANDIDATES = [
    IMMOLATE_DIR / "build" / "Immolate",
    IMMOLATE_DIR / "build" / "Release" / "Immolate.exe",
    IMMOLATE_DIR / "Immolate",
]


def immolate_bin() -> Path | None:
    """returns: path to a runnable Immolate binary, or None if not built."""
    for p in _IMMOLATE_CANDIDATES:
        if p.exists() and os.access(p, os.X_OK):
            return p
    return None


def lua_bin() -> str | None:
    """returns: 'lua' / 'luajit' name if a Lua interpreter is on PATH, else None."""
    return next((c for c in ("lua", "luajit") if shutil.which(c)), None)


# Immolate loads search.cl + filters/ + lib/ relative to its own cwd, so every
# invocation runs from IMMOLATE_DIR.
def _run(args: list[str], timeout: float) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(immolate_bin()), *args],
        cwd=IMMOLATE_DIR,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def run_immolate(query: str, *, start: str, n: int, filt: str = "find_joker", timeout: float = 120.0) -> list[str]:
    """All seeds matching `query` in the deterministic range [start, start+n).

    Enumeration over a fixed (start, n) is deterministic, so callers can assert
    set relationships (subset, monotonicity) without knowing seed contents.
    returns: sorted list of matching seed strings.
    """
    proc = _run(["-f", filt, "-q", "-s", start, "-n", str(n), "-j", query], timeout)
    if proc.returncode != 0:
        raise RuntimeError(f"Immolate failed (rc={proc.returncode}): {proc.stderr.strip()}")
    return sorted(s.strip() for s in proc.stdout.splitlines() if s.strip())


def seed_matches(seed: str, query: str, *, filt: str = "find_joker", timeout: float = 60.0) -> bool:
    """Whether a single `seed` satisfies `query` (searches exactly that seed).

    Used to verify a found seed actually matches, independent of which seed the
    search returned.
    """
    out = run_immolate(query, start=seed, n=1, filt=filt, timeout=timeout)
    return seed in out


def emit_query(keys: list[str], min_ante: int, max_ante: int, at_least: int | None = None) -> str:
    """The query JSON the mod would produce, built by the REAL Lua query-builder.

    raises: RuntimeError if no Lua interpreter is available.
    """
    lua = lua_bin()
    if not lua:
        raise RuntimeError("no Lua interpreter")
    args = [",".join(keys), str(min_ante), str(max_ante)]
    if at_least is not None:
        args.append(str(at_least))
    proc = subprocess.run(
        [lua, "tests/lua/emit_query.lua", *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=30,
        env={**os.environ, "CB_REPO_ROOT": str(REPO_ROOT)},
    )
    if proc.returncode != 0:
        raise RuntimeError(f"emit_query.lua failed: {proc.stderr.strip()}")
    return proc.stdout.strip()
