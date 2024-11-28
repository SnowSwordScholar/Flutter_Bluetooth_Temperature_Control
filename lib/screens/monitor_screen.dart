// lib/screens/monitor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时监控'),
        actions: [
          if (tempProvider.isRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                tempProvider.interruptRun();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已中断当前运行')),
                );
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
            const SizedBox(height: 20),
            const Text(
              '接下来的操作:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: tempProvider.upcomingOperations.isEmpty
                  ? const Center(child: Text('暂无即将进行的操作'))
                  : ListView.builder(
                      itemCount: tempProvider.upcomingOperations.length,
                      itemBuilder: (context, index) {
                        final operation = tempProvider.upcomingOperations[index];
                        return ListTile(
                          leading: const Icon(Icons.arrow_forward),
                          title: Text(operation),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}