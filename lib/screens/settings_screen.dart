// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_temperature_control/providers/temperature_provider.dart';
import 'package:bluetooth_temperature_control/models/temperature_point.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _addTemperaturePoint(BuildContext context) {
    final temperatureProvider = Provider.of<TemperatureProvider>(context, listen: false);
    temperatureProvider.addTemperaturePoint(TemperaturePoint(time: 0, temperature: 20));
  }

  void _saveTemperaturePoints(BuildContext context) async {
    final temperatureProvider = Provider.of<TemperatureProvider>(context, listen: false);
    try {
      await temperatureProvider.sendTemperaturePointsWithVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('温控点已保存并验证')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存温控点失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置温控点'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveTemperaturePoints(context),
          ),
        ],
      ),
      body: Consumer<TemperatureProvider>(
        builder: (context, temperatureProvider, child) {
          return ListView.builder(
            itemCount: temperatureProvider.temperaturePoints.length,
            itemBuilder: (context, index) {
              final point = temperatureProvider.temperaturePoints[index];
              return ListTile(
                title: Text('温控点 ${index + 1}'),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: point.time.toString(),
                        decoration: const InputDecoration(labelText: '时间 (分钟)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newTime = int.tryParse(value) ?? point.time;
                          temperatureProvider.editTemperaturePoint(
                            index,
                            TemperaturePoint(time: newTime, temperature: point.temperature),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: point.temperature.toString(),
                        decoration: const InputDecoration(labelText: '温度 (°C)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newTemp = int.tryParse(value) ?? point.temperature;
                          temperatureProvider.editTemperaturePoint(
                            index,
                            TemperaturePoint(time: point.time, temperature: newTemp),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => temperatureProvider.removeTemperaturePoint(index),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTemperaturePoint(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}