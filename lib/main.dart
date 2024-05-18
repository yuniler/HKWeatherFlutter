import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeatherApp(),
    );
  }
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  String selectedCity = "京士柏";
  double temperature = 0.0;
  String errorMessage = "";

  String generalSituation = "";
  String forecastDesc = "";
  String outlook = "";
  String updateTime = "";

  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> weatherForecast = [];

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  void fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=sc'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final responseHonkang = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=flw&lang=sc'));
        if (responseHonkang.statusCode == 200) {
          final honData = json.decode(responseHonkang.body);
          generalSituation = honData['generalSituation'];
          forecastDesc = honData['forecastDesc'];
          outlook = honData['outlook'];
          updateTime = honData['updateTime'];
        }

        final lineHonkang = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=fnd&lang=sc'));
        if (lineHonkang.statusCode == 200) {
          final lineData = json.decode(lineHonkang.body);
          weatherForecast = List<Map<String, dynamic>>.from(lineData['weatherForecast']);
          weatherForecast.removeRange(7, weatherForecast.length);
        }

        final List<dynamic> tempData = data['temperature']['data'];
        setState(() {
          cities = tempData.map((item) => {
            'place': item['place'],
            'temperature': item['value']
          }).toList();
          updateTemperature(selectedCity);
        });
      } else {
        setState(() {
          errorMessage = "数据加载失败";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "获取天气数据失败";
      });
    }
  }

  void updateTemperature(String city) {
    final cityData = cities.firstWhere((item) => item['place'] == city, orElse: () => {'place': '', 'temperature': 0.0});

    if (cityData != null) {
      setState(() {
        temperature = cityData['temperature'].toDouble();
        errorMessage = "";
      });
    } else {
      setState(() {
        errorMessage = "找不到城市";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HK Weather App"),
        backgroundColor: Colors.blue,
        actions: [
          DropdownButton<String>(
            value: selectedCity,
            icon: Icon(Icons.arrow_downward, color: Colors.white),
            dropdownColor: Colors.blue,
            onChanged: (String? newCity) {
              if (newCity != null) {
                setState(() {
                  selectedCity = newCity;
                  updateTemperature(selectedCity);
                });
              }
            },
            items: cities.map<DropdownMenuItem<String>>((Map<String, dynamic> city) {
              return DropdownMenuItem<String>(
                value: city['place'],
                child: Text(city['place'], style: TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
      body:Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/weatherp1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              if (temperature != 0.0)
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$selectedCity",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      "$temperature °C",
                      style: TextStyle(fontSize: 50),
                    ),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: "天气概况   ", style: TextStyle(fontSize: 20)),
                          TextSpan(text: "$generalSituation", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: "天气预测   ", style: TextStyle(fontSize: 20)),
                          TextSpan(text: "$forecastDesc", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: "长期预测   ", style: TextStyle(fontSize: 20)),
                          TextSpan(text: " $outlook", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: "更新时间   ", style: TextStyle(fontSize: 20)),
                          TextSpan(text: "$updateTime", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (weatherForecast.isNotEmpty)

                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: weatherForecast.length * 60.0,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true,horizontalInterval: 1),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < weatherForecast.length) {
                                    return Text(weatherForecast[index]['week'],style: TextStyle(
                                      fontSize: 12,

                                    ),);
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            // leftTitles: AxisTitles(
                            //   sideTitles: SideTitles(showTitles: true),
                            // ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: weatherForecast.asMap().entries.map((entry) {
                                int index = entry.key;
                                var forecast = entry.value;
                                return FlSpot(index.toDouble(), forecast['forecastMaxtemp']['value'].toDouble());
                              }).toList(),
                              isCurved: true,
                              // colors: [Colors.red],
                              barWidth: 2,
                              // belowBarData: BarAreaData(show: true, colors: [Colors.red.withOpacity(0.3)]),
                            ),
                            LineChartBarData(
                              spots: weatherForecast.asMap().entries.map((entry) {
                                int index = entry.key;
                                var forecast = entry.value;
                                return FlSpot(index.toDouble(), forecast['forecastMintemp']['value'].toDouble());
                              }).toList(),
                              isCurved: true,
                              // colors: [Colors.blue],
                              barWidth: 2,
                              // belowBarData: BarAreaData(show: true, colors: [Colors.blue.withOpacity(0.3)]),
                            ),
                          ],
                          minX: 0,
                          maxX: weatherForecast.length.toDouble(),
                        ),

                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )

    );
  }
}
