import 'package:flutter/material.dart';
import 'package:flkey/common/context.dart';
import 'package:flkey/common/color.dart';

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

  BorderSide getBorderSide(BuildContext context, Set<WidgetState> states) {
    final colorScheme = context.colorScheme;
    final hoverColor = colorScheme.primary.withOpacity60();
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed)) {
      return BorderSide(color: hoverColor);
    }
    return BorderSide(color: colorScheme.surfaceContainerHighest);
  }

  Color? getBackgroundColor(BuildContext context, Set<WidgetState> states) {
    final colorScheme = context.colorScheme;
    return colorScheme.surfaceContainerLow;
  }

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
        iconColor: WidgetStatePropertyAll(context.colorScheme.primary),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => getBackgroundColor(context, states),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => getBorderSide(context, states),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
