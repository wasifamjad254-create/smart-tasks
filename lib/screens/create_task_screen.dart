import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await apiService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully!')),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;

      final message = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Could not create task. Please try again.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17213B);
    const muted = Color(0xFF7B8298);
    const purple = Color(0xFF6558F5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New task'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6558F5), Color(0xFF8D82FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_note_rounded, color: Colors.white, size: 34),
                      SizedBox(height: 16),
                      Text('One thing at a time.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      SizedBox(height: 7),
                      Text('Write down what you want to get done.', style: TextStyle(color: Color(0xFFEDEBFF), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Task title', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'e.g. Finish project proposal', prefixIcon: Icon(Icons.title_rounded)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a task title' : null,
                ),
                const SizedBox(height: 22),
                const Text('Description', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add a few details (optional)', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(17)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: purple),
                      SizedBox(width: 11),
                      Expanded(child: Text('Your new task will be saved as Pending. You can update its status later.', style: TextStyle(color: ink, height: 1.4, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveTask,
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded), SizedBox(width: 8), Text('Save task')]),
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
