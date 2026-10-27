.PHONY: test-server serve eval eval-app

PY=server/.venv/bin/python

test-server:
	$(PY) -m unittest server.test_events server.test_api

serve:
	$(PY) -m uvicorn server.main:app --host 0.0.0.0 --port 8000

eval:
	$(PY) ml/eval.py

eval-app:
	$(PY) -m ml.app_eval prepare
	cd app && PPE_EVAL_DIR=$(CURDIR)/ml/eval_out/app_eval flutter test test/app_eval_test.dart
	$(PY) -m ml.app_eval score
