// lib/services/bluetooth_manager.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class BluetoothManager with ChangeNotifier {
  final Logger _logger = Logger();
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  bool _isConnected = false; // 声明 _isConnected 变量

  // 回调函数，用于传递接收到的数据
  Function(Map<String, dynamic>)? onDataReceived;

  // 定义服务UUID和特征UUID（使用 lowerCamelCase）
  final String serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  final String characteristicUuid = "abcdefab-1234-5678-1234-abcdefabcdef";

  bool get isConnected => _isConnected;

  // 扫描并连接到设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      _logger.i("开始扫描设备...");

      // 开始扫描，不过滤任何服务以便调试
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [],
      );

      // 声明 scanSubscription 变量
      late StreamSubscription<List<ScanResult>> scanSubscription;

      // 监听扫描结果
      scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          String deviceName = r.device.platformName; // 使用 platformName
          String deviceIdStr = r.device.id.id; // 使用 id.id

          _logger.i("扫描到设备: $deviceName ($deviceIdStr)");

          if (deviceIdStr == deviceId) {
            _logger.i("找到目标设备: $deviceName ($deviceIdStr)");
            FlutterBluePlus.stopScan();
            await _connect(r.device);
            await scanSubscription.cancel(); // 正确引用已声明的变量
            break;
          }
        }
      });

      // 等待扫描完成
      await FlutterBluePlus.isScanning.firstWhere((isScanning) => !isScanning);
    } catch (e) {
      _logger.e("连接设备时出错: $e");
      throw Exception("连接设备时出错: $e");
    }
  }

  // 连接到设备并发现服务
  Future<void> _connect(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      await _connectedDevice!.connect(autoConnect: false);
      _logger.i("已连接到设备: ${_connectedDevice!.platformName}");

      // 设置连接状态监听
      _connectedDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _logger.w("设备已断开连接");
          _isConnected = false;
          _writeCharacteristic = null;
          _notifyCharacteristic = null;
          notifyListeners();
        }
      });

      // 发现服务
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      for (BluetoothService service in services) {
        _logger.i("发现服务: ${service.uuid}");
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          _logger.i("找到目标服务: ${service.uuid}");

          for (BluetoothCharacteristic characteristic in service.characteristics) {
            _logger.i("检查特征: ${characteristic.uuid}");

            if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              _writeCharacteristic = characteristic;
              _logger.i("找到写入特征: ${characteristic.uuid}");
            }

            if (characteristic.properties.notify) {
              _notifyCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) { // 使用 lastValueStream
                _logger.i("收到通知数据: $value");
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
              _logger.i("找到通知特征: ${characteristic.uuid}");
            }
          }
        }
      }

      if (_writeCharacteristic == null) {
        throw Exception("未找到写入特征");
      }

      if (_notifyCharacteristic == null) {
        _logger.w("未找到通知特征");
      }

      _isConnected = true;
      notifyListeners(); // 通知连接状态变化
      _logger.i("设备连接和服务发现完成");
    } catch (e) {
      _logger.e("连接或服务发现时出错: $e");
      throw Exception("连接或服务发现时出错: $e");
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

      // BLE单次写入的最大字节数（根据设备和平台，通常为512字节）
      const int maxChunkSize = 500;

      for (int i = 0; i < bytes.length; i += maxChunkSize) {
        int end = (i + maxChunkSize < bytes.length) ? i + maxChunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);
        await _writeCharacteristic!.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 50)); // 避免发送过快
      }
      _logger.i("数据已发送: ${jsonString.length} 字节");
    } catch (e) {
      _logger.e("发送数据时出错: $e");
      throw Exception("发送数据时出错: $e");
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
        _isConnected = false;
        notifyListeners();
        _logger.i("设备已断开连接.");
      }
    } catch (e) {
      _logger.e("断开连接时出错: $e");
      throw Exception("断开连接时出错: $e");
    }
  }
}