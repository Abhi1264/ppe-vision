# Model assets

`ppe_model.tflite` is the float32 export of `helemt-vest-detection/best.pt`
(YOLO11s, 640×640). Class order: `hardhat`, `vest`, `person`.

The `.tflite` file is gitignored. Keep it in this folder locally or the model will not load.

The app maps `hardhat` to helmet. Loading and YOLO decoding stay in
`lib/services/detection/model_detection_io.dart`.
