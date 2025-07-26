import 'package:fauth/common/constant.dart';
import 'package:fauth/common/system.dart';
import 'package:flutter/material.dart';

// class WindowTitleBar extends StatefulWidget implements PreferredSizeWidget {
//   final String title;
//   const WindowTitleBar({super.key, required this.title});

//   @override
//   State<WindowTitleBar> createState() => _WindowTitleBarState();

//   @override
//   Size get preferredSize => const Size.fromHeight(32);
// }

// class _WindowTitleBarState extends State<WindowTitleBar> {
//   bool _isMaximized = false;

//   _updateMaximizedState() async {
//     if (await windowManager.isMaximized()) {
//       windowManager.unmaximize();
//       setState(() {
//         _isMaximized = false;
//       });
//     } else {
//       windowManager.maximize();
//       setState(() {
//         _isMaximized = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!isDesktop()) {
//       return const SizedBox.shrink();
//     }
//     // windowManager.setHasShadow(true);
//     return Material(
//       // height: widget.preferredSize.height,
//       // color: Theme.of(context).colorScheme.surface,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Positioned(
//             child: GestureDetector(
//               behavior: HitTestBehavior.translucent,
//               onPanStart: (_) => windowManager.startDragging(),
//               onDoubleTap: () => _updateMaximizedState(),
//               child: Container(
//                 color: Theme.of(
//                   context,
//                 ).colorScheme.secondary.withValues(alpha: 0.15),
//                 alignment: Alignment.centerLeft,
//                 height: titleBarHeight,
//               ),
//             ),
//           ),
//           if (Platform.isMacOS)
//             const Text(appName)
//           else ...[
//             Positioned(left: 0, child: AppIcon()),
//             Positioned(
//               right: 0,
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.remove, size: 16),
//                     onPressed: () => windowManager.minimize(),
//                     splashRadius: 16,
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       _isMaximized ? Icons.filter_none : Icons.crop_square,
//                       size: 16,
//                     ),
//                     onPressed: () => _updateMaximizedState(),
//                     splashRadius: 16,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, size: 16),
//                     onPressed: () => windowManager.close(),
//                     splashRadius: 16,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

class WindowTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const WindowTitleBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(context) {
    return isDesktop()
        ? const SizedBox.shrink()
        : AppBar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.15),
            title: AppIcon(),
          );
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircleAvatar(
              foregroundImage: AssetImage("assets/images/icon.png"),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(width: 8),
          Text(appName),
        ],
      ),
    );
  }
}
