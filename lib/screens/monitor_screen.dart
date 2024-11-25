// lib/screens/monitor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({Key? key}) : super(key: key); // 添加 key 参数

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时监控'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('当前温度: ${tempProvider.currentTemperature}°C',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Text('运行时间: ${tempProvider.runtime} 分钟',
                style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
