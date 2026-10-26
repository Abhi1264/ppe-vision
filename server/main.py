from __future__ import annotations

from contextlib import asynccontextmanager
import threading
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse, Response

from server.events import (
    Debouncer,
    Store,
    parse_required,
    report_text,
    snapshot_file,
    utc_now,
)

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "server" / "data"


class Session:
    def __init__(self, camera_id: str, required: tuple[str, ...], confirm_frames: int, store: Store):
        self.camera_id = camera_id
        self.required = required
        self.confirm_frames = confirm_frames
        self.debouncer = Debouncer(required, confirm_frames)
        self.lock = threading.Lock()
        self.jpeg = b""
        self.width = 0
        self.height = 0
        self.tracks: list[dict] = []
        self.opened: list[dict] = []


class Hub:
    def __init__(self, store: Store):
        self.store = store
        self.sessions: dict[str, Session] = {}
        self.lock = threading.Lock()
        self.stop = threading.Event()
        self.thread: threading.Thread | None = None
        self.error: str | None = None
        self.camera_id: str | None = None

    def session_for(self, camera_id: str, required: tuple[str, ...], confirm_frames: int) -> Session:
        with self.lock:
            current = self.sessions.get(camera_id)
            if (
                current is None
                or current.required != required
                or current.confirm_frames != confirm_frames
            ):
                current = Session(camera_id, required, confirm_frames, self.store)
                self.sessions[camera_id] = current
            return current

    def step(self, camera_id: str, required, confirm_frames: int, tracks: list[dict], frame) -> dict:
        session = self.session_for(camera_id, required, confirm_frames)
        now = utc_now()
        with session.lock:
            for track in tracks:
                track["missing"] = [label for label in required if label not in track["present"]]
            opened = session.debouncer.step(tracks, now, self.store, camera_id)
            for event in opened:
                snapshot_file(self.store, event["id"], frame, event.get("xyxy"))
            if frame is not None:
                import cv2

                session.height, session.width = frame.shape[:2]
                ok, buf = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 70])
                session.jpeg = buf.tobytes() if ok else b""
            session.tracks = [_public_track(track) for track in tracks]
            session.opened = [
                {"id": event["id"], "track_id": event["track_id"], "violation_type": event["violation_type"]}
                for event in opened
            ]
            return live_payload(session, include_image=False)


def _public_track(track: dict) -> dict:
    boxes = track.get("boxes") or {}
    return {
        "track_id": track["track_id"],
        "confidence": track["confidence"],
        "person": track["person"],
        "hardhat": boxes.get("hardhat"),
        "vest": boxes.get("vest"),
        "missing": track.get("missing") or [],
    }


def live_payload(session: Session, include_image: bool) -> dict:
    import base64

    body = {
        "camera_id": session.camera_id,
        "width": session.width,
        "height": session.height,
        "tracks": session.tracks,
        "opened": session.opened,
    }
    if include_image and session.jpeg:
        body["jpeg_base64"] = base64.b64encode(session.jpeg).decode("ascii")
    return body


def create_app(detect=None, db_path: Path | None = None, snap_dir: Path | None = None) -> FastAPI:
    data = DATA
    store = Store(db_path or (data / "events.db"), snap_dir or (data / "snapshots"))
    hub = Hub(store)

    @asynccontextmanager
    async def lifespan(_app):
        if detect is not None:
            yield
            return
        try:
            from server.detect import load_models

            _app.state.models = load_models()
        except Exception as error:  # noqa: BLE001 - shown on /health
            _app.state.model_error = str(error)
        yield

    app = FastAPI(lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.state.hub = hub
    app.state.detect = detect
    app.state.models = None
    app.state.model_error = None

    def _check_required(raw: str) -> tuple[str, ...]:
        try:
            return parse_required(raw)
        except ValueError as error:
            raise HTTPException(400, str(error)) from error

    def _check_confirm(value: int) -> int:
        if value < 1 or value > 120:
            raise HTTPException(400, "confirm_frames must be from 1 to 120")
        return value

    @app.get("/health")
    def health():
        ready = app.state.detect is not None or app.state.models is not None
        return {"ok": ready, "error": None if ready else app.state.model_error}

    @app.post("/frames")
    async def frames(
        file: UploadFile = File(...),
        camera_id: str = Form("app"),
        required: str = Form("hardhat,vest"),
        confirm_frames: int = Form(8),
        conf: float = Form(0.25),
        encoding: str = Form("jpeg"),
        width: int = Form(0),
        height: int = Form(0),
    ):
        if hub.thread is not None and hub.thread.is_alive():
            raise HTTPException(409, "Stop the capture job before posting frames")
        names = _check_required(required)
        confirm = _check_confirm(confirm_frames)
        if not 0.01 <= conf <= 0.99:
            raise HTTPException(400, "conf must be from 0.01 to 0.99")
        raw = await file.read()
        if not raw:
            raise HTTPException(400, "Empty image")
        try:
            tracks, frame = _frame_from_upload(app, raw, conf, encoding, width, height)
        except ValueError as error:
            raise HTTPException(400, str(error)) from error
        hub.step(camera_id, names, confirm, tracks, frame)
        session = hub.session_for(camera_id, names, confirm)
        with session.lock:
            return live_payload(session, include_image=True)

    @app.post("/jobs")
    def start_job(body: dict):
        if hub.thread is not None and hub.thread.is_alive():
            raise HTTPException(409, "A capture job is already running")
        source = str(body.get("source", "0"))
        camera_id = str(body.get("camera_id") or source)
        names = _check_required(str(body.get("required", "hardhat,vest")))
        confirm = _check_confirm(int(body.get("confirm_frames", 8)))
        conf = float(body.get("conf", 0.25))
        if app.state.detect is None and app.state.models is None:
            raise HTTPException(503, app.state.model_error or "Model is not loaded")
        hub.error = None
        hub.camera_id = camera_id
        hub.stop = threading.Event()
        hub.session_for(camera_id, names, confirm)

        def loop():
            import cv2

            cap = cv2.VideoCapture(int(source) if source.isdigit() else source)
            if not cap.isOpened():
                hub.error = f"Could not open {source}"
                return
            try:
                while not hub.stop.is_set():
                    ok, frame = cap.read()
                    if not ok:
                        hub.error = "Could not read a frame"
                        break
                    if app.state.detect is not None:
                        tracks, _frame = app.state.detect(_jpeg(frame), conf)
                        frame = _frame if _frame is not None else frame
                    else:
                        from server.detect import infer

                        tracks = infer(app.state.models[0], app.state.models[1], frame, conf)
                    hub.step(camera_id, names, confirm, tracks, frame)
            finally:
                cap.release()

        hub.thread = threading.Thread(target=loop, daemon=True)
        hub.thread.start()
        return {"camera_id": camera_id, "source": source}

    @app.post("/jobs/stop")
    def stop_job():
        hub.stop.set()
        thread = hub.thread
        if thread is not None:
            thread.join(timeout=2)
        hub.thread = None
        return {"stopped": True, "error": hub.error}

    @app.get("/jobs")
    def job_status():
        running = hub.thread is not None and hub.thread.is_alive()
        return {"running": running, "camera_id": hub.camera_id, "error": hub.error}

    @app.get("/live")
    def live(camera_id: str = "0", image: int = 1):
        session = hub.sessions.get(camera_id)
        if session is None:
            return {
                "camera_id": camera_id,
                "width": 0,
                "height": 0,
                "tracks": [],
                "opened": [],
            }
        with session.lock:
            return live_payload(session, include_image=bool(image))

    @app.get("/events")
    def events(
        violation_type: str | None = None,
        camera_id: str | None = None,
        start: str | None = None,
        end: str | None = None,
    ):
        return store.list_events(violation_type, camera_id, start, end)

    @app.get("/events.csv")
    def events_csv(
        violation_type: str | None = None,
        camera_id: str | None = None,
        start: str | None = None,
        end: str | None = None,
    ):
        rows = store.list_events(violation_type, camera_id, start, end)
        lines = ["id,timestamp,track_id,violation_type,confidence,start_time,end_time,snapshot_path,camera_id"]
        for row in rows:
            lines.append(
                ",".join(
                    [
                        str(row["id"]),
                        row["timestamp"],
                        str(row["track_id"]),
                        row["violation_type"],
                        str(row["confidence"]),
                        row["start_time"],
                        row["end_time"] or "",
                        (row["snapshot_path"] or "").replace(",", " "),
                        row["camera_id"],
                    ]
                )
            )
        return Response("\n".join(lines) + "\n", media_type="text/csv")

    @app.get("/events/{event_id}")
    def one_event(event_id: int):
        row = store.get_event(event_id)
        if row is None:
            raise HTTPException(404, "No such event")
        return row

    @app.get("/events/{event_id}/snapshot")
    def snapshot(event_id: int):
        row = store.get_event(event_id)
        if row is None:
            raise HTTPException(404, "No such event")
        raw_path = row.get("snapshot_path") or ""
        if not raw_path:
            raise HTTPException(404, "This event has no snapshot")
        path = Path(raw_path).resolve()
        root = store.snap_dir.resolve()
        if not path.is_relative_to(root) or not path.is_file():
            raise HTTPException(404, "Snapshot file is missing")
        return FileResponse(path, media_type="image/jpeg")

    @app.get("/stats")
    def stats(camera_id: str | None = None):
        return store.stats(camera_id)

    @app.get("/report")
    def report(camera_id: str | None = None):
        return PlainTextResponse(report_text(store.stats(camera_id)))

    return app


def _frame_from_upload(app, raw: bytes, conf: float, encoding: str, width: int, height: int):
    if app.state.detect is not None:
        return app.state.detect(raw, conf)
    if app.state.models is None:
        raise HTTPException(503, app.state.model_error or "Model is not loaded")
    if encoding == "rgb":
        if width < 1 or height < 1 or len(raw) != width * height * 3:
            raise ValueError("rgb upload size does not match width and height")
        import cv2
        import numpy as np

        from server.detect import infer

        frame = np.frombuffer(raw, dtype=np.uint8).reshape((height, width, 3)).copy()
        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
        return infer(app.state.models[0], app.state.models[1], frame, conf), frame
    from server.detect import decode_and_infer

    return decode_and_infer(app.state.models, raw, conf)


def _jpeg(frame) -> bytes:
    import cv2

    ok, buf = cv2.imencode(".jpg", frame)
    if not ok:
        return b""
    return buf.tobytes()


app = create_app()
