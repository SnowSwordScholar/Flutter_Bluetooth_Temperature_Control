// lib/models/temperature_point.dart
class TemperaturePoint {
  int time; // 分钟
  int temperature; // 摄氏度

  TemperaturePoint({required this.time, required this.temperature});

  Map<String, dynamic> toJson() => {
        'time': time,
        'temperature': temperature,
      };

  factory TemperaturePoint.fromJson(Map<String, dynamic> json) {
    return TemperaturePoint(
      time: json['time'],
      temperature: json['temperature'],
    );
  }
}
