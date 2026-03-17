import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BeProudApp());
}

class BeProudApp extends StatelessWidget {
  const BeProudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Be Proud',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090B14),
      ),
      home: const DiscoveryScreen(),
    );
  }
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.distanceKm,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }

  final int id;
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final double distanceKm;
}

class AssistantSuggestion {
  const AssistantSuggestion({
    required this.venue,
    required this.category,
    required this.direction,
  });

  factory AssistantSuggestion.fromJson(Map<String, dynamic> json) {
    return AssistantSuggestion(
      venue: json['venue'] as String,
      category: json['category'] as String,
      direction: json['direction'] as String,
    );
  }

  final String venue;
  final String category;
  final String direction;
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<Venue>> fetchVenues({String query = ''}) async {
    final response = await http.get(Uri.parse('$baseUrl/venues/?query=$query'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch venues');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['results'] as List<dynamic>)
        .map((e) => Venue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<(String, List<AssistantSuggestion>)> askAssistant(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'latitude': 6.5244,
        'longitude': 3.3792,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Assistant unavailable');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = (payload['suggestions'] as List<dynamic>)
        .map((e) => AssistantSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    return (payload['reply'] as String, suggestions);
  }
}

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _assistantController = TextEditingController();

  List<Venue> _venues = const [];
  List<AssistantSuggestion> _suggestions = const [];
  String _assistantReply =
      'Hi! Ask me anything like: “Find a calm café nearby with parking.”';
  bool _loading = true;
  bool _assistantLoading = false;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues({String query = ''}) async {
    setState(() => _loading = true);
    try {
      final venues = await _apiService.fetchVenues(query: query);
      setState(() => _venues = venues);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load venues. Check backend.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _askAssistant() async {
    final prompt = _assistantController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _assistantLoading = true);
    try {
      final (reply, suggestions) = await _apiService.askAssistant(prompt);
      setState(() {
        _assistantReply = reply;
        _suggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistant is unreachable right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _assistantLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildTabs(),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _tabIndex,
                        children: [
                          _buildVenueList(),
                          _buildMapAndSquares(),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _buildAssistant(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C5CFF), Color(0xFF00D8D6)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.explore_rounded),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Be Proud',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text('Discover nearby vibes with AI + immersive preview'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _queryController,
      onSubmitted: (value) => _fetchVenues(query: value),
      decoration: InputDecoration(
        hintText: 'Search restaurants, lounges, billiard halls, cafés...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: () => _fetchVenues(query: _queryController.text.trim()),
          icon: const Icon(Icons.tune_rounded),
        ),
        filled: true,
        fillColor: const Color(0xFF151B2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _tabButton(0, 'List', Icons.view_list_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _tabButton(1, 'Map + 3D', Icons.map_rounded)),
      ],
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final selected = _tabIndex == index;
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFF7C5CFF) : const Color(0xFF1A223A),
      ),
      onPressed: () => setState(() => _tabIndex = index),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildVenueList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111729),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: _venues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final venue = _venues[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2340),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  venue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(venue.category.toUpperCase())),
                    Text(
                      '${venue.distanceKm.toStringAsFixed(1)} km · ⭐ ${venue.rating.toStringAsFixed(1)}',
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapAndSquares() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1628),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive map placeholder + square 3D blocks',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF132238), Color(0xFF0A1020)],
                ),
              ),
              child: CustomPaint(painter: SquareCityPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistant() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12192B),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(_assistantReply),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._suggestions.map(
              (item) => Text('• ${item.venue} (${item.category}): ${item.direction}'),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _assistantController,
                  decoration: const InputDecoration(
                    hintText: 'Try: find a lively lounge with good music',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _assistantLoading ? null : _askAssistant,
                icon: _assistantLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: const Text('Ask'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SquareCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D1B2A),
    );

    final random = math.Random(8);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * (size.width - 48);
      final y = random.nextDouble() * (size.height - 60);
      final block = 18 + random.nextDouble() * 26;
      final levels = 1 + random.nextInt(4);

      for (int level = 0; level < levels; level++) {
        final rect = Rect.fromLTWH(x - level * 2.8, y - level * 6, block, block);
        final color = Color.lerp(
          const Color(0xFF7C5CFF),
          const Color(0xFF00D8D6),
          level / (levels + 0.5),
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = (color ?? Colors.white).withValues(alpha: 0.86),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
