import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      // 假设您从一个API获取数据，替换以下URL为您的API端点
      final response = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=sc'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final responseHonkang = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=flw&lang=sc'));
        if(responseHonkang.statusCode == 200){
          final honData = json.decode(responseHonkang.body);

          // 解析其他字段
          generalSituation = honData['generalSituation'];
          forecastDesc = honData['forecastDesc'];
          outlook = honData['outlook'];
          updateTime = honData['updateTime'];

        }else{
          generalSituation = "";
          forecastDesc = "";
          outlook = "";
          updateTime = "";
        }

        // Fetch forecast data
        final lineHonkang = await http.get(Uri.parse('https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=fnd&lang=sc'));
        if(lineHonkang.statusCode == 200){
          final lineData = json.decode(lineHonkang.body);
          weatherForecast = List<Map<String, dynamic>>.from(lineData['weatherForecast']);
          print("lineHonkang.weatherForecastweatherForecast $weatherForecast");
        }else{
          print("lineHonkang.statusCode != 200");
        }



        // 解析温度数据
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
          errorMessage = "Failed to load data";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch weather data";
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
        errorMessage = "City not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weather App"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            if (temperature != 0.0)
              Column(
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
                        TextSpan(text: "天气概况 ", style: TextStyle(fontSize: 50)), // 前四个字放大
                        TextSpan(text: "$generalSituation", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(text: "天气预测 ", style: TextStyle(fontSize: 50)), // 前四个字放大
                        TextSpan(text: "$forecastDesc", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(text: "长期预测 ", style: TextStyle(fontSize: 50)), // 前四个字放大
                        TextSpan(text: " $outlook", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(text: "更新时间", style: TextStyle(fontSize: 50)), // 前四个字放大
                        TextSpan(text: "$updateTime", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),




                ],
              ),
          ],
        ),
      ),
    );
  }
}
