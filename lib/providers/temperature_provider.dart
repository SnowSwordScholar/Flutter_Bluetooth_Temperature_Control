// lib/providers/temperature_provider.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_manager.dart';
import '../models/temperature_point.dart';
import 'device_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/device.dart';

class TemperatureProvider with ChangeNotifier {
  final List<TemperaturePoint> _temperaturePoints = [];
  final List<String> _upcomingOperations = [];
  int runtime = 0;
  int currentTemperature = 0;
  int _remainingTime = 0;
  int get remainingTime => _remainingTime;

  final BluetoothManager _bluetoothManager = BluetoothManager();
  bool _isRunning = false;
  Timer? _autoRunTimer;

  bool get isRunning => _isRunning;
  List<TemperaturePoint> get temperaturePoints => List.unmodifiable(_temperaturePoints);
  List<String> get upcomingOperations => List.unmodifiable(_upcomingOperations);

  TemperatureProvider() {
    // 设置接收数据的回调
    _bluetoothManager.onDataReceived = _handleBluetoothData;
  }

  // 当选择了设备后连接
  void connectToSelectedDevice(DeviceProvider deviceProvider) {
    if (deviceProvider.selectedDevice != null) {
      _bluetoothManager.connectToDevice(deviceProvider.selectedDevice!.id).then((_) {
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
      // 处理错误
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
        notifyListeners();
        startAutoRun();
      } else {
        // 验证失败，处理相应逻辑
        _isRunning = false;
        notifyListeners();
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
      // 处理错误
    }
  }

  // 启动自动运行计时器
void startAutoRun() {
  if (_temperaturePoints.isEmpty) return;

  // 计算总持续时间（秒）
  int totalDuration = _temperaturePoints.fold(0, (sum, point) => sum + point.duration);
  _remainingTime = totalDuration;
  notifyListeners();

  _autoRunTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_remainingTime > 0) {
      _remainingTime--;
      notifyListeners();
    } else {
      _isRunning = false;
      timer.cancel();
      notifyListeners();
    }
  });
}

  // 中断当前运行
  void interruptRun() {
    if (_isRunning) {
      _autoRunTimer?.cancel();
      _isRunning = false;
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
    super.dispose();
  }
}
