// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_temperature_control/providers/temperature_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startRun(BuildContext context) {
    final temperatureProvider = Provider.of<TemperatureProvider>(context, listen: false);
    temperatureProvider.startAutoRun();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始运行')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temperatureProvider = Provider.of<TemperatureProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('温控管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // 修正路由
            },
          ),
        ],
      ),
      body: temperatureProvider.isConnected
          ? Center( // 使用 Center 包裹 Column
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
                  crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
                  mainAxisSize: MainAxisSize.min, // 根据内容大小调整
                  children: [
                    Text(
                      '当前温度: ${temperatureProvider.currentTemperature}°C',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '运行时间: ${temperatureProvider.runtime} 分钟',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings'); // 修正路由
                      },
                      child: const Text('设置温控点'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (temperatureProvider.isConnected &&
                              temperatureProvider.temperaturePoints.isNotEmpty &&
                              temperatureProvider.verificationPassed &&
                              temperatureProvider.temperaturePointsLoaded)
                          ? () => _startRun(context)
                          : null,
                      child: const Text('开始运行'),
                    ),
                    const SizedBox(height: 20),
                    if (temperatureProvider.upcomingOperations.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: temperatureProvider.upcomingOperations.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(temperatureProvider.upcomingOperations[index]),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            )
          : const Center(child: Text('未连接到任何设备')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bluetooth),
        onPressed: () {
          Navigator.pushNamed(context, '/device_management');
        },
      ),
    );
  }
}