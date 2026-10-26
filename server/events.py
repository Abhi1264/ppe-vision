"""Violation events: one row per streak, not one per frame."""

from __future__ import annotations

import sqlite3
import threading
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

ALLOWED = ("hardhat", "vest")


def parse_required(raw: str) -> tuple[str, ...]:
    names = {part.strip() for part in raw.split(",") if part.strip()}
    if not names or not names <= set(ALLOWED):
        raise ValueError("required must list hardhat, vest, or both")
    return tuple(name for name in ALLOWED if name in names)


def assign_ppe(people: list[dict], items: list[tuple]) -> dict[int, dict]:
    """Give each PPE box to the smallest person box that contains its center.

    people: {track_id, xyxy}
    items: (label, xyxy, confidence)
    returns track_id -> {label: xyxy}
    """
    owned: dict[int, dict] = {person["track_id"]: {} for person in people}
    for label, xyxy, _conf in items:
        cx = (xyxy[0] + xyxy[2]) / 2
        cy = (xyxy[1] + xyxy[3]) / 2
        best_id = None
        best_area = None
        for person in people:
            x1, y1, x2, y2 = person["xyxy"]
            if x1 <= cx <= x2 and y1 <= cy <= y2:
                area = (x2 - x1) * (y2 - y1)
                if best_area is None or area < best_area:
                    best_id = person["track_id"]
                    best_area = area
        if best_id is not None:
            owned[best_id][label] = list(xyxy)
    return owned


@dataclass
class _Track:
    missing: dict[str, int] = field(default_factory=dict)
    since: dict[str, str] = field(default_factory=dict)
    open_ids: dict[str, int] = field(default_factory=dict)
    absent: int = 0


class Debouncer:
    def __init__(self, required: tuple[str, ...], confirm_frames: int, lost_after: int = 15):
        if confirm_frames < 1:
            raise ValueError("confirm_frames must be >= 1")
        if lost_after < 1:
            raise ValueError("lost_after must be >= 1")
        self.required = required
        self.confirm_frames = confirm_frames
        # ponytail: a track missing this many frames is closed. Raise if ByteTrack blinks.
        self.lost_after = lost_after
        self.tracks: dict[int, _Track] = {}

    def step(self, observations: list[dict], now: str, store: "Store", camera_id: str) -> list[dict]:
        seen: set[int] = set()
        opened: list[dict] = []
        person_frames = 0
        compliant_frames = 0
        for obs in observations:
            track_id = int(obs["track_id"])
            present = set(obs["present"])
            seen.add(track_id)
            person_frames += 1
            if set(self.required) <= present:
                compliant_frames += 1
            mem = self.tracks.setdefault(track_id, _Track())
            mem.absent = 0
            for label in self.required:
                if label in present:
                    mem.missing[label] = 0
                    mem.since.pop(label, None)
                    event_id = mem.open_ids.pop(label, None)
                    if event_id is not None:
                        store.close_event(event_id, now)
                    continue
                mem.missing[label] = mem.missing.get(label, 0) + 1
                mem.since.setdefault(label, now)
                if mem.missing[label] < self.confirm_frames or label in mem.open_ids:
                    continue
                event_id = store.open_event(
                    timestamp=now,
                    track_id=track_id,
                    violation_type=f"missing_{label}",
                    confidence=float(obs["confidence"]),
                    start_time=mem.since[label],
                    camera_id=camera_id,
                )
                mem.open_ids[label] = event_id
                opened.append(
                    {
                        "id": event_id,
                        "track_id": track_id,
                        "violation_type": f"missing_{label}",
                        "confidence": float(obs["confidence"]),
                        "start_time": mem.since[label],
                        "xyxy": obs.get("xyxy"),
                    }
                )
        for track_id, mem in list(self.tracks.items()):
            if track_id in seen:
                continue
            mem.absent += 1
            if mem.absent < self.lost_after:
                continue
            for event_id in mem.open_ids.values():
                store.close_event(event_id, now)
            del self.tracks[track_id]
        store.add_ticks(camera_id, now[:16], person_frames, compliant_frames)
        return opened


class Store:
    def __init__(self, db_path: str | Path, snap_dir: str | Path):
        self.snap_dir = Path(snap_dir)
        self.snap_dir.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._db = sqlite3.connect(str(db_path), check_same_thread=False)
        self._db.row_factory = sqlite3.Row
        self._db.execute(
            """
            create table if not exists events (
                id integer primary key,
                timestamp text not null,
                track_id integer not null,
                violation_type text not null,
                confidence real not null,
                start_time text not null,
                end_time text,
                snapshot_path text,
                camera_id text not null
            )
            """
        )
        self._db.execute(
            """
            create table if not exists ticks (
                camera_id text not null,
                minute text not null,
                person_frames integer not null,
                compliant_frames integer not null,
                primary key (camera_id, minute)
            )
            """
        )
        self._db.commit()

    def open_event(self, **row) -> int:
        with self._lock:
            cur = self._db.execute(
                """
                insert into events (
                    timestamp, track_id, violation_type, confidence,
                    start_time, end_time, snapshot_path, camera_id
                ) values (?, ?, ?, ?, ?, null, '', ?)
                """,
                (
                    row["timestamp"],
                    row["track_id"],
                    row["violation_type"],
                    row["confidence"],
                    row["start_time"],
                    row["camera_id"],
                ),
            )
            self._db.commit()
            return int(cur.lastrowid)

    def close_event(self, event_id: int, end_time: str) -> None:
        with self._lock:
            self._db.execute(
                "update events set end_time = ? where id = ? and end_time is null",
                (end_time, event_id),
            )
            self._db.commit()

    def set_snapshot(self, event_id: int, path: str) -> None:
        with self._lock:
            self._db.execute(
                "update events set snapshot_path = ? where id = ?",
                (path, event_id),
            )
            self._db.commit()

    def add_ticks(self, camera_id: str, minute: str, person_frames: int, compliant_frames: int) -> None:
        if person_frames == 0:
            return
        with self._lock:
            self._db.execute(
                """
                insert into ticks (camera_id, minute, person_frames, compliant_frames)
                values (?, ?, ?, ?)
                on conflict (camera_id, minute) do update set
                    person_frames = person_frames + excluded.person_frames,
                    compliant_frames = compliant_frames + excluded.compliant_frames
                """,
                (camera_id, minute, person_frames, compliant_frames),
            )
            self._db.commit()

    def list_events(self, violation_type: str | None, camera_id: str | None, start: str | None, end: str | None) -> list[dict]:
        sql = "select * from events where 1=1"
        args: list = []
        if violation_type:
            sql += " and violation_type = ?"
            args.append(violation_type)
        if camera_id:
            sql += " and camera_id = ?"
            args.append(camera_id)
        if start:
            sql += " and start_time >= ?"
            args.append(start)
        if end:
            sql += " and start_time <= ?"
            args.append(end)
        sql += " order by id desc"
        with self._lock:
            rows = self._db.execute(sql, args).fetchall()
        return [dict(row) for row in rows]

    def get_event(self, event_id: int) -> dict | None:
        with self._lock:
            row = self._db.execute("select * from events where id = ?", (event_id,)).fetchone()
        return dict(row) if row else None

    def stats(self, camera_id: str | None = None) -> dict:
        events = self.list_events(None, camera_id, None, None)
        by_type: dict[str, int] = {}
        by_hour: dict[str, int] = {}
        by_day: dict[str, int] = {}
        by_track: dict[tuple[str, int], int] = {}
        for event in events:
            by_type[event["violation_type"]] = by_type.get(event["violation_type"], 0) + 1
            hour = event["start_time"][:13]
            day = event["start_time"][:10]
            by_hour[hour] = by_hour.get(hour, 0) + 1
            by_day[day] = by_day.get(day, 0) + 1
            key = (event["camera_id"], int(event["track_id"]))
            by_track[key] = by_track.get(key, 0) + 1
        with self._lock:
            if camera_id:
                tick = self._db.execute(
                    "select coalesce(sum(person_frames),0), coalesce(sum(compliant_frames),0) from ticks where camera_id = ?",
                    (camera_id,),
                ).fetchone()
            else:
                tick = self._db.execute(
                    "select coalesce(sum(person_frames),0), coalesce(sum(compliant_frames),0) from ticks"
                ).fetchone()
        person_frames = int(tick[0])
        compliant_frames = int(tick[1])
        rate = None if person_frames == 0 else compliant_frames / person_frames
        tracks = [
            {"camera_id": camera, "track_id": track_id, "events": count}
            for (camera, track_id), count in sorted(by_track.items(), key=lambda item: item[1], reverse=True)
        ]
        return {
            "events": len(events),
            "by_type": by_type,
            "by_hour": by_hour,
            "by_day": by_day,
            "tracks": tracks,
            "person_frames": person_frames,
            "compliant_frames": compliant_frames,
            "compliance_rate": rate,
        }


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def snapshot_file(store: Store, event_id: int, frame, xyxy) -> None:
    if frame is None or xyxy is None:
        return
    import cv2

    height, width = frame.shape[:2]
    x1, y1, x2, y2 = [int(v) for v in xyxy]
    x1 = max(0, min(width - 1, x1))
    x2 = max(0, min(width, x2))
    y1 = max(0, min(height - 1, y1))
    y2 = max(0, min(height, y2))
    crop = frame if x2 <= x1 or y2 <= y1 else frame[y1:y2, x1:x2]
    path = store.snap_dir / f"{event_id}.jpg"
    if cv2.imwrite(str(path), crop):
        store.set_snapshot(event_id, str(path))


def report_text(stats: dict) -> str:
    lines = [
        "PPE violation report",
        f"events: {stats['events']}",
        f"person_frames: {stats['person_frames']}",
        f"compliant_frames: {stats['compliant_frames']}",
    ]
    if stats["compliance_rate"] is None:
        lines.append("compliance_rate: unavailable (no person frames recorded)")
    else:
        lines.append(f"compliance_rate: {stats['compliance_rate']}")
    lines.append("by_type:")
    if not stats["by_type"]:
        lines.append("  none")
    for name, count in sorted(stats["by_type"].items()):
        lines.append(f"  {name}: {count}")
    lines.append("by_day:")
    if not stats["by_day"]:
        lines.append("  none")
    for day, count in sorted(stats["by_day"].items()):
        lines.append(f"  {day}: {count}")
    lines.append("repeat_tracks:")
    if not stats["tracks"]:
        lines.append("  none")
    for track in stats["tracks"][:10]:
        lines.append(
            f"  camera {track['camera_id']} track {track['track_id']}: {track['events']}"
        )
    lines.append("Track ids reset when a capture session restarts. They are not a person's name.")
    return "\n".join(lines) + "\n"
