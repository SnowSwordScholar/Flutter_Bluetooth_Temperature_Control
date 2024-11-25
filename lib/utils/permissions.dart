// lib/utils/permissions.dart
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  /// 请求所有必要的权限
  static Future<bool> requestAllPermissions() async {
    // 定义需要请求的权限列表
    List<Permission> permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ];

    // 请求权限
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // 检查所有权限是否被授予
    bool allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted;
  }
}
