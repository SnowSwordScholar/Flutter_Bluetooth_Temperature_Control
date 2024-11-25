// lib/providers/temperature_provider.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_manager.dart';
import '../models/temperature_point.dart';

class TemperatureProvider with ChangeNotifier {
  final List<TemperaturePoint> _temperaturePoints = [];
  int runtime = 0;
  int currentTemperature = 0;
  final BluetoothManager _bluetoothManager = BluetoothManager();

  TemperatureProvider() {
    // 设置接收数据的回调
    _bluetoothManager.onDataReceived = _handleBluetoothData;
    // 连接到设备（请替换为实际的设备名称）
    _bluetoothManager.connectToDevice("ESP32_Device_Name");
  }

  // 获取温控点列表
  List<TemperaturePoint> get temperaturePoints => List.unmodifiable(_temperaturePoints);

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

  // 发送温控点数据到设备
  void sendTemperaturePoints() {
    Map<String, dynamic> data = {
      "command": "set_temperature_points",
      "data": _temperaturePoints.map((e) => e.toJson()).toList(),
    };
    _bluetoothManager.sendData(data);
  }

  // 处理接收到的蓝牙数据
  void _handleBluetoothData(Map<String, dynamic> data) {
    if (data['command'] == 'current_status') {
      runtime = data['data']['runtime'];
      currentTemperature = data['data']['current_temperature'];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bluetoothManager.disconnect();
    super.dispose();
  }
}
