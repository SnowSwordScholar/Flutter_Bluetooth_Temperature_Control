// lib/providers/temperature_provider.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_manager.dart';
import '../models/temperature_point.dart';
import 'device_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/device.dart';
import 'package:logger/logger.dart';

class TemperatureProvider with ChangeNotifier {
  final Logger _logger = Logger();
  final List<TemperaturePoint> _temperaturePoints = [];
  final List<String> _upcomingOperations = [];
  int runtime = 0;
  int currentTemperature = 0;
  final BluetoothManager _bluetoothManager = BluetoothManager();
  bool _isRunning = false;
  bool _isConnected = false;
  Timer? _autoRunTimer;
  Timer? _startupDelayTimer;
  int _startupDelay = 10; // 预留的时间，秒
  int _remainingTime = 0;

  bool get isRunning => _isRunning;
  bool get isConnected => _isConnected;
  List<TemperaturePoint> get temperaturePoints => List.unmodifiable(_temperaturePoints);
  List<String> get upcomingOperations => List.unmodifiable(_upcomingOperations);
  int get remainingTime => _remainingTime;

  TemperatureProvider() {
    // 设置接收数据的回调
    _bluetoothManager.onDataReceived = _handleBluetoothData;
  }

  // 当选择了设备后连接
  void connectToSelectedDevice(DeviceProvider deviceProvider) {
    if (deviceProvider.selectedDevice != null) {
      _bluetoothManager.connectToDevice(deviceProvider.selectedDevice!.id).then((_) {
        // 连接后开始启动延迟计时
        startStartupDelay();
        // 连接后请求温度数据
        retrieveTemperatureData();
      });
    }
  }

  // 请求设备发送已有的温度数据
  Future<void> retrieveTemperatureData() async {
    try {
      Map<String, dynamic> request = {
        "command": "get_temperature_points",
      };
      await _bluetoothManager.sendData(request);
      // 假设设备会响应 "temperature_points" 命令
    } catch (e) {
      _logger.e("请求温度数据时出错: $e");
    }
  }

  // 处理从设备接收到的数据
  void _handleBluetoothData(Map<String, dynamic> data) {
    if (data['command'] == 'current_status') {
      runtime = data['data']['runtime'];
      currentTemperature = data['data']['current_temperature'];
      notifyListeners();
    } else if (data['command'] == 'temperature_verification') {
      bool verification = data['data']['verification'];
      if (verification) {
        // 验证通过，开始运行
        _isRunning = true;
        _isConnected = true;
        notifyListeners();
        startAutoRun();
      } else {
        // 验证失败，处理相应逻辑
        _isRunning = false;
        _isConnected = false;
        notifyListeners();
        _logger.e("温度验证失败");
      }
    } else if (data['command'] == 'temperature_points') {
      // 接收到设备的温度数据
      List<dynamic> points = data['data'];
      _temperaturePoints.clear();
      for (var point in points) {
        _temperaturePoints.add(TemperaturePoint.fromJson(point));
      }
      notifyListeners();
    } else if (data['command'] == 'upcoming_operations') {
      // 接收到即将进行的操作
      List<dynamic> operations = data['data'];
      _upcomingOperations.clear();
      for (var op in operations) {
        _upcomingOperations.add(op.toString());
      }
      notifyListeners();
    }
    // 处理其他命令
  }

  // 发送温控点数据并等待验证
  Future<void> sendTemperaturePointsWithVerification() async {
    try {
      Map<String, dynamic> data = {
        "command": "set_temperature_points",
        "data": _temperaturePoints.map((e) => e.toJson()).toList(),
      };
      await _bluetoothManager.sendData(data);
      // 假设设备会响应 "temperature_verification" 命令
    } catch (e) {
      _logger.e("发送温控点数据时出错: $e");
    }
  }

  // 启动自动运行计时器
  void startAutoRun() {
    if (_temperaturePoints.isEmpty) return;

    // 计算各时间点的延迟（秒）
    _upcomingOperations.clear();
    List<TemperaturePoint> sortedPoints = List.from(_temperaturePoints)
      ..sort((a, b) => a.time.compareTo(b.time));

    DateTime startTime = DateTime.now().add(Duration(seconds: _startupDelay));

    for (var point in sortedPoints) {
      DateTime pointTime = startTime.add(Duration(minutes: point.time));
      Duration delay = pointTime.difference(DateTime.now());
      if (delay.isNegative) delay = Duration.zero;
      _upcomingOperations.add(
          '在 ${point.time} 分钟后设置温度为 ${point.temperature}°C');

      Timer(delay, () {
        // 发送温度设置命令
        Map<String, dynamic> setTemp = {
          "command": "set_temperature",
          "data": {
            "temperature": point.temperature,
          },
        };
        _bluetoothManager.sendData(setTemp);
      });
    }

    notifyListeners();
  }

  // 启动延迟计时
  void startStartupDelay() {
    _remainingTime = _startupDelay;
    notifyListeners();

    _startupDelayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        timer.cancel();
        sendTemperaturePointsWithVerification();
      }
    });
  }

  // 中断当前运行
  void interruptRun() {
    if (_isRunning) {
      _autoRunTimer?.cancel();
      _startupDelayTimer?.cancel();
      _isRunning = false;
      _isConnected = false;
      notifyListeners();
      // 发送中断命令到设备
      Map<String, dynamic> interruptCommand = {
        "command": "interrupt",
      };
      _bluetoothManager.sendData(interruptCommand);
    }
  }

  // 编辑温控点
  void editTemperaturePoint(int index, TemperaturePoint newPoint) {
    if (index >= 0 && index < _temperaturePoints.length) {
      _temperaturePoints[index] = newPoint;
      notifyListeners();
    }
  }

  // 添加温控点
  void addTemperaturePoint(TemperaturePoint point) {
    _temperaturePoints.add(point);
    notifyListeners();
  }

  // 删除温控点
  void removeTemperaturePoint(int index) {
    if (index >= 0 && index < _temperaturePoints.length) {
      _temperaturePoints.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bluetoothManager.disconnect();
    _autoRunTimer?.cancel();
    _startupDelayTimer?.cancel();
    super.dispose();
  }
}
