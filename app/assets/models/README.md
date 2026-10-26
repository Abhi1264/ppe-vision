# Model assets

`ppe_model.tflite` is the float32 export of `ml/best.pt`
(YOLO11s, 640×640). Class order: `hardhat`, `vest`, `person`.

The `.tflite` file is gitignored. Keep it in this folder locally or the model will not load.

The live app loads this file on the phone and on desktop. It does not call the Python server.
