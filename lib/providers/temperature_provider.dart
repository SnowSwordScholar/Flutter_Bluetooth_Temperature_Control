// lib/providers/temperature_provider.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_manager.dart';
import '../models/temperature_point.dart';
import 'device_provider.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class TemperatureProvider with ChangeNotifier {
  final Logger _logger = Logger();
  final List<TemperaturePoint> _temperaturePoints = [];
  final List<String> _upcomingOperations = [];
  int runtime = 0;
  int currentTemperature = 0;
  BluetoothManager? _bluetoothManager;
  bool _isRunning = false;
  bool _isConnected = false;
  Timer? _autoRunTimer;
  Timer? _startupDelayTimer;
  int _startupDelay = 10; // 预留的时间，秒
  int _remainingTime = 0;
  bool _verificationPassed = false; // 添加验证状态

  bool _temperaturePointsLoaded = false;
  bool get temperaturePointsLoaded => _temperaturePointsLoaded;

  bool _dataRequestFailed = false;
  bool get dataRequestFailed => _dataRequestFailed;

  Timer? _dataTimeoutTimer;

  bool get isRunning => _isRunning;
  bool get isConnected => _isConnected;
  List<TemperaturePoint> get temperaturePoints => List.unmodifiable(_temperaturePoints);
  List<String> get upcomingOperations => List.unmodifiable(_upcomingOperations);
  int get remainingTime => _remainingTime;
  bool get verificationPassed => _verificationPassed; // 获取验证状态

  TemperatureProvider();

  // 当选择了设备后连接
  Future<void> connectToSelectedDevice(DeviceProvider deviceProvider) async {
    if (deviceProvider.selectedDevice != null &&
        deviceProvider.selectedDevice!.platformName == "ESP32_Temperature_Controll") {
      _bluetoothManager = deviceProvider.bluetoothManager;
      _bluetoothManager!.onDataReceived = _handleBluetoothData;
      try {
        await deviceProvider.connectToSelectedDevice();
        _isConnected = true;
        _temperaturePointsLoaded = false;
        _dataRequestFailed = false;
        notifyListeners();

        // 连接后请求温度数据（尽管设备会自动发送）
        await retrieveTemperatureData();

        // 启动超时定时器
        _dataTimeoutTimer?.cancel();
        _dataTimeoutTimer = Timer(const Duration(seconds: 5), () {
          if (!_temperaturePointsLoaded) {
            _logger.w("温控点数据未在预期时间内收到");
            _dataRequestFailed = true;
            notifyListeners();
          }
        });
      } catch (e) {
        _logger.e("连接到设备时出错: $e");
        throw Exception("连接到设备时出错: $e");
      }
    } else {
      throw Exception("未选择有效设备");
    }
  }

  // 请求设备发送已有的温度数据（可选，因为设备会自动发送）
  Future<void> retrieveTemperatureData() async {
    try {
      Map<String, dynamic> request = {
        "command": "get_temperature_points",
      };
      await _bluetoothManager!.sendData(request);
      _logger.i("已发送获取温控点请求");
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
    } else if (data['command'] == 'verify_temperature_points') {
      String status = data['status'];
      String message = data['message'];
      if (status == 'success') {
        _logger.i("温控点验证通过");
        _verificationPassed = true;
        notifyListeners();
      } else {
        _logger.e("温控点验证失败: $message");
        _verificationPassed = false;
        notifyListeners();
      }
    } else if (data['command'] == 'temperature_points') {
      // 接收到设备的温度数据
      List<dynamic> points = data['data'];
      _temperaturePoints.clear();
      for (var point in points) {
        _temperaturePoints.add(TemperaturePoint.fromJson(point));
      }
      _temperaturePointsLoaded = true;
      _dataRequestFailed = false;
      _dataTimeoutTimer?.cancel();
      notifyListeners();
    } else if (data['command'] == 'run_status') {
      String status = data['status'];
      String message = data['message'];
      if (status == 'started') {
        _logger.i("运行已开始");
        _isRunning = true;
        notifyListeners();
      } else if (status == 'interrupted') {
        _logger.i("运行已中断");
        _isRunning = false;
        notifyListeners();
      }
      // 处理其他运行状态
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
      await _bluetoothManager!.sendData(data);
      _logger.i("已发送温控点数据");
      // 设备会响应 "verify_temperature_points" 命令
    } catch (e) {
      _logger.e("发送温控点数据时出错: $e");
    }
  }

  // 发送开始运行命令
  Future<void> sendStartRunCommand() async {
    try {
      Map<String, dynamic> data = {
        "command": "start_run",
      };
      await _bluetoothManager!.sendData(data);
      _logger.i("已发送开始运行命令");
      // 设备会响应 "run_status" 命令
    } catch (e) {
      _logger.e("发送开始运行命令时出错: $e");
    }
  }

  // 启动自动运行计时器
  void startAutoRun() {
    if (_temperaturePoints.isEmpty) return;

    _isRunning = true;
    _verificationPassed = false;
    notifyListeners();

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
        _bluetoothManager!.sendData(setTemp);
      });
    }

    // 发送开始运行命令
    sendStartRunCommand();

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
  Future<void> interruptRun() async {
    if (_isRunning) {
      _autoRunTimer?.cancel();
      _startupDelayTimer?.cancel();
      _isRunning = false;
      _isConnected = false;
      _verificationPassed = false;
      notifyListeners();
      // 发送中断命令到设备
      Map<String, dynamic> interruptCommand = {
        "command": "interrupt",
      };
      try {
        await _bluetoothManager!.sendData(interruptCommand);
        _logger.i("已发送中断命令");
      } catch (e) {
        _logger.e("发送中断命令时出错: $e");
      }
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

  // 设置温控点列表
  void setTemperaturePoints(List<TemperaturePoint> points) {
    _temperaturePoints.clear();
    _temperaturePoints.addAll(points);
    _verificationPassed = false;
    notifyListeners();
  }

  // 请求重新发送温控点数据
  Future<void> requestTemperaturePoints() async {
    try {
      Map<String, dynamic> request = {
        "command": "get_temperature_points",
      };
      await _bluetoothManager!.sendData(request);
      _logger.i("已发送重新请求温控点数据");

      // 重置标志位
      _temperaturePointsLoaded = false;
      _dataRequestFailed = false;
      notifyListeners();

      // 重新启动超时定时器
      _dataTimeoutTimer?.cancel();
      _dataTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!_temperaturePointsLoaded) {
          _logger.w("重新请求温控点数据后仍未收到数据");
          _dataRequestFailed = true;
          notifyListeners();
        }
      });
    } catch (e) {
      _logger.e("重新请求温控点数据时出错: $e");
    }
  }

  // 用户选择跳过恢复环节，直接进入设置温控点
  void skipLoadingTemperaturePoints() {
    _temperaturePointsLoaded = true;
    _dataRequestFailed = false;
    _temperaturePoints.clear(); // 清空现有温控点，允许用户添加新的温控点
    _dataTimeoutTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothManager?.disconnect();
    _autoRunTimer?.cancel();
    _startupDelayTimer?.cancel();
    _dataTimeoutTimer?.cancel();
    super.dispose();
  }
}