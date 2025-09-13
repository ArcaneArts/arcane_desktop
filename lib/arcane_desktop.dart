import 'dart:io';

import 'package:arcane/arcane.dart' hide Window, MenuItem;
import 'package:bar/bar.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:serviced/serviced.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class AWM {
  static TrayManager? tray;
  static Menu? trayMenu;
  static PylonBuilder? barTitle;
  static PylonBuilder? barLeading;
}

class ArcaneTrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isMacOS) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit') {
      windowManager.destroy().then((_) => exit(0));
    }
    // Handle custom menu items via keys if needed
  }
}

class ArcaneTray {
  final String iconPath;
  final String tooltip;
  final List<MenuItem> menu;

  ArcaneTray({required this.iconPath, required this.tooltip, this.menu = const []});

  Future<void> init() async {
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip(tooltip);
    Menu menu = initMenu();
    await trayManager.setContextMenu(menu);
    trayManager.addListener(ArcaneTrayListener());
    AWM.tray = trayManager;
  }

  Menu initMenu() {
    Menu menu = Menu(items: [...this.menu, MenuItem(key: 'exit', label: 'Exit')]);
    AWM.trayMenu = menu;
    return menu;
  }
}

class ArcaneWindow extends StatelessWidget with MagicInitializer {
  final ArcaneTray? tray;
  final WindowListener? windowListener;
  final WindowOptions? windowOptions;
  final WindowEffect? windowEffect;
  final Color? windowColor;
  final PylonBuilder? barTitle;
  final PylonBuilder? barLeading;

  @override
  final Widget child;

  const ArcaneWindow({super.key, this.tray, this.windowListener, this.windowOptions = const WindowOptions(titleBarStyle: TitleBarStyle.hidden, windowButtonVisibility: false), this.windowEffect, this.windowColor, this.barTitle, this.barLeading, required this.child});

  @override
  Widget build(BuildContext context) => Pylon<InjectBarHeader?>(
    value: InjectBarHeader(
      header:
          (context) => TitleBar(
            title: AWM.barTitle?.call(context) ?? SizedBox.shrink(),
            leading: AWM.barLeading?.call(context),
            surfaceColor: Theme.of(context).colorScheme.foreground,
            color: Colors.transparent,
            theme: Platform.isMacOS ? PlatformTheme.mac : PlatformTheme.windows,
            onMaximize: () => windowManager.maximize(),
            onClose: () => AWM.tray != null ? windowManager.hide() : windowManager.destroy().then((_) => exit(0)),
            onStartDragging: () => windowManager.startDragging(),
            onUnMaximize: () => windowManager.unmaximize(),
            isMaximized: () => windowManager.isMaximized(),
            onMinimize: () => windowManager.minimize(),
          ),
    ),
    builder: (context) => child,
  );

  @override
  InitTask get $initializer => InitTask("Arcane Desktop", () async {
    WidgetsFlutterBinding.ensureInitialized();
    AWM.barTitle = barTitle;
    AWM.barLeading = barLeading;
    await windowManager.ensureInitialized();
    await tray?.init();
    await Window.initialize();

    if (windowListener != null) {
      windowManager.addListener(windowListener!);
    }

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setBackgroundColor(Colors.transparent);
      await Window.setEffect(effect: windowEffect ?? WindowEffect.menu, color: windowColor ?? const Color(0x00000000));
    });
  });
}
