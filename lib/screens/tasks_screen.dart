import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ApiService apiService = ApiService();

  List<dynamic> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await apiService.getTasks();
      debugPrint('TASK API RESPONSE: ${response.data}');

      final data = response.data;

      final taskList = data is List
          ? data
          : data is Map && data['tasks'] is List
          ? data['tasks'] as List
          : data is Map && data['data'] is List
          ? data['data'] as List
          : <dynamic>[];

      if (!mounted) return;

      setState(() {
        tasks = taskList;
        isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.response?.statusCode == 401
            ? 'Your session has expired. Please log in again.'
            : 'Could not load tasks. Check your connection and try again.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Something went wrong: $e';
      });
    }
  }

  Future<void> logout() async {
    try {
      await apiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  // Edit task title and description
  Future<void> editTask(Map<String, dynamic> task) async {
    final id = int.tryParse(task['id'].toString());

    if (id == null) {
      showMessage('Invalid task ID.');
      return;
    }

    final titleController = TextEditingController(
      text: task['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: task['description']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(dialogContext, true);
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

    if (shouldSave != true) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    try {
      await apiService.updateTask(
        taskId: id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
      );

      titleController.dispose();
      descriptionController.dispose();

      if (!mounted) return;

      showMessage('Task updated successfully!');
      await fetchTasks();
    } on DioException catch (e) {
      titleController.dispose();
      descriptionController.dispose();

      if (!mounted) return;

      final message = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;

      showMessage(message ?? 'Could not update task.');
    } catch (e) {
      titleController.dispose();
      descriptionController.dispose();

      if (!mounted) return;

      showMessage('Something went wrong: $e');
    }
  }

  Future<void> confirmDeleteTask(Map<String, dynamic> task) async {
    final id = int.tryParse(task['id'].toString());

    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid task ID')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await apiService.deleteTask(taskId: id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );

      await fetchTasks();
    } on DioException catch (e) {
      if (!mounted) return;

      final message = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Failed to delete task')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
  }

  // Change task status
  Future<void> changeTaskStatus(
    Map<String, dynamic> task,
    String newStatus,
  ) async {
    final id = int.tryParse(task['id'].toString());

    if (id == null) {
      showMessage('Invalid task ID.');
      return;
    }

    final oldStatus = task['status']?.toString() ?? 'pending';

    if (oldStatus == newStatus) return;

    try {
      await apiService.updateTaskStatus(taskId: id, status: newStatus);

      if (!mounted) return;

      showMessage(
        newStatus == 'completed'
            ? 'Task marked as completed!'
            : 'Task marked as pending.',
      );

      await fetchTasks();
    } on DioException catch (e) {
      if (!mounted) return;

      final message = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;

      showMessage(message ?? 'Could not update task status.');
    } catch (e) {
      if (!mounted) return;

      showMessage('Something went wrong: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17213B);
    const muted = Color(0xFF7B8298);
    const purple = Color(0xFF6558F5);
    const green = Color(0xFF1E9D78);
    const orange = Color(0xFFE99B36);

    final completedCount = tasks.where((task) => task is Map && task['status'] == 'completed').length;
    final pendingCount = tasks.length - completedCount;
    final visibleTasks = tasks.where((rawTask) {
      if (rawTask is! Map) return false;
      final status = rawTask['status']?.toString() ?? 'pending';
      if (selectedFilter == 'Pending') return status != 'completed';
      if (selectedFilter == 'Completed') return status == 'completed';
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
          if (created == true) fetchTasks();
        },
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchTasks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SMARTTASKS', style: TextStyle(color: purple, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            const Text('My tasks', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                            const SizedBox(height: 4),
                            const Text('Small steps make big progress.', style: TextStyle(color: muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh tasks',
                        onPressed: fetchTasks,
                        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ink),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: logout,
                        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ink),
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 15, 22, 22),
                  child: Container(
                    padding: const EdgeInsets.all(21),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6558F5), Color(0xFF8D82FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(completedCount == tasks.length && tasks.isNotEmpty ? 'Amazing work!' : 'Let’s make today count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE8A3), size: 23),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tasks.isEmpty ? 'Add your first task and start building momentum.' : '$completedCount of ${tasks.length} tasks completed. Keep going!',
                          style: TextStyle(color: Colors.white.withOpacity(.88), fontSize: 13, height: 1.45),
                        ),
                        const SizedBox(height: 17),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: tasks.isEmpty ? 0 : completedCount / tasks.length,
                            backgroundColor: Colors.white.withOpacity(.24),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE8A3)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(tasks.isEmpty ? '0% complete' : '${((completedCount / tasks.length) * 100).round()}% complete', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('All tasks', tasks.length.toString(), Icons.grid_view_rounded, const Color(0xFFEFEDFF), purple)),
                      const SizedBox(width: 11),
                      Expanded(child: _buildStatCard('Pending', pendingCount.toString(), Icons.schedule_rounded, const Color(0xFFFFF3DF), orange)),
                      const SizedBox(width: 11),
                      Expanded(child: _buildStatCard('Done', completedCount.toString(), Icons.check_circle_outline_rounded, const Color(0xFFE4F7F0), green)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 27, 22, 13),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Your list', style: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800))),
                      Text('${visibleTasks.length} items', style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: ['All', 'Pending', 'Completed'].map((filter) {
                      final selected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          onSelected: (_) => setState(() => selectedFilter = filter),
                          showCheckmark: false,
                          selectedColor: purple,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: selected ? Colors.white : muted, fontWeight: FontWeight.w700, fontSize: 12),
                          side: BorderSide(color: selected ? purple : const Color(0xFFE8EAF2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFE05260)),
                          const SizedBox(height: 12),
                          Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.4)),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(onPressed: fetchTasks, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
                        ],
                      ),
                    ),
                  ),
                )
              else if (visibleTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 12, 30, 100),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(color: const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(25)),
                            child: const Icon(Icons.checklist_rounded, color: purple, size: 39),
                          ),
                          const SizedBox(height: 17),
                          Text(tasks.isEmpty ? 'A fresh start' : 'Nothing in this filter', style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 7),
                          Text(tasks.isEmpty ? 'Add your first task to see it here.' : 'Try another filter to see more tasks.', textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.45)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 105),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = Map<String, dynamic>.from(visibleTasks[index] as Map);
                        return _buildTaskCard(task);
                      },
                      childCount: visibleTasks.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color tint, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEFF0F6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 18)),
          const SizedBox(height: 13),
          Text(value, style: const TextStyle(color: Color(0xFF17213B), fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF7B8298), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    const ink = Color(0xFF17213B);
    const muted = Color(0xFF7B8298);
    const purple = Color(0xFF6558F5);
    const green = Color(0xFF1E9D78);
    final title = task['title']?.toString() ?? 'Untitled task';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'pending';
    final isCompleted = status == 'completed';
    final accent = isCompleted ? green : purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(15, 15, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFF0F6)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: isCompleted ? const Color(0xFFE4F7F0) : const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(14)),
                child: Icon(isCompleted ? Icons.check_rounded : Icons.pending_actions_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800, decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none)),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: isCompleted ? const Color(0xFFE4F7F0) : const Color(0xFFFFF3DF), borderRadius: BorderRadius.circular(30)),
                        child: Text(isCompleted ? 'COMPLETED' : 'PENDING', style: TextStyle(color: isCompleted ? green : const Color(0xFFB77716), fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Task options',
                icon: const Icon(Icons.more_horiz_rounded, color: muted),
                onSelected: (value) {
                  if (value == 'edit') editTask(task);
                  if (value == 'delete') confirmDeleteTask(task);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 19), SizedBox(width: 10), Text('Edit task')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Color(0xFFE05260), size: 19), SizedBox(width: 10), Text('Delete task')])) ,
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFF0F1F6)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, size: 17, color: muted),
              const SizedBox(width: 7),
              const Expanded(child: Text('Update status', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isCompleted ? 'completed' : 'pending',
                  borderRadius: BorderRadius.circular(14),
                  style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null) changeTaskStatus(task, newStatus);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
