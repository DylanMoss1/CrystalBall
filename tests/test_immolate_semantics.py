"""Query-grammar semantics, locked against the real Immolate (crystal_ball/
query_parse.h + filters/find_joker.cl).

Enumeration over a fixed (start, n) range is deterministic, so each property is
asserted as a set relation between match sets -- no hard-coded seed lists, robust
to which seeds happen to match. Skipped when Immolate isn't built.
"""

import json
import unittest

import cbtest

# Fixed deterministic window. Wide enough that the broad queries are non-empty.
START, N = "ABCD1234", 4000
A, B = "Blueprint", "Brainstorm"


def clause(items, lo, hi, at_least):
    return {"atLeast": at_least, "minAnte": lo, "maxAnte": hi, "of": items}


def query(*groups):
    """groups: each a list of clauses -> {"any":[{"all":[...]}, ...]}."""
    return json.dumps({"any": [{"all": cls} for cls in groups]})


_SKIP = "Immolate not built (run `make build_linux`)" if cbtest.immolate_bin() is None else None


@unittest.skipIf(_SKIP, _SKIP or "")
class SemanticsTest(unittest.TestCase):
    def matches(self, q):
        return set(cbtest.run_immolate(q, start=START, n=N))

    def test_range_is_deterministic(self):
        q = query([clause([A], 1, 8, 1)])
        self.assertEqual(self.matches(q), self.matches(q))

    def test_wider_ante_window_is_superset(self):
        narrow = self.matches(query([clause([A], 1, 1, 1)]))
        wide = self.matches(query([clause([A], 1, 8, 1)]))
        self.assertTrue(narrow <= wide)
        self.assertTrue(wide, "broad query unexpectedly empty -- check the range")

    def test_atleast_is_monotone(self):
        any_one = self.matches(query([clause([A, B], 1, 8, 1)]))
        both = self.matches(query([clause([A, B], 1, 8, 2)]))
        self.assertTrue(both <= any_one)

    def test_and_narrows(self):
        a_only = self.matches(query([clause([A], 1, 8, 1)]))
        both = self.matches(query([clause([A], 1, 8, 1), clause([B], 1, 8, 1)]))
        self.assertTrue(both <= a_only)

    def test_or_equals_union_and_atleast1_identity(self):
        a = self.matches(query([clause([A], 1, 8, 1)]))
        b = self.matches(query([clause([B], 1, 8, 1)]))
        # Two groups OR together == union of each group's matches.
        either = self.matches(query([clause([A], 1, 8, 1)], [clause([B], 1, 8, 1)]))
        self.assertEqual(either, a | b)
        # ... and "at least 1 of {A,B}" is the same set as that union.
        at_least_one = self.matches(query([clause([A, B], 1, 8, 1)]))
        self.assertEqual(at_least_one, a | b)


if __name__ == "__main__":
    unittest.main()
