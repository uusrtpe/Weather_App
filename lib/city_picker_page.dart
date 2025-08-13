// city_picker_page.dart — Global arama + ortada şehir, altında sıcaklık & ikon
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CityPickerPage extends StatefulWidget {
  const CityPickerPage({super.key});

  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  static const String _apiKey = '1a82d9fa4d5b4b9e8d1120003252807';

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _error = '';

  static const List<String> _suggested = [
    'Berlin','London','Paris','New York','Istanbul','Tokyo',
    'Los Angeles','Vienna','Rome','Barcelona','Dubai','Seoul'
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      q = q.trim();
      if (q.length < 2) {
        setState(() {
          _results = [];
          _loading = false;
          _error = '';
        });
      } else {
        _searchCities(q);
      }
    });
  }

  Future<void> _searchCities(String q) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final url = Uri.parse(
          'https://api.weatherapi.com/v1/search.json?key=$_apiKey&q=$q');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final list = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _results = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Arama başarısız: ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ağ hatası: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final showingResults = _controller.text.trim().length >= 2;

    // Grid item'ları: {label, query}
    final items = showingResults
        ? _results
        .map((m) => {
      'label': '${m['name']}, ${m['country']}',
      'query': '${m['name']}, ${m['country']}',
    })
        .toList()
        : _suggested.map((s) => {'label': s, 'query': s}).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF48A5F4), Color(0xFF90CAF9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weather',
                    style: TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search city',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: .85)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_loading) ...[
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                ] else if (_error.isNotEmpty && showingResults) ...[
                  Text(_error, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.35,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (context, i) {
                      final label = items[i]['label']!;
                      final query = items[i]['query']!;
                      return _CityCenteredTile(
                        label: label,
                        query: query,
                        apiKey: _apiKey,
                        onTap: () => Navigator.pop(context, query),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CityCenteredTile extends StatelessWidget {
  final String label; // ekranda görünecek (Berlin, Germany / Berlin)
  final String query; // API'ye gidecek q
  final String apiKey;
  final VoidCallback onTap;

  const _CityCenteredTile({
    required this.label,
    required this.query,
    required this.apiKey,
    required this.onTap,
  });

  Future<Map<String, dynamic>?> _fetchCurrent(String q) async {
    try {
      final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$q&aqi=no',
      );
      final r = await http.get(url);
      if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchCurrent(query),
          builder: (context, snap) {
            String? temp;
            String? iconUrl;
            if (snap.hasData && snap.data != null) {
              final current = snap.data!['current'];
              temp = '${(current['temp_c'] as num).round()}°C';
              iconUrl = 'https:${current['condition']['icon']}';
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Şehir adı
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (temp != null && iconUrl != null) ...[
                    Text(
                      temp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Image.network(iconUrl, width: 30, height: 30),
                  ] else ...[
                    // Yüklenirken küçük placeholder
                    Container(
                      width: 44,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
