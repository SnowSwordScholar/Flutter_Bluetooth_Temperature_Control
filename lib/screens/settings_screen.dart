// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../models/temperature_point.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    final TextEditingController timeController = TextEditingController();
    final TextEditingController tempController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置温控点'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await tempProvider.sendTemperaturePointsWithVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('温控点已发送至设备，等待验证')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: tempProvider.temperaturePoints.isEmpty
                ? const Center(child: Text('暂无温控点'))
                : ListView.builder(
                    itemCount: tempProvider.temperaturePoints.length,
                    itemBuilder: (context, index) {
                      final point = tempProvider.temperaturePoints[index];
                      return ListTile(
                        title: Text('时间: ${point.time} 分钟'),
                        subtitle: Text('温度: ${point.temperature} °C'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final TextEditingController editTimeController =
                                        TextEditingController(text: point.time.toString());
                                    final TextEditingController editTempController =
                                        TextEditingController(text: point.temperature.toString());
                                    return AlertDialog(
                                      title: const Text('编辑温控点'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: editTimeController,
                                            decoration: const InputDecoration(labelText: '时间 (分钟)'),
                                            keyboardType: TextInputType.number,
                                          ),
                                          TextField(
                                            controller: editTempController,
                                            decoration: const InputDecoration(labelText: '温度 (°C)'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            int? newTime = int.tryParse(editTimeController.text);
                                            int? newTemp = int.tryParse(editTempController.text);
                                            if (newTime != null && newTemp != null) {
                                              tempProvider.editTemperaturePoint(
                                                  index,
                                                  TemperaturePoint(
                                                      time: newTime,
                                                      temperature: newTemp));
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          child: const Text('保存'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                tempProvider.removeTemperaturePoint(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: '时间 (分钟)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: tempController,
                  decoration: const InputDecoration(labelText: '温度 (°C)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    int? time = int.tryParse(timeController.text);
                    int? temp = int.tryParse(tempController.text);
                    if (time != null && temp != null) {
                      tempProvider.addTemperaturePoint(
                          TemperaturePoint(time: time, temperature: temp));
                      timeController.clear();
                      tempController.clear();
                    }
                  },
                  child: const Text('添加温控点'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}