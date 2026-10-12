import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio dio;

  ApiService()
    : dio = Dio(
        BaseOptions(
          baseUrl: 'http://192.168.100.22:8000/api',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  // Get saved authentication token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Create authorization headers
  Future<Options> _authOptions() async {
    final token = await _getToken();

    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  // Register
  Future<Response> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await dio.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );

    final token = response.data['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token.toString());
    }

    return response;
  }

  // Login
  Future<Response> login(String email, String password) async {
    final response = await dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token.toString());
    }

    return response;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      if (token != null) {
        await dio.post('/logout', options: await _authOptions());
      }
    } finally {
      // Clear the local token even if the API request fails.
      await prefs.remove('token');
    }
  }

  // Get Tasks
  Future<Response> getTasks() async {
    return await dio.get('/tasks', options: await _authOptions());
  }

  // Create Task
  Future<Response> createTask({
    required String title,
    required String description,
  }) async {
    return await dio.post(
      '/tasks',
      data: {'title': title, 'description': description, 'status': 'pending'},
      options: await _authOptions(),
    );
  }

  // Edit Task: title, description, and/or status
  Future<Response> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? status,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) {
      data['title'] = title;
    }

    if (description != null) {
      data['description'] = description;
    }

    if (status != null) {
      data['status'] = status;
    }

    if (data.isEmpty) {
      throw ArgumentError('Provide at least one field to update.');
    }

    return await dio.put(
      '/tasks/$taskId',
      data: data,
      options: await _authOptions(),
    );
  }

  // Update only the task status
  Future<Response> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    if (status != 'pending' && status != 'completed') {
      throw ArgumentError('Status must be pending or completed.');
    }

    return await updateTask(taskId: taskId, status: status);
  }

  Future<void> deleteTask({required int taskId}) async {
    final token = await _getToken();

    await dio.delete(
      '/tasks/$taskId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
