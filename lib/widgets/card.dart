import 'package:flutter/material.dart';

class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    this.onPressed,
    this.selectWidget,
    this.padding,
    required this.child,
    this.radius = 12,
  });

  final void Function()? onPressed;
  final Widget? selectWidget;
  final EdgeInsets? padding;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      clipBehavior: Clip.antiAlias,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        iconSize: WidgetStateProperty.all(20),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
