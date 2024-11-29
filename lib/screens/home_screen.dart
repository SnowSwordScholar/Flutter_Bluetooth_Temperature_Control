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

  void _interruptRun(BuildContext context) async {
    try {
      await temperatureProvider.interruptRun();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已发送中断命令')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送中断命令失败: $e')),
      );
    }
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
            icon: const Icon(Icons.power_settings_new),
            tooltip: '发送中断命令',
            onPressed: temperatureProvider.isRunning
                ? () => _interruptRun(context)
                : null,
          ),
        ],
      ),
      body: deviceProvider.selectedDevice != null && temperatureProvider.isConnected
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 占据屏幕1/3的空白区域
                      SizedBox(height: constraints.maxHeight * 0.1),
                      
                      // 实时监控信息直接显示在页面上
                      Column(
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
                      
                      const Spacer(), // 将按钮推到屏幕下部

                      // 按钮排列在底部
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                            child: const Text('设置温控点'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50), // 按钮宽度填满
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: (temperatureProvider.isConnected &&
                                    temperatureProvider.temperaturePoints.isNotEmpty &&
                                    temperatureProvider.verificationPassed &&
                                    temperatureProvider.temperaturePointsLoaded)
                                ? () => _startRun(context)
                                : null,
                            child: const Text('开始运行'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // 与底部留出一些空间
                    ],
                  ),
                );
              },
            )
          : const Center(child: Text('未连接设备')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bluetooth),
        onPressed: () {
          Navigator.pushNamed(context, '/device_management');
        },
        tooltip: '设备管理',
      ),
    );
  }
}