// weather_page.dart – edge-to-edge + city picker entegrasyonu (+ ok geri gider)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'city_picker_page.dart';

class WeatherPage extends StatefulWidget {
  final String city;
  const WeatherPage({super.key, required this.city});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late Future<Map<String, dynamic>> weatherData;
  late String currentCity;
  int selectedHourIndex = 2; // 17:00 seçili

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ));

    currentCity = widget.city;
    weatherData = fetchWeather(currentCity);
  }

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    const String apiKey = '1a82d9fa4d5b4b9e8d1120003252807';
    final url = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=3&aqi=no&alerts=no',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch weather');
    }
  }

  String _monthShort(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
  String _weekdayFull(int w) =>
      const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][w - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF48A5F4), Color(0xFF90CAF9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<Map<String, dynamic>>(
            future: weatherData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)),
                );
              }

              final data = snapshot.data!;
              final location = data['location'];
              final current = data['current'];
              final forecast = (data['forecast']['forecastday'] as List).cast<dynamic>();

              // 15:00–18:00
              final hours = (forecast[0]['hour'] as List<dynamic>).where((h) {
                final hh = int.parse((h['time'] as String).substring(11, 13));
                return hh >= 15 && hh <= 18;
              }).toList();

              final todayDate = DateTime.parse(forecast[0]['date']);
              final todayLabel = '${_monthShort(todayDate.month)}, ${todayDate.day}';

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  children: [
                    // Üst bar
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  (location?['name'] as String?) ?? currentCity,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // ↓↓↓ küçük beyaz ok: geri dönsün
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                onPressed: () => Navigator.maybePop(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Arama
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () async {
                            final selected = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CityPickerPage(),
                              ),
                            );
                            if (selected != null && selected.isNotEmpty) {
                              setState(() {
                                currentCity = selected;
                                weatherData = fetchWeather(currentCity);
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.notifications_none, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 8),
                    Image.network('https:${current['condition']['icon']}', width: 110, height: 110),
                    const SizedBox(height: 2),

                    Text(
                      '${(current['temp_c'] as num).round()}°',
                      style: const TextStyle(
                          fontSize: 64, height: 1.0, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text('Precipitations', style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 14)),
                    Text(
                      'Max: ${forecast[0]['day']['maxtemp_c']}°  Min: ${forecast[0]['day']['mintemp_c']}°',
                      style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 14),
                    ),
                    const SizedBox(height: 14),

                    _Frosted(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.water_drop, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('${forecast[0]['day']['daily_chance_of_rain']}%',
                                  style: const TextStyle(color: Colors.white)),
                            ]),
                            Row(children: [
                              const Icon(Icons.opacity, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('${current['humidity']}%', style: const TextStyle(color: Colors.white)),
                            ]),
                            Row(children: [
                              const Icon(Icons.air, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('${current['wind_kph']} km/h', style: const TextStyle(color: Colors.white)),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Today',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(todayLabel, style: TextStyle(color: Colors.white.withValues(alpha: .7))),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _Frosted(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(hours.length, (i) {
                            final hour = hours[i];
                            final time = (hour['time'] as String).substring(11, 16);
                            final temp = (hour['temp_c'] as num).round();
                            final icon = 'https:${hour['condition']['icon']}';
                            final selected = i == selectedHourIndex;

                            return _HourTile(
                              time: time,
                              temp: temp,
                              iconUrl: icon,
                              selected: selected,
                              onTap: () => setState(() => selectedHourIndex = i),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Next Forecast',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),

                    ...forecast.skip(1).map((day) {
                      final date = DateTime.parse(day['date']);
                      final max = (day['day']['maxtemp_c'] as num).round();
                      final min = (day['day']['mintemp_c'] as num).round();
                      final icon = 'https:${day['day']['condition']['icon']}';

                      return _Frosted(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_weekdayFull(date.weekday),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                  Text(day['day']['condition']['text'],
                                      style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12.5)),
                                ],
                              ),
                              Row(
                                children: [
                                  Image.network(icon, width: 30),
                                  const SizedBox(width: 10),
                                  Text('$max°  $min°', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HourTile extends StatelessWidget {
  final String time;
  final int temp;
  final String iconUrl;
  final bool selected;
  final VoidCallback onTap;

  const _HourTile({
    required this.time,
    required this.temp,
    required this.iconUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: .18) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: Colors.white.withValues(alpha: .7), width: 1) : null,
      ),
      child: Column(
        children: [
          Text('$temp°C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Image.network(iconUrl, width: 28),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );

    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: base);
  }
}

class _Frosted extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _Frosted({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
