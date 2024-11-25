import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/temperature_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monitor_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemperatureProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // 可以根据Provider提供的主题设置进行动态主题切换
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '温控管理APP',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(),
      routes: {
        '/settings': (context) => SettingsScreen(),
        '/monitor': (context) => MonitorScreen(),
      },
    );
  }
}
