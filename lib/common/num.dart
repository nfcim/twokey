import 'package:flutter/material.dart';

extension NumApExtension on num {
  double ap(BuildContext context) {
    final double scale = MediaQuery.of(context).textScaler.scale(1.0);
    return this * (1 + (scale - 1) * 0.5);
  }
}
