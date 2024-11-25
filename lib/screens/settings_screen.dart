import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../models/temperature_point.dart';

class SettingsScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('设置温控点'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              tempProvider.sendTemperaturePoints();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('温控点已发送至设备')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tempProvider.temperaturePoints.length,
              itemBuilder: (context, index) {
                final point = tempProvider.temperaturePoints[index];
                return ListTile(
                  title: Text('时间: ${point.time} 分钟'),
                  subtitle: Text('温度: ${point.temperature} °C'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      tempProvider.removeTemperaturePoint(index);
                    },
                  ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(labelText: '时间 (分钟)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入时间';
                        }
                        if (int.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempController,
                      decoration: InputDecoration(labelText: '温度 (°C)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入温度';
                        }
                        if (int.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        int time = int.parse(_timeController.text);
                        int temp = int.parse(_tempController.text);
                        tempProvider.addTemperaturePoint(
                          TemperaturePoint(time: time, temperature: temp),
                        );
                        _timeController.clear();
                        _tempController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
