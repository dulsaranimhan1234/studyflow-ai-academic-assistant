
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _taskController = TextEditingController();
  final _deadlineController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _priority = 'Medium';
  bool _isSaving = false;

  @override
  void dispose() {
    _studentController.dispose();
    _subjectController.dispose();
    _taskController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: _deadlineController.text.isNotEmpty
          ? DateTime.parse(_deadlineController.text)
          : today,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );

    if (selected != null && mounted) {
      setState(() {
        _deadlineController.text =
            '${selected.year.toString().padLeft(4, '0')}-'
            '${selected.month.toString().padLeft(2, '0')}-'
            '${selected.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _apiService.createTask(
        student: _studentController.text.trim(),
        subject: _subjectController.text.trim(),
        task: _taskController.text.trim(),
        deadline: _deadlineController.text,
        priority: _priority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task creation request sent')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Create an academic task',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Enter the task details below.'),
            const SizedBox(height: 24),

            TextFormField(
              controller: _studentController,
              decoration: const InputDecoration(
                labelText: 'Student',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the student name'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a subject'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'e.g. Complete assignment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a task title'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              onTap: _selectDeadline,
              decoration: const InputDecoration(
                labelText: 'Deadline',
                hintText: 'Select a date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.date_range),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Select a deadline'
                  : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveTask,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSaving ? 'Saving...' : 'Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
