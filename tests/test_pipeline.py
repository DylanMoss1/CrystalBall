"""End-to-end backend pipeline: the most e2e test without launching Balatro.

    Lua mod.build_criteria/query_json  (real query-builder)
        -> request.txt
        -> watcher.py                  (real host bridge)
        -> Immolate                    (real searcher, on the GPU)
        -> response.txt
        -> seed, re-verified to actually satisfy the query.

Skipped when Immolate isn't built or no Lua interpreter is present.
"""

import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

import cbtest

_SKIP = None
if cbtest.immolate_bin() is None:
    _SKIP = "Immolate not built (run `make build_linux`)"
elif cbtest.lua_bin() is None:
    _SKIP = "no Lua interpreter on PATH"


@unittest.skipIf(_SKIP, _SKIP or "")
class PipelineTest(unittest.TestCase):
    def _through_watcher(self, query, rid="pipeline-1", timeout=180):
        """Run one request through the real watcher + Immolate; returns the payload."""
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            req, resp = d / "request.txt", d / "response.txt"
            proc = subprocess.Popen(
                [sys.executable, str(cbtest.WATCHER), "--dir", str(d),
                 "--immolate", str(cbtest.immolate_bin()), "--interval", "0.05"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            self.addCleanup(proc.wait)
            self.addCleanup(proc.terminate)
            time.sleep(0.2)
            req.write_text(f"{rid}\n{query}\n", encoding="utf-8")

            deadline = time.time() + timeout
            while time.time() < deadline:
                if resp.exists():
                    head = resp.read_text(encoding="utf-8").split("\n")
                    if head[0].strip() == rid:
                        return head[1].strip()
                time.sleep(0.1)
        self.fail(f"watcher returned no response for {rid} within {timeout}s")

    def _assert_pipeline_seed(self, keys, lo, hi, at_least):
        query = cbtest.emit_query(keys, lo, hi, at_least)  # the REAL Lua builder
        payload = self._through_watcher(query)
        self.assertFalse(payload.startswith("ERROR"), f"search failed: {payload}")
        self.assertRegex(payload, r"^[A-Z0-9]{1,8}$", "not a well-formed seed")
        # The headline assertion: the produced seed really satisfies the query.
        self.assertTrue(cbtest.seed_matches(payload, query), f"{payload} does not satisfy {query}")

    def test_single_joker_query_yields_matching_seed(self):
        # Blueprint within antes 1-8: common enough that --first returns quickly.
        self._assert_pipeline_seed(["j_blueprint"], 1, 8, 1)

    def test_multi_joker_atleast_one_yields_matching_seed(self):
        # "at least 1 of {Blueprint, Brainstorm}" -- exercises the multi-item of[].
        self._assert_pipeline_seed(["j_blueprint", "j_brainstorm"], 1, 8, 1)

    def test_malformed_query_resolves_as_error(self):
        # A bad query must come back as an ERROR payload, never a bogus seed.
        payload = self._through_watcher("{not valid json", rid="pipeline-bad", timeout=30)
        self.assertTrue(payload.startswith("ERROR"), payload)


if __name__ == "__main__":
    unittest.main()
