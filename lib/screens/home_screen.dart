// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../providers/device_provider.dart';
import '../utils/permissions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // 使用 super 参数

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    // Determine connection status
    bool isConnected = tempProvider.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('温控管理'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.devices,
              color: isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/device_management');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '当前温度: ${tempProvider.currentTemperature}°C',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              '运行时间: ${tempProvider.runtime} 分钟',
              style: const TextStyle(fontSize: 20),
            ),
            if (tempProvider.remainingTime > 0)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '自动运行将在 ${tempProvider.remainingTime} 秒后开始',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ],
              ),
            const Spacer(),
            Center( // Center the buttons
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      bool granted = await Permissions.requestAllPermissions();
                      if (granted) {
                        Navigator.pushNamed(context, '/settings');
                      } else {
                        // 提示用户权限未被授予
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('需要蓝牙和位置权限才能继续')),
                        );
                      }
                    },
                    child: const Text('设置温控点'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      bool granted = await Permissions.requestAllPermissions();
                      if (granted) {
                        Navigator.pushNamed(context, '/monitor');
                      } else {
                        // 提示用户权限未被授予
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('需要蓝牙和位置权限才能继续')),
                        );
                      }
                    },
                    child: const Text('实时监控'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
