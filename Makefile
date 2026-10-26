.PHONY: test-server serve eval

PY=server/.venv/bin/python

test-server:
	$(PY) -m unittest server.test_events server.test_api

serve:
	$(PY) -m uvicorn server.main:app --host 127.0.0.1 --port 8000

eval:
	$(PY) ml/eval.py
