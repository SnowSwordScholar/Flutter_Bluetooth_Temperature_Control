// lib/providers/device_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/device.dart';

class DeviceProvider with ChangeNotifier {
  final Logger _logger = Logger();
  List<Device> _availableDevices = [];
  Device? _selectedDevice;

  List<Device> get availableDevices => _availableDevices;
  Device? get selectedDevice => _selectedDevice;

  DeviceProvider() {
    scanDevices();
    loadSelectedDevice();
  }

  // 加载已选择的设备
  Future<void> loadSelectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('selected_device_id');
    if (deviceId != null) {
      // 等待设备扫描完成后设置已选择的设备
      await Future.delayed(const Duration(seconds: 5));
      Device? device = _availableDevices.firstWhere(
        (device) => device.id == deviceId,
        orElse: () => Device(id: deviceId, name: "未知设备"),
      );
      _selectedDevice = device;
      notifyListeners();
    }
  }

  // 扫描设备
  Future<void> scanDevices() async {
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        _availableDevices = results
            .map((r) => Device(
                  id: r.device.remoteId.str,
                  name: r.device.platformName.isNotEmpty ? r.device.platformName : "未知设备",
                ))
            .toList();
        notifyListeners();
      });
    } catch (e) {
      _logger.e("扫描设备时出错: $e");
    }
  }

  // 选择设备
  Future<void> selectDevice(Device device) async {
    _selectedDevice = device;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_device_id', device.id);
    notifyListeners();
  }

  // 清除选择的设备
  Future<void> clearSelectedDevice() async {
    _selectedDevice = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_device_id');
    notifyListeners();
  }
}
