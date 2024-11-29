// lib/providers/temperature_provider.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_manager.dart';
import '../models/temperature_point.dart';
import 'device_provider.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class TemperatureProvider with ChangeNotifier {
  final Logger _logger = Logger();

  // 温控点列表
  final List<TemperaturePoint> _temperaturePoints = [];

  // 即将进行的操作列表
  final List<String> _upcomingOperations = [];

  // 当前运行时间（分钟）
  int runtime = 0;

  // 当前温度（°C）
  int currentTemperature = 0;

  // BluetoothManager 实例
  BluetoothManager? _bluetoothManager;

  // 运行状态
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  // 连接状态
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 自动运行计时器
  Timer? _autoRunTimer;

  // 启动延迟计时器
  Timer? _startupDelayTimer;

  // 启动延迟时间（秒）
  int _startupDelay = 10;

  // 剩余启动时间（秒）
  int _remainingTime = 0;
  int get remainingTime => _remainingTime;

  // 验证状态
  bool _verificationPassed = false;
  bool get verificationPassed => _verificationPassed;

  // 温控点数据加载状态
  bool _temperaturePointsLoaded = false;
  bool get temperaturePointsLoaded => _temperaturePointsLoaded;

  // 数据请求失败状态
  bool _dataRequestFailed = false;
  bool get dataRequestFailed => _dataRequestFailed;

  // 数据超时定时器
  Timer? _dataTimeoutTimer;

  // 日志
  final Logger logger = Logger();

  TemperatureProvider();

  /// 当选择了设备后连接
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

        // 连接后请求温度数据（设备会自动发送）
        await retrieveTemperatureData();

        // 启动超时定时器
        _dataTimeoutTimer?.cancel();
        _dataTimeoutTimer = Timer(const Duration(seconds: 5), () {
          if (!_temperaturePointsLoaded) {
            logger.w("温控点数据未在预期时间内收到");
            _dataRequestFailed = true;
            notifyListeners();
          }
        });
      } catch (e) {
        logger.e("连接到设备时出错: $e");
        throw Exception("连接到设备时出错: $e");
      }
    } else {
      throw Exception("未选择有效设备");
    }
  }

  /// 请求设备发送已有的温度数据（设备会自动发送，但这里作为冗余）
  Future<void> retrieveTemperatureData() async {
    try {
      Map<String, dynamic> request = {
        "command": "get_temperature_points",
      };
      await _bluetoothManager!.sendData(request);
      logger.i("已发送获取温控点请求");
    } catch (e) {
      logger.e("请求温度数据时出错: $e");
    }
  }

  /// 处理从设备接收到的数据
  void _handleBluetoothData(Map<String, dynamic> data) {
    if (data['command'] == 'current_status') {
      runtime = data['data']['runtime'];
      currentTemperature = data['data']['current_temperature'];
      notifyListeners();
    } else if (data['command'] == 'verify_temperature_points') {
      String status = data['status'];
      String message = data['message'];
      if (status == 'success') {
        logger.i("温控点验证通过");
        _verificationPassed = true;
        notifyListeners();
      } else {
        logger.e("温控点验证失败: $message");
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
        logger.i("运行已开始");
        _isRunning = true;
        notifyListeners();
      } else if (status == 'interrupted') {
        logger.i("运行已中断");
        _isRunning = false;
        notifyListeners();
      }
      // 处理其他运行状态
    }
    // 处理其他命令
  }

  /// 发送温控点数据并等待验证
  Future<void> sendTemperaturePointsWithVerification() async {
    try {
      // 先进行温度点的时间顺序验证
      if (!validateTemperaturePoints()) {
        throw Exception("温度点时间设置不正确。请确保每个温度点的时间大于前一个温度点。");
      }

      Map<String, dynamic> data = {
        "command": "set_temperature_points",
        "data": _temperaturePoints.map((e) => e.toJson()).toList(),
      };
      await _bluetoothManager!.sendData(data);
      logger.i("已发送温控点数据");
      // 设备会响应 "verify_temperature_points" 命令
    } catch (e) {
      logger.e("发送温控点数据时出错: $e");
      // 可以考虑设置一个错误状态并通知 UI
    }
  }

  /// 发送开始运行命令
  Future<void> sendStartRunCommand() async {
    try {
      Map<String, dynamic> data = {
        "command": "start_run",
      };
      await _bluetoothManager!.sendData(data);
      logger.i("已发送开始运行命令");
      // 设备会响应 "run_status" 命令
    } catch (e) {
      logger.e("发送开始运行命令时出错: $e");
    }
  }

  /// 启动自动运行计时器
  void startAutoRun() {
    if (_temperaturePoints.isEmpty) return;

    _isRunning = true;
    _verificationPassed = false;
    notifyListeners();

    // 计算各时间点的延迟（分钟）
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

  /// 启动延迟计时
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

  /// 中断当前运行
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
        logger.i("已发送中断命令");
      } catch (e) {
        logger.e("发送中断命令时出错: $e");
      }
    }
  }

  /// 编辑温控点
  void editTemperaturePoint(int index, TemperaturePoint newPoint) {
    if (index >= 0 && index < _temperaturePoints.length) {
      // 验证时间顺序
      if (!canSetTemperaturePoint(index, newPoint.time)) {
        logger.w("温控点时间设置不正确。");
        return;
      }
      _temperaturePoints[index] = newPoint;
      notifyListeners();
    }
  }

  /// 添加温控点
  void addTemperaturePoint(TemperaturePoint point) {
    // 验证时间顺序
    if (!canAddTemperaturePoint(point.time)) {
      logger.w("温控点时间设置不正确。");
      // 可以考虑通知 UI 失败，或在 UI 中处理
      return;
    }
    _temperaturePoints.add(point);
    notifyListeners();
  }

  /// 删除温控点
  void removeTemperaturePoint(int index) {
    if (index >= 0 && index < _temperaturePoints.length) {
      _temperaturePoints.removeAt(index);
      notifyListeners();
    }
  }

  /// 设置温控点列表
  void setTemperaturePoints(List<TemperaturePoint> points) {
    _temperaturePoints.clear();
    _temperaturePoints.addAll(points);
    _verificationPassed = false;
    notifyListeners();
  }

  /// 请求重新发送温控点数据
  Future<void> requestTemperaturePoints() async {
    try {
      Map<String, dynamic> request = {
        "command": "get_temperature_points",
      };
      await _bluetoothManager!.sendData(request);
      logger.i("已发送重新请求温控点数据");

      // 重置标志位
      _temperaturePointsLoaded = false;
      _dataRequestFailed = false;
      notifyListeners();

      // 重新启动超时定时器
      _dataTimeoutTimer?.cancel();
      _dataTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!_temperaturePointsLoaded) {
          logger.w("重新请求温控点数据后仍未收到数据");
          _dataRequestFailed = true;
          notifyListeners();
        }
      });
    } catch (e) {
      logger.e("重新请求温控点数据时出错: $e");
    }
  }

  /// 用户选择跳过恢复环节，直接进入设置温控点
  void skipLoadingTemperaturePoints() {
    _temperaturePointsLoaded = true;
    _dataRequestFailed = false;
    _temperaturePoints.clear(); // 清空现有温控点，允许用户添加新的温控点
    _dataTimeoutTimer?.cancel();
    notifyListeners();
  }

  /// 验证温控点时间顺序
  bool validateTemperaturePoints() {
    if (_temperaturePoints.isEmpty) return true;
    // 确保第一个温控点时间 >= 0
    if (_temperaturePoints[0].time < 0) return false;
    for (int i = 1; i < _temperaturePoints.length; i++) {
      if (_temperaturePoints[i].time <= _temperaturePoints[i - 1].time) {
        return false;
      }
    }
    return true;
  }

  /// 检查是否可以设置温控点时间
  bool canSetTemperaturePoint(int index, int newTime) {
    if (index == 0) {
      // 第一个温控点时间必须 >= 0
      return newTime >= 0;
    } else {
      // 当前温控点时间必须 > 前一个温控点时间
      if (newTime <= _temperaturePoints[index - 1].time) return false;
      // 当前温控点时间必须 < 下一个温控点时间（如果有）
      if (index < _temperaturePoints.length - 1) {
        if (newTime >= _temperaturePoints[index + 1].time) return false;
      }
      return true;
    }
  }

  /// 检查是否可以添加温控点时间
  bool canAddTemperaturePoint(int newTime) {
    if (_temperaturePoints.isEmpty) {
      return newTime >= 0;
    } else {
      // 新增的温控点时间必须 > 最后一个温控点时间
      return newTime > _temperaturePoints.last.time;
    }
  }

  @override
  void dispose() {
    _bluetoothManager?.disconnect();
    _autoRunTimer?.cancel();
    _startupDelayTimer?.cancel();
    _dataTimeoutTimer?.cancel();
    super.dispose();
  }

  // 公开温控点列表
  List<TemperaturePoint> get temperaturePoints => List.unmodifiable(_temperaturePoints);

  // 公开即将进行的操作列表
  List<String> get upcomingOperations => List.unmodifiable(_upcomingOperations);
}