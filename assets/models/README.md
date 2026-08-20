# Model assets

Place the exported TFLite model here.

Expected future file:

```text
assets/models/ppe_model.tflite
```

Do not commit model files until the model has been finalized.

The rest of the application consumes detections only as `List<Detection>`.
Model loading, tensor layout, and YOLO decoding belong exclusively in
`lib/services/detection/model_detection_provider.dart`.
