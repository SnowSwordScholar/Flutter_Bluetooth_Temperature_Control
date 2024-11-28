// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../providers/device_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: isConnected
                        ? () async {
                            Navigator.pushNamed(context, '/settings');
                          }
                        : null, // 未连接时禁用按钮
                    child: const Text('设置温控点'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isConnected
                        ? () {
                            Navigator.pushNamed(context, '/monitor');
                          }
                        : null, // 未连接时禁用按钮
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