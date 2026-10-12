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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );

          if (created == true) {
            fetchTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tasks',
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: fetchTasks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt, size: 64, color: Colors.indigo),
                  const SizedBox(height: 12),
                  const Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your tasks will appear here.'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: fetchTasks,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = Map<String, dynamic>.from(tasks[index] as Map);

                  final title = task['title']?.toString() ?? 'Untitled task';
                  final description = task['description']?.toString() ?? '';
                  final status = task['status']?.toString() ?? 'pending';

                  final isCompleted = status == 'completed';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : Colors.indigo,
                              child: Icon(
                                isCompleted ? Icons.check : Icons.task_alt,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(description),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: description.isNotEmpty,

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => editTask(task),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.indigo,
                                  ),
                                  tooltip: 'Edit task',
                                ),
                                IconButton(
                                  onPressed: () => confirmDeleteTask(task),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete task',
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Change status')),
                                DropdownButton<String>(
                                  value: status == 'completed'
                                      ? 'completed'
                                      : 'pending',
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text('Pending'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text('Completed'),
                                    ),
                                  ],
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      changeTaskStatus(task, newStatus);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
