
import 'package:flutter/material.dart';
import 'api_service.dart';

class MedicationScreen extends StatefulWidget {
  final String token;

  const MedicationScreen({
    super.key,
    required this.token,
  });

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<dynamic> medications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  Future<void> loadMedications() async {
    setState(() => loading = true);

    try {
      final result = await ApiService.getMedications(widget.token);
      final data = result['data'];

      if (result['statusCode'] == 200) {
        if (data is Map && data['medications'] is List) {
          medications = data['medications'];
        } else if (data is List) {
          medications = data;
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to load medications');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  int get activeCount {
    return medications.where((m) => m['isActive'] != false).length;
  }

  Future<void> showMedicationForm({Map? medication}) async {
    final nameController =
    TextEditingController(text: medication?['medicationName'] ?? '');
    final dosageController =
    TextEditingController(text: medication?['dosage'] ?? '');
    final instructionsController =
    TextEditingController(text: medication?['instructions'] ?? '');
    final notesController =
    TextEditingController(text: medication?['notes'] ?? '');
    final remindersController = TextEditingController(
      text: medication?['reminderTimes'] is List
          ? (medication!['reminderTimes'] as List).join(', ')
          : '',
    );

    String frequency = medication?['frequency'] ?? 'Daily';

    final startDateController = TextEditingController(
      text: medication?['startDate']?.toString().split('T')[0] ??
          DateTime.now().toIso8601String().split('T')[0],
    );

    final endDateController = TextEditingController(
      text: medication?['endDate']?.toString().split('T')[0] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                medication == null ? 'Add Medication' : 'Edit Medication',
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                      ),
                    ),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (e.g. 500 mg)',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                      ),
                      items: const [
                        'Daily',
                        'Twice daily',
                        'Three times daily',
                        'Weekly',
                        'As needed',
                        'Custom',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => frequency = value);
                        }
                      },
                    ),
                    TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'After food, before food, etc.',
                      ),
                    ),
                    TextField(
                      controller: remindersController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder times',
                        hintText: '09:00, 21:00',
                      ),
                    ),
                    TextField(
                      controller: startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start date (YYYY-MM-DD)',
                      ),
                    ),
                    TextField(
                      controller: endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End date (optional)',
                      ),
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        dosageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter medication name and dosage'),
                        ),
                      );
                      return;
                    }

                    final payload = {
                      'medicationName': nameController.text.trim(),
                      'dosage': dosageController.text.trim(),
                      'instructions': instructionsController.text.trim(),
                      'frequency': frequency,
                      'reminderTimes': remindersController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      'startDate': startDateController.text.trim(),
                      'endDate': endDateController.text.trim().isEmpty
                          ? null
                          : endDateController.text.trim(),
                      'isActive': true,
                      'notes': notesController.text.trim(),
                    };

                    Navigator.pop(context);

                    try {
                      Map<String, dynamic> result;

                      if (medication == null) {
                        result = await ApiService.addMedication(
                          token: widget.token,
                          medication: payload,
                        );
                      } else {
                        result = await ApiService.updateMedication(
                          token: widget.token,
                          id: medication['_id'].toString(),
                          medication: payload,
                        );
                      }

                      if (result['statusCode'] == 200 ||
                          result['statusCode'] == 201) {
                        await loadMedications();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                medication == null
                                    ? 'Medication added successfully!'
                                    : 'Medication updated successfully!',
                              ),
                            ),
                          );
                        }
                      } else {
                        throw Exception(
                          result['data']['message'] ?? 'Operation failed',
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteMedication(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: const Text(
          'Are you sure you want to delete this medication?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.deleteMedication(
        token: widget.token,
        id: id,
      );

      if (result['statusCode'] == 200) {
        await loadMedications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication deleted')),
          );
        }
      } else {
        throw Exception(result['data']['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('Medication'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadMedications,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        onPressed: () => showMedicationForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadMedications,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFE3F2E5),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medication,
                      size: 42,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Medications'),
                        Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (medications.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text('No medications added yet'),
                      Text('Tap + to add your medication'),
                    ],
                  ),
                ),
              ),
            ...medications.map((medication) {
              final reminders =
              medication['reminderTimes'] is List
                  ? (medication['reminderTimes'] as List).join(', ')
                  : 'No reminders';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2E5),
                    child: Icon(
                      Icons.medication,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  title: Text(
                    medication['medicationName'] ?? 'Medication',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Dosage: ${medication['dosage'] ?? '-'}\n'
                          'Frequency: ${medication['frequency'] ?? '-'}\n'
                          'Instructions: ${medication['instructions'] ?? '-'}\n'
                          'Reminders: $reminders',
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showMedicationForm(medication: medication);
                      } else if (value == 'delete') {
                        deleteMedication(
                          medication['_id'].toString(),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
