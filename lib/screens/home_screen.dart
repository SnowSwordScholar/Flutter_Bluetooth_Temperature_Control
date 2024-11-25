// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../utils/permissions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key); // 添加 key 参数

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('温控管理'),
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
    );
  }
}
