"""CLI-contract tests for the Immolate binary itself (crystal_ball/query_parse.h
error paths).

These lock how the searcher reports bad input -- the behaviour the watcher and
the Windows inline path rely on to tell failure from a real seed. Skipped when
Immolate isn't built.
"""

import subprocess
import unittest

import cbtest

_SKIP = "Immolate not built (run `make build_linux`)" if cbtest.immolate_bin() is None else None


def _run(query=None, *, start="ABCD1234", n=1, timeout=60):
    args = ["-f", "find_joker", "-q", "-s", start, "-n", str(n)]
    if query is not None:
        args += ["-j", query]
    return subprocess.run(
        [str(cbtest.immolate_bin()), *args],
        cwd=cbtest.IMMOLATE_DIR, capture_output=True, text=True, timeout=timeout,
    )


@unittest.skipIf(_SKIP, _SKIP or "")
class ImmolateCliTest(unittest.TestCase):
    def test_malformed_json_fails(self):
        proc = _run("{not valid json")
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("Failed to parse", proc.stdout + proc.stderr)

    def test_unknown_item_fails(self):
        q = '{"any":[{"all":[{"atLeast":1,"minAnte":1,"maxAnte":8,"of":["NotARealJoker"]}]}]}'
        proc = _run(q)
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("Unknown item: NotARealJoker", proc.stdout + proc.stderr)

    def test_empty_any_matches_nothing(self):
        # A well-formed but empty query (numGroups=0) is valid and matches no seed.
        proc = _run('{"any":[]}', n=2000)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual([s for s in proc.stdout.splitlines() if s.strip()], [])

    def test_absent_query_matches_nothing(self):
        # No -j at all: query-aware filters see an empty query and match nothing.
        proc = _run(None, n=2000)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual([s for s in proc.stdout.splitlines() if s.strip()], [])


if __name__ == "__main__":
    unittest.main()
