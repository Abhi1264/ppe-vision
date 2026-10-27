import 'dart:typed_data';

import '../../core/constants/detection_constants.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import '../image/image_preprocessor.dart';
import 'yolo_decode.dart';

typedef ModelOutput = ({Float32List values, List<int> shape});
typedef RunModel = ModelOutput Function(Float32List input);

/// Hardhats and vests from the PPE model, people from the COCO model.
List<Detection> detectFrame(
  FrameData frame, {
  required RunModel ppe,
  required RunModel person,
}) {
  final image = const DefaultImagePreprocessor(
    targetWidth: DetectionConstants.modelInputSize,
    targetHeight: DetectionConstants.modelInputSize,
  ).processSync(frame);
  final input = Float32List(image.rgbBytes.length);
  for (var i = 0; i < input.length; i++) {
    input[i] = image.rgbBytes[i] / 255.0;
  }
  final upright = uprightFrameSize(frame);

  List<Detection> decode(ModelOutput output, List<String> labels) {
    return decodeYoloOutput(
      values: output.values,
      shape: output.shape,
      modelWidth: image.width,
      modelHeight: image.height,
      padX: image.padX,
      padY: image.padY,
      letterboxScale: image.letterboxScale,
      uprightWidth: upright.width,
      uprightHeight: upright.height,
      labels: labels,
    );
  }

  return [
    for (final d in decode(ppe(input), DetectionConstants.modelLabels))
      if (d.classType == DetectionClass.helmet || d.classType == DetectionClass.vest) d,
    for (final d in decode(person(input), DetectionConstants.personModelLabels))
      if (d.classType == DetectionClass.person) d,
  ];
}
