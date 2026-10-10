
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;


  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();

  bool isLoading = false;

  Future<void> completeTask() async {
    setState(() => isLoading = true);

    try {
      await _apiService.completeTask(widget.task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task completed successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing task: $e')),
      );
    }
  }

  Future<void> editTask() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: widget.task),
      ),
    );

    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text(
            'This task will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => isLoading = true);

    try {
      await _apiService.deleteTask(widget.task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.status.toLowerCase() == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.task,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.subject,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),

            _InfoTile(
              icon: Icons.calendar_today,
              title: 'Deadline',
              value: task.deadline,
            ),
            _InfoTile(
              icon: Icons.priority_high,
              title: 'Priority',
              value: task.priority,
            ),
            _InfoTile(
              icon: Icons.timer_outlined,
              title: 'Days Remaining',
              value: '${task.calculatedDaysRemaining}',
            ),
            _InfoTile(
              icon: Icons.warning_amber_rounded,
              title: 'Urgency',
              value: task.urgency,
            ),
            _InfoTile(
              icon: Icons.check_circle_outline,
              title: 'Status',
              value: task.status,
            ),

            const SizedBox(height: 30),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isCompleted ? null : completeTask,
                  icon: const Icon(Icons.check),
                  label: Text(
                    isCompleted ? 'Completed' : 'Mark as Complete',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: editTask,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Task'),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: deleteTask,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Task'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
