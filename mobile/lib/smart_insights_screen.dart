
import 'package:flutter/material.dart';
import 'api_service.dart';

class SmartInsightsScreen extends StatefulWidget {
  final String token;

  const SmartInsightsScreen({
    super.key,
    required this.token,
  });

  @override
  State<SmartInsightsScreen> createState() => _SmartInsightsScreenState();
}

class _SmartInsightsScreenState extends State<SmartInsightsScreen> {
  Map<String, dynamic>? insights;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadInsights();
  }

  Future<void> loadInsights() async {
    setState(() => loading = true);

    try {
      insights = await ApiService.getSmartInsights(widget.token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load insights: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  double calculateScore() {
    if (insights == null) return 0;

    final water = (insights!['water'] ?? 0).toDouble();
    final sleep = (insights!['sleep'] ?? 0).toDouble();
    final exercise = (insights!['exercise'] ?? 0).toDouble();

    final waterScore = (water / 2.5 * 30).clamp(0, 30);
    final sleepScore = (sleep / 8 * 35).clamp(0, 35);
    final exerciseScore = (exercise / 30 * 35).clamp(0, 35);

    return waterScore + sleepScore + exerciseScore;
  }

  String scoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 40) return 'Getting Started';
    return 'Needs Attention';
  }

  Color scoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget metricCard(
      String title,
      String value,
      String goal,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    goal,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = calculateScore();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('Smart Health Insights'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadInsights,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : insights == null
          ? const Center(child: Text('No insights available'))
          : RefreshIndicator(
        onRefresh: loadInsights,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Your Wellness Score',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 12,
                              backgroundColor:
                              Colors.grey.shade200,
                              color: scoreColor(score),
                            ),
                          ),
                          Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                score.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('/ 100'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      scoreLabel(score),
                      style: TextStyle(
                        color: scoreColor(score),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Daily Wellness Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            metricCard(
              'Hydration',
              '${insights!['water']} L',
              'Goal: 2.5 L',
              Icons.water_drop,
              Colors.blue,
            ),
            metricCard(
              'Sleep',
              '${insights!['sleep']} hours',
              'Goal: 8 hours',
              Icons.bedtime,
              Colors.indigo,
            ),
            metricCard(
              'Exercise',
              '${insights!['exercise']} minutes',
              'Goal: 30 minutes',
              Icons.fitness_center,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            const Text(
              'Personalized Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...(insights!['insights'] as List).map((insight) {
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.lightbulb,
                    color: Colors.orange,
                  ),
                  title: Text(insight.toString()),
                ),
              );
            }),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Records analyzed'),
                trailing: Text(
                  '${insights!['totalRecords']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
