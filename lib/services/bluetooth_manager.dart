// lib/services/bluetooth_manager.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class BluetoothManager {
  final Logger _logger = Logger();
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // 回调函数，用于传递接收到的数据
  Function(Map<String, dynamic>)? onDataReceived;

  // 检查蓝牙是否支持
  Future<bool> isBluetoothSupported() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      _logger.e("检查蓝牙支持性时出错: $e");
      return false;
    }
  }

  // 检查蓝牙是否已开启
  Future<bool> isBluetoothOn() async {
    try {
      // 获取适配器状态
      Stream<BluetoothAdapterState> stateStream = FlutterBluePlus.adapterState;
      BluetoothAdapterState state = await stateStream.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      _logger.e("检查蓝牙状态时出错: $e");
      return false;
    }
  }

  // 扫描设备
  Future<void> startScan() async {
    try {
      // 开始扫描
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      // 监听扫描结果
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          _logger.i("发现设备: ${r.device.platformName.isNotEmpty ? r.device.platformName : "未知设备"} - ${r.device.remoteId.str}");
        }
      });
    } catch (e) {
      _logger.e("扫描设备时出错: $e");
    }
  }

  // 停止扫描
  Future<void> stopScan() async {
    try {
      FlutterBluePlus.stopScan();
      _logger.i("已停止扫描.");
    } catch (e) {
      _logger.e("停止扫描时出错: $e");
    }
  }

  // 连接到设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      _logger.i("尝试连接设备: $deviceId");
      // 获取所有已连接的设备
      List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;
      // 查找目标设备
      _connectedDevice = connectedDevices.firstWhere(
        (device) => device.remoteId.str == deviceId,
        orElse: () => throw Exception("设备未找到"),
      );

      // 连接设备
      await _connectedDevice!.connect(autoConnect: false);
      _logger.i("已连接到设备: ${_connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : "未知设备"}");

      // 发现服务和特征
      await _discoverServices();
    } catch (e) {
      _logger.e("连接设备时出错: $e");
    }
  }

  // 发现服务和特征
  Future<void> _discoverServices() async {
    try {
      if (_connectedDevice == null) return;

      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen((value) {
              _logger.i("收到的数据: $value");
              String jsonString = utf8.decode(value);
              try {
                Map<String, dynamic> data = jsonDecode(jsonString);
                if (onDataReceived != null) {
                  onDataReceived!(data);
                }
              } catch (e) {
                _logger.e("解析数据时出错: $e");
              }
            });
          }
        }
      }
    } catch (e) {
      _logger.e("发现服务时出错: $e");
    }
  }

  // 发送数据
  Future<void> sendData(Map<String, dynamic> data) async {
    try {
      if (_writeCharacteristic == null) {
        throw Exception("未找到写入特征");
      }
      String jsonString = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonString);
      await _writeCharacteristic!.write(bytes, withoutResponse: true);
      _logger.i("数据已发送: $jsonString");
    } catch (e) {
      _logger.e("发送数据时出错: $e");
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _logger.i("设备已断开连接.");
      }
    } catch (e) {
      _logger.e("断开连接时出错: $e");
    }
  }
}
