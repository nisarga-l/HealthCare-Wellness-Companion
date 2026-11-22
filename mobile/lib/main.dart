
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

const Color brand = Color(0xFF247C67);
const Color darkGreen = Color(0xFF164E43);
const Color backgroundColor = Color(0xFFF4F7F6);

void main() {
  runApp(const HealthMateApp());
}

class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brand),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: darkGreen,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FBFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCE6E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCE6E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brand, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return DashboardScreen(
            token: args['token'] as String,
            user: args['user'] is Map
                ? Map<String, dynamic>.from(args['user'])
                : <String, dynamic>{},
          );
        },
      },
    );
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD
// -----------------------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  bool loading = true;
  bool saving = false;
  bool profileLoading = true;

  List<Map<String, dynamic>> records = [];
  Map<String, dynamic> profile = {};

  String get userName =>
      (profile['name'] ?? widget.user['name'] ?? 'HealthMate User')
          .toString();

  String get userEmail =>
      (profile['email'] ?? widget.user['email'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadWellness(),
      loadProfile(),
    ]);

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> loadWellness() async {
    try {
      final List<dynamic> result =
      await ApiService.getWellness(widget.token);

      if (!mounted) return;

      setState(() {
        records = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        records.sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
      });
    } catch (e) {
      if (mounted) {
        _message('Could not load wellness records: $e');
      }
    }
  }

  Future<void> loadProfile() async {
    try {
      final result = await ApiService.getProfile(widget.token);

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        final data = result['data'];

        if (data is Map && data['user'] is Map) {
          setState(() {
            profile = Map<String, dynamic>.from(data['user']);
          });
        } else if (data is Map) {
          setState(() {
            profile = Map<String, dynamic>.from(data);
          });
        }
      }
    } catch (_) {
      // Use the user information already received during login.
    } finally {
      if (mounted) {
        setState(() {
          profileLoading = false;
        });
      }
    }
  }

  Future<void> addWellness({
    required String category,
    required double value,
    required String unit,
    required String notes,
  }) async {
    setState(() => saving = true);

    try {
      final result = await ApiService.addWellness(
        token: widget.token,
        category: category,
        value: value,
        unit: unit,
        notes: notes,
      );

      if (result['statusCode'] == 200 ||
          result['statusCode'] == 201) {
        await loadWellness();

        if (mounted) {
          _message('Wellness activity added successfully!');
        }
      } else {
        final data = result['data'];
        _message(
          data is Map
              ? (data['message'] ?? 'Could not save activity').toString()
              : 'Could not save activity',
        );
      }
    } catch (e) {
      _message('Connection error: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> updateWellness(
      Map<String, dynamic> record, {
        required double value,
        required String notes,
      }) async {
    try {
      final response = await ApiService.updateWellness(
        token: widget.token,
        id: record['_id'].toString(),
        category: record['category'].toString(),
        value: value,
        unit: (record['unit'] ?? '').toString(),
        notes: notes,
      );

      if (response['statusCode'] == 200) {
        await loadWellness();
        _message('Wellness activity updated.');
      } else {
        _message('Could not update activity.');
      }
    } catch (e) {
      _message('Update failed: $e');
    }
  }

  Future<void> deleteWellness(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: const Text(
          'Are you sure you want to permanently delete this wellness record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.deleteWellness(
        token: widget.token,
        id: record['_id'].toString(),
      );

      if (response['statusCode'] == 200) {
        await loadWellness();
        _message('Activity deleted.');
      } else {
        _message('Could not delete activity.');
      }
    } catch (e) {
      _message('Delete failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DATA HELPERS
  // ---------------------------------------------------------------------------

  DateTime _dateOf(Map<String, dynamic> record) {
    try {
      return DateTime.parse(record['date'].toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  bool _isToday(Map<String, dynamic> record) {
    final date = _dateOf(record);
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _valueOf(Map<String, dynamic> record) {
    final value = record['value'];

    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _total(String category, {bool todayOnly = false}) {
    return records
        .where((record) =>
    record['category'].toString().toLowerCase() == category &&
        (!todayOnly || _isToday(record)))
        .fold<double>(0, (sum, record) => sum + _valueOf(record));
  }

  int get todayEntries => records.where(_isToday).length;

  String _dateText(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _recordDate(Map<String, dynamic> record) {
    final date = _dateOf(record);
    return '${_dateText(date)} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // ADD ACTIVITY FORM
  // ---------------------------------------------------------------------------

  Future<void> _showAddActivityDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddActivityDialog(),
    );

    if (!mounted || result == null) return;

    await addWellness(
      category: result['category'] as String,
      value: result['value'] as double,
      unit: result['unit'] as String,
      notes: result['notes'] as String,
    );
  }

  // ---------------------------------------------------------------------------
  // EDIT ACTIVITY
  // ---------------------------------------------------------------------------

  Future<void> _showEditDialog(Map<String, dynamic> record) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditActivityDialog(
        initialValue: _valueOf(record).toString(),
        initialNotes: record['notes']?.toString() ?? '',
        unit: (record['unit'] ?? '').toString(),
      ),
    );

    if (!mounted || result == null) return;

    final value = double.tryParse(result['value'] ?? '');

    if (value == null || value <= 0) {
      _message('Enter a valid value greater than zero.');
      return;
    }

    await updateWellness(
      record,
      value: value,
      notes: result['notes'] ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // BMI CALCULATOR
  // ---------------------------------------------------------------------------

  void _showBmiCalculator() {
    showDialog<void>(
      context: context,
      builder: (_) => BmiCalculatorDialog(
        initialHeight: (profile['height'] ?? '').toString(),
        initialWeight: (profile['weight'] ?? '').toString(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN SCAFFOLD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      _progressPage(),
      _wellnessPage(),
      _notificationsPage(),
      _profilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: brand),
            SizedBox(width: 8),
            Text(
              'HealthMate',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadInitialData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => selectedIndex = 3),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadInitialData,
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      floatingActionButton: selectedIndex == 0 || selectedIndex == 2
          ? FloatingActionButton.extended(
        onPressed: saving ? null : _showAddActivityDialog,
        backgroundColor: brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wellness',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _page(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [child],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE WIDGETS
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF718078),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricCard(
      String title,
      String value,
      IconData icon,
      Color color, {
        String? subtitle,
      }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF718078),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF3EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your wellness matters!',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Small healthy habits make a big difference. '
                      'Keep moving towards a healthier you.',
                  style: TextStyle(
                    color: Color(0xFF4C6C62),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _showAddActivityDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add activity'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.health_and_safety,
            color: brand,
            size: 54,
          ),
        ],
      ),
    );
  }

  Widget _goalCard({
    required String title,
    required String amount,
    required String target,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    final percentage = (progress * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$amount / $target',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOME / DASHBOARD
  // ---------------------------------------------------------------------------

  Widget _homePage() {
    final waterToday = _total('water', todayOnly: true);
    final sleepToday = _total('sleep', todayOnly: true);
    final exerciseToday = _total('exercise', todayOnly: true);

    final waterProgress = waterToday / 2.5;
    final sleepProgress = sleepToday / 8;
    final exerciseProgress = exerciseToday / 30;

    final recentRecords = records.take(3).toList();

    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _dateText(DateTime.now()),
            style: const TextStyle(color: Color(0xFF718078)),
          ),
          const SizedBox(height: 18),
          _heroCard(),
          const SizedBox(height: 24),

          _sectionTitle(
            'Your Overview',
            subtitle: 'Your all-time wellness summary',
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _metricCard(
                'Water recorded',
                '${_total('water').toStringAsFixed(2)} L',
                Icons.water_drop,
                const Color(0xFF269BCB),
              ),
              _metricCard(
                'Sleep recorded',
                '${_total('sleep').toStringAsFixed(1)} hrs',
                Icons.bedtime,
                const Color(0xFF9875D0),
              ),
              _metricCard(
                'Exercise recorded',
                '${_total('exercise').round()} min',
                Icons.directions_run,
                const Color(0xFF299D75),
              ),
              _metricCard(
                'Total entries',
                '${records.length}',
                Icons.analytics_outlined,
                brand,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle(
            "Today's Wellness",
            subtitle: '$todayEntries activities recorded today',
          ),
          const SizedBox(height: 12),

          _goalCard(
            title: 'Water intake',
            amount: '${waterToday.toStringAsFixed(2)} L',
            target: '2.5 L',
            progress: waterProgress,
            icon: Icons.water_drop,
            color: const Color(0xFF269BCB),
          ),
          _goalCard(
            title: 'Sleep',
            amount: '${sleepToday.toStringAsFixed(1)} hrs',
            target: '8 hrs',
            progress: sleepProgress,
            icon: Icons.bedtime,
            color: const Color(0xFF9875D0),
          ),
          _goalCard(
            title: 'Exercise',
            amount: '${exerciseToday.round()} min',
            target: '30 min',
            progress: exerciseProgress,
            icon: Icons.directions_run,
            color: const Color(0xFF299D75),
          ),

          const SizedBox(height: 15),
          _sectionTitle(
            'Recent Wellness Records',
            subtitle: 'Your latest three activities',
          ),
          const SizedBox(height: 10),

          if (recentRecords.isEmpty)
            _emptyState(
              'No activities yet',
              'Add your first wellness activity to get started.',
              Icons.favorite_border,
            )
          else
            ...recentRecords.map(_recordCard),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => selectedIndex = 2),
              icon: const Icon(Icons.list_alt),
              label: const Text('View all wellness records'),
            ),
          ),

          if (saving) ...[
            const SizedBox(height: 15),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS
  // ---------------------------------------------------------------------------

  Widget _progressPage() {
    final days = List.generate(
      7,
          (index) => DateTime.now().subtract(
        Duration(days: 6 - index),
      ),
    );

    final values = days.map((day) {
      return records.where((record) {
        final date = _dateOf(record);

        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).length.toDouble();
    }).toList();

    final maxValue = values.fold<double>(
      1,
          (previous, value) => previous > value ? previous : value,
    );

    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Your Progress',
            subtitle: 'Track your wellness journey',
          ),
          const SizedBox(height: 18),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _metricCard(
                'Total entries',
                '${records.length}',
                Icons.analytics,
                brand,
              ),
              _metricCard(
                'Water',
                '${_total('water').toStringAsFixed(2)} L',
                Icons.water_drop,
                const Color(0xFF269BCB),
              ),
              _metricCard(
                'Sleep',
                '${_total('sleep').toStringAsFixed(1)} hrs',
                Icons.bedtime,
                const Color(0xFF9875D0),
              ),
              _metricCard(
                'Exercise',
                '${_total('exercise').round()} min',
                Icons.directions_run,
                const Color(0xFF299D75),
              ),
            ],
          ),

          const SizedBox(height: 25),
          _sectionTitle(
            'Daily Activity',
            subtitle: 'Number of wellness records over the last 7 days',
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final barHeight =
                    values[index] == 0 ? 4.0 : 115 * values[index] / maxValue;

                    return Column(
                      children: [
                        Text(
                          values[index].round().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 25,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: brand,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${days[index].day}/${days[index].month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          _sectionTitle(
            'All Wellness Records',
            subtitle: '${records.length} total activities',
          ),
          const SizedBox(height: 10),

          if (records.isEmpty)
            _emptyState(
              'No progress data',
              'Your wellness records will appear here.',
              Icons.show_chart,
            )
          else
            ...records.map(_recordCard),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WELLNESS RECORDS
  // ---------------------------------------------------------------------------

  Widget _wellnessPage() {
    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'My Wellness',
            subtitle: 'View, edit and delete your saved activities',
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF3EB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: brand, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have ${records.length} wellness records. '
                        'Keep tracking your daily habits!',
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          if (records.isEmpty)
            _emptyState(
              'No wellness records',
              'Use the Add Activity button to record your first activity.',
              Icons.favorite_border,
            )
          else
            ...records.map(
                  (record) => _recordCard(
                record,
                showActions: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _recordCard(
      Map<String, dynamic> record, {
        bool showActions = false,
      }) {
    final category = record['category']?.toString().toLowerCase() ?? '';
    final icon = category == 'water'
        ? Icons.water_drop
        : category == 'sleep'
        ? Icons.bedtime
        : Icons.directions_run;

    final color = category == 'water'
        ? const Color(0xFF269BCB)
        : category == 'sleep'
        ? const Color(0xFF9875D0)
        : const Color(0xFF299D75);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.isEmpty ? 'Activity' : category[0].toUpperCase() + category.substring(1)} • ${_valueOf(record)} ${record['unit'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recordDate(record),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if ((record['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record['notes'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showActions)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(record);
                } else if (value == 'delete') {
                  deleteWellness(record);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Widget _notificationsPage() {
    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Notifications',
            subtitle: 'Helpful reminders for a healthier lifestyle',
          ),
          const SizedBox(height: 18),

          _notice(
            Icons.water_drop,
            'Stay hydrated',
            'Remember to drink water regularly throughout the day. '
                'Your daily water goal is 2.5 litres.',
            const Color(0xFF269BCB),
          ),
          _notice(
            Icons.bedtime,
            'Healthy sleep',
            'Try to maintain a consistent sleep schedule and aim for '
                'around 8 hours of sleep.',
            const Color(0xFF9875D0),
          ),
          _notice(
            Icons.directions_walk,
            'Keep moving',
            'Take short movement breaks during long study or work sessions. '
                'Aim for 30 minutes of exercise.',
            const Color(0xFF299D75),
          ),
          _notice(
            Icons.favorite,
            'Daily check-in',
            'Update your wellness activities regularly to monitor your '
                'progress and build healthy habits.',
            brand,
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These are in-app wellness tips. Push notifications '
                        'are not configured in this version.',
                    style: TextStyle(
                      color: Color(0xFF80612B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(
      IconData icon,
      String title,
      String body,
      Color color,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF718078),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE
  // ---------------------------------------------------------------------------

  Widget _profilePage() {
    final age = profile['age'] ?? widget.user['age'];
    final gender = profile['gender'] ?? widget.user['gender'];
    final height = profile['height'] ?? widget.user['height'];
    final weight = profile['weight'] ?? widget.user['weight'];
    final targetWeight =
        profile['targetWeight'] ?? widget.user['targetWeight'];
    final goal = profile['goal'] ?? widget.user['goal'];

    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'My Profile',
            subtitle: 'Your personal and health information',
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFE5F3F1),
                  child: Icon(
                    Icons.person,
                    size: 43,
                    color: brand,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'HealthMate member',
                  style: TextStyle(
                    color: brand,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _sectionTitle('Personal Information'),
          const SizedBox(height: 10),

          _profileInfo('Full name', userName, Icons.person_outline),
          _profileInfo('Email address', userEmail, Icons.email_outlined),
          _profileInfo(
            'Age',
            age == null ? 'Not provided' : '$age years',
            Icons.cake_outlined,
          ),
          _profileInfo(
            'Gender',
            gender?.toString().isNotEmpty == true
                ? gender.toString()
                : 'Not provided',
            Icons.people_outline,
          ),

          const SizedBox(height: 20),
          _sectionTitle('Health Information'),
          const SizedBox(height: 10),

          _profileInfo(
            'Height',
            height == null ? 'Not provided' : '$height cm',
            Icons.height,
          ),
          _profileInfo(
            'Current weight',
            weight == null ? 'Not provided' : '$weight kg',
            Icons.monitor_weight_outlined,
          ),
          _profileInfo(
            'Target weight',
            targetWeight == null ? 'Not provided' : '$targetWeight kg',
            Icons.flag_outlined,
          ),
          _profileInfo(
            'Health goal',
            goal?.toString().isNotEmpty == true
                ? goal.toString()
                : 'Not provided',
            Icons.track_changes,
          ),

          const SizedBox(height: 20),
          _sectionTitle('Wellness Summary'),
          const SizedBox(height: 10),

          _metricCard(
            'Total records',
            '${records.length}',
            Icons.analytics,
            brand,
          ),
          const SizedBox(height: 10),
          _metricCard(
            'Water recorded',
            '${_total('water').toStringAsFixed(2)} litres',
            Icons.water_drop,
            const Color(0xFF269BCB),
          ),
          const SizedBox(height: 10),
          _metricCard(
            'Sleep recorded',
            '${_total('sleep').toStringAsFixed(1)} hours',
            Icons.bedtime,
            const Color(0xFF9875D0),
          ),
          const SizedBox(height: 10),
          _metricCard(
            'Exercise recorded',
            '${_total('exercise').round()} minutes',
            Icons.directions_run,
            const Color(0xFF299D75),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showBmiCalculator,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate BMI'),
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh profile'),
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),

          if (profileLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _profileInfo(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: brand, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF718078),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _emptyState(
      String title,
      String message,
      IconData icon,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// ADD ACTIVITY DIALOG
// Controllers belong to this State object. Flutter disposes them only after
// the dialog route has finished its closing animation.
// -----------------------------------------------------------------------------

class AddActivityDialog extends StatefulWidget {
  const AddActivityDialog({super.key});

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final TextEditingController valueController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String category = 'water';
  String unit = 'litres';

  @override
  void dispose() {
    valueController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void save() {
    final value = double.tryParse(valueController.text.trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid value greater than zero.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'category': category,
      'unit': unit,
      'value': value,
      'notes': notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Wellness Activity',
        style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'water', child: Text('Water')),
                DropdownMenuItem(value: 'sleep', child: Text('Sleep')),
                DropdownMenuItem(value: 'exercise', child: Text('Exercise')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  category = value;
                  unit = value == 'water'
                      ? 'litres'
                      : value == 'sleep'
                      ? 'hours'
                      : 'minutes';
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Value'),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter $unit',
                suffixText: unit,
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notes'),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write a note (optional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save activity'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EDIT ACTIVITY DIALOG
// -----------------------------------------------------------------------------

class EditActivityDialog extends StatefulWidget {
  final String initialValue;
  final String initialNotes;
  final String unit;

  const EditActivityDialog({
    super.key,
    required this.initialValue,
    required this.initialNotes,
    required this.unit,
  });

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  late final TextEditingController valueController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    valueController = TextEditingController(text: widget.initialValue);
    notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    valueController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit wellness activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Value (${widget.unit})'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'value': valueController.text.trim(),
            'notes': notesController.text.trim(),
          }),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BMI CALCULATOR DIALOG
// -----------------------------------------------------------------------------

class BmiCalculatorDialog extends StatefulWidget {
  final String initialHeight;
  final String initialWeight;

  const BmiCalculatorDialog({
    super.key,
    required this.initialHeight,
    required this.initialWeight,
  });

  @override
  State<BmiCalculatorDialog> createState() => _BmiCalculatorDialogState();
}

class _BmiCalculatorDialogState extends State<BmiCalculatorDialog> {
  late final TextEditingController heightController;
  late final TextEditingController weightController;
  double? bmi;
  String category = '';

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController(text: widget.initialHeight);
    weightController = TextEditingController(text: widget.initialWeight);
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void calculate() {
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      setState(() {
        bmi = null;
        category = '';
      });
      return;
    }

    final heightMetres = height / 100;
    final result = weight / (heightMetres * heightMetres);

    setState(() {
      bmi = result;
      if (result < 18.5) {
        category = 'Underweight';
      } else if (result < 25) {
        category = 'Normal weight';
      } else if (result < 30) {
        category = 'Overweight';
      } else {
        category = 'Obesity';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('BMI Calculator'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: calculate,
                child: const Text('Calculate BMI'),
              ),
            ),
            if (bmi != null) ...[
              const SizedBox(height: 20),
              const Text('Your BMI', style: TextStyle(color: Colors.grey)),
              Text(
                bmi!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: brand,
                ),
              ),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Adult BMI categories: below 18.5 Underweight, '
                  '18.5–24.9 Normal, 25–29.9 Overweight, '
                  '30 or above Obesity.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'BMI is a screening measure, not a diagnosis. '
                  'Interpretation may differ for children, teenagers, '
                  'pregnant people and some athletes.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
