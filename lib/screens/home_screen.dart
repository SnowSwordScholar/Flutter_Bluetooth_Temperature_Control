// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../providers/device_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TemperatureProvider temperatureProvider;
  late DeviceProvider deviceProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    temperatureProvider = Provider.of<TemperatureProvider>(context);
    deviceProvider = Provider.of<DeviceProvider>(context);

    // 监听温度提供者的变化，以便在运行状态变化时更新 UI
    temperatureProvider.addListener(_handleTemperatureChange);
  }

  @override
  void dispose() {
    temperatureProvider.removeListener(_handleTemperatureChange);
    super.dispose();
  }

  void _handleTemperatureChange() {
    // 如果需要在运行状态变化时进行特定操作，可以在这里添加逻辑
    // 例如，自动导航到监控页面等
  }

  void _startRun(BuildContext context) {
    if (temperatureProvider.temperaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置温控点')),
      );
      return;
    }
    temperatureProvider.startAutoRun();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始运行')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temperatureProvider = Provider.of<TemperatureProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('温控管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // 正确的路由
            },
          ),
        ],
      ),
      body: deviceProvider.selectedDevice != null && temperatureProvider.isConnected
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 实时监控信息
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                temperatureProvider.isRunning
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: temperatureProvider.isRunning
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                temperatureProvider.isRunning
                                    ? '设备正在运行'
                                    : '设备未运行',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: temperatureProvider.isRunning
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 设置温控点按钮
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings'); // 正确的路由
                    },
                    child: const Text('设置温控点'),
                  ),
                  const SizedBox(height: 20),
                  // 开始运行按钮
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
                  // 即将进行的操作列表
                  Expanded(
                    child: temperatureProvider.upcomingOperations.isEmpty
                        ? const Center(child: Text('暂无即将进行的操作'))
                        : ListView.builder(
                            itemCount: temperatureProvider.upcomingOperations.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const Icon(Icons.arrow_forward),
                                title: Text(temperatureProvider.upcomingOperations[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            )
          : const Center(child: Text('未连接设备')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bluetooth),
        onPressed: () {
          Navigator.pushNamed(context, '/device_management');
        },
      ),
    );
  }
}