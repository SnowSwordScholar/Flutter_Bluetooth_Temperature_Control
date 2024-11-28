// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_temperature_control/providers/temperature_provider.dart';
import 'package:bluetooth_temperature_control/models/temperature_point.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<TemperaturePoint> _temperaturePoints;

  @override
  void initState() {
    super.initState();
    final temperatureProvider = Provider.of<TemperatureProvider>(context, listen: false);
    _temperaturePoints = List.from(temperatureProvider.temperaturePoints);
  }

  void _addTemperaturePoint() {
    setState(() {
      _temperaturePoints.add(TemperaturePoint(time: 0, temperature: 20));
    });
  }

  void _removeTemperaturePoint(int index) {
    setState(() {
      _temperaturePoints.removeAt(index);
    });
  }

  void _saveTemperaturePoints() async {
    final temperatureProvider = Provider.of<TemperatureProvider>(context, listen: false);
    temperatureProvider.setTemperaturePoints(_temperaturePoints);
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
    final temperatureProvider = Provider.of<TemperatureProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置温控点'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemperaturePoints,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _temperaturePoints.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('温控点 ${index + 1}'),
            subtitle: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _temperaturePoints[index].time.toString(),
                    decoration: const InputDecoration(labelText: '时间 (分钟)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _temperaturePoints[index] = TemperaturePoint(
                          time: int.tryParse(value) ?? _temperaturePoints[index].time,
                          temperature: _temperaturePoints[index].temperature,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: _temperaturePoints[index].temperature.toString(),
                    decoration: const InputDecoration(labelText: '温度 (°C)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _temperaturePoints[index] = TemperaturePoint(
                          time: _temperaturePoints[index].time,
                          temperature: int.tryParse(value) ?? _temperaturePoints[index].temperature,
                        );
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTemperaturePoint(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemperaturePoint,
        child: const Icon(Icons.add),
      ),
    );
  }
}