import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';

class MonitorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tempProvider = Provider.of<TemperatureProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('实时监控'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('当前温度: ${tempProvider.currentTemperature}°C',
                style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('运行时间: ${tempProvider.runtime} 分钟',
                style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
