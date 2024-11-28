// lib/models/temperature_point.dart
class TemperaturePoint {
  final int time; // 时间，以分钟为单位
  final int temperature; // 温度，以摄氏度为单位

  TemperaturePoint({required this.time, required this.temperature});

  factory TemperaturePoint.fromJson(Map<String, dynamic> json) {
    return TemperaturePoint(
      time: json['time'],
      temperature: json['temperature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
    };
  }
}