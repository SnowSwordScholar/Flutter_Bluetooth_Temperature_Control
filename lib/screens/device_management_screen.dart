// lib/screens/device_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_temperature_control/providers/device_provider.dart';
import 'package:bluetooth_temperature_control/models/device.dart';

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              deviceProvider.scanDevices();
            },
          ),
        ],
      ),
      body: deviceProvider.availableDevices.isEmpty
          ? const Center(child: Text('未发现任何设备'))
          : ListView.builder(
              itemCount: deviceProvider.availableDevices.length,
              itemBuilder: (context, index) {
                final device = deviceProvider.availableDevices[index];
                final isSelected =
                    deviceProvider.selectedDevice?.id == device.id;
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "未知设备"),
                  subtitle: Text(device.id),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    deviceProvider.selectDevice(device);
                  },
                );
              },
            ),
      floatingActionButton: deviceProvider.selectedDevice != null
          ? FloatingActionButton(
              child: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context); // 关闭设备管理页面
              },
            )
          : null,
    );
  }
}
