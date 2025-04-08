import 'dart:io';

import 'package:arcane/arcane.dart' hide Window;
import 'package:bar/bar.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:serviced/serviced.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class AWM {
  static SystemTray? tray;
  static Menu? trayMenu;
  static PylonBuilder? barTitle;
  static PylonBuilder? barLeading;
}

class ArcaneTray {
  final String iconPath;
  final String tooltip;
  final List<MenuItemBase> menu;

  ArcaneTray({
    required this.iconPath,
    required this.tooltip,
    this.menu = const [],
  });

  Future<SystemTray> init() async {
    SystemTray tray = SystemTray();
    await tray.initSystemTray(
      iconPath: iconPath,
      isTemplate: true,
      toolTip: tooltip,
    );
    await tray.setContextMenu(await initMenu());
    tray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
      } else if (eventName == kSystemTrayEventRightClick) {
        tray.popUpContextMenu();
      }
    });

    AWM.tray = tray;
    return tray;
  }

  Future<Menu> initMenu() async {
    Menu menu = Menu();
    await menu.buildFrom([
      ...this.menu,
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) => windowManager.destroy().then((_) => exit(0)),
      ),
    ]);

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

  const ArcaneWindow({
    super.key,
    this.tray,
    this.windowListener,
    this.windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    ),
    this.windowEffect,
    this.windowColor,
    this.barTitle,
    this.barLeading,
    required this.child,
  });

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
            onClose:
                () =>
                    AWM.tray != null
                        ? windowManager.hide()
                        : windowManager.destroy().then((_) => exit(0)),
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
      await Window.setEffect(
        effect: windowEffect ?? WindowEffect.menu,
        color: windowColor ?? const Color(0x00000000),
      );
    });
  });
}
