import 'package:flutter/material.dart';

extension ColorExtension on Color {
  Color withOpacity80() {
    return withAlpha(204);
  }

  Color withOpacity60() {
    return withAlpha(153);
  }
}
