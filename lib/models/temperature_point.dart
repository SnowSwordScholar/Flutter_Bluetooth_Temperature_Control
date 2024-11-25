// lib/models/temperature_point.dart
class TemperaturePoint {
  int time; // 分钟
  int temperature; // 摄氏度
  int duration; // 持续时间，秒

  TemperaturePoint({required this.time, required this.temperature, required this.duration});

  Map<String, dynamic> toJson() => {
        'time': time,
        'temperature': temperature,
        'duration': duration,
      };

  factory TemperaturePoint.fromJson(Map<String, dynamic> json) {
    return TemperaturePoint(
      time: json['time'],
      temperature: json['temperature'],
      duration: json['duration'],
    );
  }
}
