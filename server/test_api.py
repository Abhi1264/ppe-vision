import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from server.main import create_app


class ApiTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.calls = 0

        def detect(_raw, _conf):
            self.calls += 1
            tracks = [
                {
                    "track_id": 4,
                    "confidence": 0.66,
                    "present": set(),
                    "person": [0.1, 0.1, 0.5, 0.9],
                    "boxes": {},
                    "xyxy": [1, 1, 8, 8],
                }
            ]
            return tracks, None

        self.app = create_app(detect=detect, db_path=root / "e.db", snap_dir=root / "snaps")
        self.client = TestClient(self.app)

    def tearDown(self):
        self.tmp.cleanup()

    def _post(self):
        return self.client.post(
            "/frames",
            data={"camera_id": "phone", "required": "hardhat,vest", "confirm_frames": "2", "conf": "0.25"},
            files={"file": ("frame.jpg", b"\xff\xd8\xff", "image/jpeg")},
        )

    def test_debounce_and_csv(self):
        first = self._post()
        self.assertEqual(first.status_code, 200)
        self.assertEqual(first.json()["opened"], [])
        second = self._post()
        self.assertEqual(second.status_code, 200)
        self.assertEqual(len(second.json()["opened"]), 2)
        third = self._post()
        self.assertEqual(third.json()["opened"], [])
        listed = self.client.get("/events", params={"camera_id": "phone"})
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(len(listed.json()), 2)
        csv_body = self.client.get("/events.csv").text
        self.assertIn("missing_hardhat", csv_body)
        self.assertIn("missing_vest", csv_body)
        stats = self.client.get("/stats").json()
        self.assertEqual(stats["events"], 2)
        self.assertEqual(stats["person_frames"], 3)
        self.assertEqual(stats["compliant_frames"], 0)
        report = self.client.get("/report").text
        self.assertIn("missing_hardhat: 1", report)
        missing = self.client.get("/events/1/snapshot")
        self.assertEqual(missing.status_code, 404)

    def test_bad_required(self):
        response = self.client.post(
            "/frames",
            data={"required": "helmet", "confirm_frames": "2"},
            files={"file": ("frame.jpg", b"abc", "image/jpeg")},
        )
        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
