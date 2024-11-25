// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/temperature_provider.dart';
import 'providers/device_provider.dart'; // 导入
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/device_management_screen.dart'; // 导入
import 'utils/permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()), // 添加 DeviceProvider
        ChangeNotifierProxyProvider<DeviceProvider, TemperatureProvider>(
          create: (_) => TemperatureProvider(),
          update: (_, deviceProvider, temperatureProvider) =>
              temperatureProvider!..connectToSelectedDevice(deviceProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key}); // 使用 super 参数

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool granted = await Permissions.requestAllPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
    if (!granted) {
      // 提示用户权限被拒绝，并引导用户到设置中开启权限
      _showPermissionsDeniedDialog();
    }
  }

  void _showPermissionsDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('权限被拒绝'),
          content: const Text('应用需要蓝牙和位置权限才能正常工作。请在设置中开启这些权限。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 打开应用设置
                openAppSettings(); // 确保已导入
              },
              child: const Text('前往设置'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 可以选择退出应用或其他处理
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '温控管理APP',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: _permissionsGranted
          ? const HomeScreen()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/monitor': (context) => const MonitorScreen(),
        '/device_management': (context) => const DeviceManagementScreen(), // 添加路由
      },
    );
  }
}
