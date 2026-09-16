"""Unit tests for independent local timing analysis / Tests de l'audit local."""
import math
import unittest
from audit_task2 import band_entry


class TimingAuditTests(unittest.TestCase):
    def setUp(self):
        self.time = [i*.002 for i in range(201)]

    def test_full_dwell(self):
        self.assertEqual(band_entry(self.time, [.1]*201, .1), 0)

    def test_delayed_entry(self):
        errors = [.2 if t < .14-1e-12 else .05 for t in self.time]
        self.assertAlmostEqual(band_entry(self.time, errors, .1), .04)

    def test_break_at_dwell_endpoint(self):
        errors = [.05]*201; errors[100] = .11
        self.assertAlmostEqual(band_entry(self.time, errors, .1), .102)

    def test_insufficient_record(self):
        self.assertIsNone(band_entry(self.time[:100], [.05]*100, .1))

    def test_nonfinite_cannot_pass(self):
        self.assertIsNone(band_entry(self.time, [math.nan]*201, .1))

    def test_gap_cannot_pass(self):
        t = [0., .002, .004, .2, .202]
        self.assertIsNone(band_entry(t, [.05]*5, 0.))

    def test_late_recovery_is_not_deadline_pass(self):
        errors = [.2 if t < .16-1e-12 else 0. for t in self.time]
        self.assertGreater(band_entry(self.time, errors, .1), .05)

    def test_nonmonotonic_rejected(self):
        with self.assertRaises(AssertionError):
            band_entry([0., .1, .1], [0.]*3, 0.)


if __name__ == '__main__':
    unittest.main()
