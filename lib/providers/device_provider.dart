// lib/providers/device_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/device.dart';
import '../services/bluetooth_manager.dart'; // 导入 BluetoothManager

class DeviceProvider with ChangeNotifier {
  final Logger _logger = Logger();
  List<Device> _availableDevices = [];
  Device? _selectedDevice;
  final BluetoothManager _bluetoothManager = BluetoothManager();

  List<Device> get availableDevices => _availableDevices;
  Device? get selectedDevice => _selectedDevice;

  DeviceProvider() {
    scanDevices();
    loadSelectedDevice();
  }

  // 加载已选择的设备
  Future<void> loadSelectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString('selected_device_name');
    if (deviceName != null) {
      // 等待设备扫描完成后设置已选择的设备
      await Future.delayed(const Duration(seconds: 5));
      Device? device = _availableDevices.firstWhere(
        (device) => device.platformName == deviceName,
        orElse: () => Device(id: "", platformName: "未知设备"),
      );
      if (device.platformName != "未知设备") {
        _selectedDevice = device;
        notifyListeners();
        _logger.i("已加载已选择的设备: ${_selectedDevice!.platformName}");
      } else {
        _logger.w("未找到已选择的设备: $deviceName");
      }
    }
  }

  // 扫描设备
  Future<void> scanDevices() async {
    try {
      _availableDevices.clear();
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), withServices: []);
      FlutterBluePlus.scanResults.listen((results) {
        _availableDevices = results
            .map((r) => Device(
                  id: r.device.id.id,
                  platformName: r.device.platformName.isNotEmpty ? r.device.platformName : "未知设备",
                ))
            .toList();
        notifyListeners();
        _logger.i("扫描到 ${_availableDevices.length} 个设备");
      });
    } catch (e) {
      _logger.e("扫描设备时出错: $e");
    }
  }

  // 选择设备
  Future<void> selectDevice(Device device) async {
    _selectedDevice = device;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_device_name', device.platformName);
    notifyListeners();
    _logger.i("已选择设备: ${device.platformName}");
  }

  // 清除选择的设备
  Future<void> clearSelectedDevice() async {
    _selectedDevice = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_device_name');
    notifyListeners();
    _logger.i("已清除选择的设备");
  }

  // 连接到已选择的设备
  Future<void> connectToSelectedDevice() async {
    if (_selectedDevice != null && _selectedDevice!.platformName == "ESP32_Temperature_Controll") {
      try {
        await _bluetoothManager.connectToDevice(_selectedDevice!.id);
        _logger.i("成功连接到设备: ${_selectedDevice!.platformName}");
      } catch (e) {
        _logger.e("连接设备时出错: $e");
        throw Exception("连接设备时出错: $e");
      }
    } else {
      throw Exception("未选择有效设备");
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    try {
      await _bluetoothManager.disconnect();
      _logger.i("已断开设备连接");
    } catch (e) {
      _logger.e("断开连接时出错: $e");
      throw Exception("断开连接时出错: $e");
    }
  }

  // 获取 BluetoothManager 实例
  BluetoothManager get bluetoothManager => _bluetoothManager;
}