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

  void _handleTemperatureChange() {}

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

void _showInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          '使用指南：',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView( // 添加可滚动的视图
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  <Widget>[
              Text(
                '授予权限 -> 打开右下角蓝牙图标选择设备 -> 设置温度点并保存 -> 开始运行\n',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
              Text(
                '指示灯提示：',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              Text(
                '\n等待连接: 两灯交替闪烁\n'
                '连接成功：两灯常量\n'
                '接收成功: D5 快速闪烁\n'
                '执行中：两灯交替呼吸\n'
                '执行中但失去蓝牙连接: D5呼吸\n'
                '执行结束: D4快速闪烁\n',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
              Text(
                '用户按键定义：',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              Text(
                '\n长按三秒 BOOT 键，按照上次设置启动\n'
                '长按十秒 BOOT 键，清除设置的数据\n',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
              Text(
                '关于本项目：',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              Text(
                '\nGitHub: https://github.com/SnowSwordScholar/Flutter_Bluetooth_Temperature_Control\n\n'
                'SnowSwordScholar 用  ❤️ 创作\n\n\n\n\n\n\n\n\n'
                '老师，请多给我打点平时分呗 ヾ(≧▽≦*)o',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭', style: TextStyle(fontSize: 16)), // 假设关闭按钮字体大小也为16
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final temperatureProvider = Provider.of<TemperatureProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showInfoDialog(context),
          child: const Text('温控管理'),
        ),
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
                          Text(
                            temperatureProvider.isRunning
                                ? ''
                                : '\n\n\n请稍等片刻，\n如果运行时间不为 0 ，\n设备仍可能在运行',
                            style: const TextStyle(
                              fontSize: 11,
                              color:  Colors.red
                            ),
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