import 'package:flutter/material.dart';

import '../../domain/media_focal_point.dart';

extension MediaFocalPointAlignment on MediaFocalPoint {
  Alignment get alignment => Alignment(x * 2 - 1, y * 2 - 1);
}
