import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import 'add_task_screen.dart';
import 'study_plan_screen.dart';
import 'task_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  List<Task> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  bool isGeneratingPlan = false;
  String? studyPlan;
  String? plannerError;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await _apiService.getTasks();

      if (!mounted) return;

      setState(() {
        tasks = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  int get pendingCount => tasks.where((task) {
        return task.status.toLowerCase() != 'completed';
      }).length;

  int get completedCount => tasks.where((task) {
        return task.status.toLowerCase() == 'completed';
      }).length;

  int get urgentCount => tasks.where((task) {
        return task.status.toLowerCase() != 'completed' &&
            task.priority.toLowerCase() == 'high';
      }).length;

  Future<void> openAddTaskScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTaskScreen(),
      ),
    );

    if (mounted) {
      await loadTasks();
    }
  }

  Future<void> openTaskDetails(Task task) async {
  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => TaskDetailScreen(task: task),
    ),
  );

  if (updated == true && mounted) {
    await loadTasks();
  }
}

  Future<void> generateStudyPlan() async {
    setState(() {
      isGeneratingPlan = true;
      plannerError = null;
    });

    try {
      final result = await _apiService.generateDailyPlan();

      if (!mounted) return;

      setState(() {
        studyPlan = result;
        isGeneratingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGeneratingPlan = false;
        plannerError = 'Could not generate a study plan. Please try again.';
      });
    }
  }

  void openStudyPlan() {
    if (studyPlan == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyPlanScreen(plan: studyPlan!),
      ),
    );
  }

  Future<void> completeTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete task?'),
        content: const Text(
          'Are you sure you want to mark this task as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.completeTask(task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task marked as completed'),
        ),
      );

      await loadTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not complete task: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome),
            SizedBox(width: 10),
            Text(
              'StudyFlow',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your academic workspace',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stay organized, meet deadlines, and study smarter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: isLoading ? '—' : '$pendingCount',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: isLoading ? '—' : '$completedCount',
                    icon: Icons.task_alt,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'High priority',
                    value: isLoading ? '—' : '$urgentCount',
                    icon: Icons.priority_high,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // AI Study Planner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI Daily Study Planner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Let StudyFlow AI organize your study tasks '
                    'and recommend what to focus on today.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          isGeneratingPlan ? null : generateStudyPlan,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      icon: isGeneratingPlan
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isGeneratingPlan
                            ? 'Generating your plan...'
                            : studyPlan == null
                                ? 'Generate Study Plan'
                                : 'Regenerate Study Plan',
                      ),
                    ),
                  ),

                  if (plannerError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      plannerError!,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],

                  if (studyPlan != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your personalized study plan is ready.',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openStudyPlan,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Full Study Plan'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Tasks heading
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Tasks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: openAddTaskScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              _ErrorCard(
                message: errorMessage!,
                onRetry: loadTasks,
              )
            else if (tasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add your first academic task to get started.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: openAddTaskScreen,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Task'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.map(
                (task) => _TaskCard(
                  task: task,
                  onTap: () => openTaskDetails(task),
                  onComplete: () => completeTask(task),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddTaskScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  Color _priorityColor() {
    switch (task.priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status.toLowerCase() == 'completed';
    final priorityColor = _priorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isCompleted
                    ? Colors.green
                    : theme.colorScheme.primary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.task,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.subject,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.flag_outlined,
                          label: task.priority,
                          color: priorityColor,
                        ),
                        _InfoChip(
                          icon: Icons.event_outlined,
                          label: task.deadline,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                IconButton(
                  tooltip: 'Mark completed',
                  onPressed: onComplete,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            const Text(
              'Could not load tasks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}