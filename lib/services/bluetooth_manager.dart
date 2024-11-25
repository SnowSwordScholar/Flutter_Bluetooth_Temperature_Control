// lib/services/bluetooth_manager.dart
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

class BluetoothManager {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  // 回调函数，用于传递接收到的数据
  Function(Map<String, dynamic>)? onDataReceived;

  // 扫描并连接设备
  Future<void> connectToDevice(String deviceName) async {
    try {
      _flutterBlue.startScan(timeout: const Duration(seconds: 4));

      // 监听扫描结果
      _flutterBlue.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.name == deviceName) {
            _flutterBlue.stopScan();
            _connectedDevice = r.device;
            await _connectedDevice!.connect();
            await _discoverServices();
            break;
          }
        }
      });
    } catch (e) {
      // 处理连接错误
      print("连接设备时出错: $e");
    }
  }

  // 发现服务和特征
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify) {
          _notifyCharacteristic = characteristic;
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            // 处理接收到的数据
            String jsonString = utf8.decode(value);
            try {
              Map<String, dynamic> data = jsonDecode(jsonString);
              if (onDataReceived != null) {
                onDataReceived!(data);
              }
            } catch (e) {
              print("解析JSON数据时出错: $e");
            }
          });
        }
      }
    }
  }

  // 发送数据
  Future<void> sendData(Map<String, dynamic> data) async {
    if (_writeCharacteristic == null) return;
    String jsonString = jsonEncode(data);
    List<int> bytes = utf8.encode(jsonString);
    await _writeCharacteristic!.write(bytes, withoutResponse: true);
  }

  // 断开连接
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
}
