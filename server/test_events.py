import tempfile
import unittest
from pathlib import Path

from server.events import Debouncer, Store, assign_ppe, parse_required


def _obs(track_id=1, present=(), confidence=0.5):
    return {
        "track_id": track_id,
        "present": set(present),
        "confidence": confidence,
        "xyxy": [0, 0, 10, 10],
    }


class DebounceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.store = Store(root / "events.db", root / "snaps")

    def tearDown(self):
        self.tmp.cleanup()

    def test_one_streak_is_one_event(self):
        deb = Debouncer(("hardhat", "vest"), confirm_frames=3)
        opened = []
        for index in range(5):
            opened = deb.step([_obs(present={"vest"})], f"t{index}", self.store, "cam")
        self.assertEqual(len(self.store.list_events(None, None, None, None)), 1)
        self.assertEqual(opened, [])
        event = self.store.list_events(None, None, None, None)[0]
        self.assertEqual(event["violation_type"], "missing_hardhat")
        self.assertEqual(event["start_time"], "t0")
        self.assertIsNone(event["end_time"])

    def test_compliance_closes_and_loss_closes(self):
        deb = Debouncer(("hardhat",), confirm_frames=1, lost_after=2)
        deb.step([_obs()], "t0", self.store, "cam")
        deb.step([_obs(present={"hardhat"})], "t1", self.store, "cam")
        event = self.store.get_event(1)
        self.assertEqual(event["end_time"], "t1")
        deb.step([_obs()], "t2", self.store, "cam")
        deb.step([], "t3", self.store, "cam")
        deb.step([], "t4", self.store, "cam")
        self.assertEqual(self.store.get_event(2)["end_time"], "t4")

    def test_assign_ppe_uses_smaller_person(self):
        people = [
            {"track_id": 1, "xyxy": [0, 0, 100, 100]},
            {"track_id": 2, "xyxy": [10, 10, 40, 40]},
        ]
        owned = assign_ppe(people, [("hardhat", [12, 12, 20, 20], 0.9)])
        self.assertIn("hardhat", owned[2])
        self.assertNotIn("hardhat", owned[1])

    def test_parse_required_rejects_helmet_alias(self):
        with self.assertRaises(ValueError):
            parse_required("helmet")
        self.assertEqual(parse_required("vest,hardhat"), ("hardhat", "vest"))


if __name__ == "__main__":
    unittest.main()
