# SmartTasks — Flutter Task Management App

SmartTasks is a mobile task management application built with Flutter and Laravel REST APIs. It allows users to create an account, log in, and manage their personal tasks through a clean mobile interface.

## Features

- **User Authentication:** Register, log in, and log out.
- **Task Management:** Create, view, edit, and delete tasks.
- **Task Status:** Update task status as work progresses.
- **REST API Integration:** Communicate with a Laravel backend using HTTP requests.
- **Database:** Store users and tasks using MySQL.
- **Secure API Access:** Use Laravel Sanctum for authenticated API requests.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application UI |
| Dart | Application programming language |
| Laravel | Backend REST API |
| MySQL | Database |
| Laravel Sanctum | API authentication |
| Dio | HTTP requests and API integration |

## Project Structure

```text
lib/
├── main.dart
├── screens/
│   ├── create_task_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── tasks_screen.dart
└── services/
    └── api_service.dart
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- PHP and Composer
- MySQL
- Laravel backend configured locally

### Run the Flutter App

1. Clone this repository.
2. Open the project folder in your terminal.
3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Configure the API base URL in `lib/services/api_service.dart` to point to your running Laravel backend.
5. Start the Flutter application:

   ```bash
   flutter run
   ```

### Backend Setup

The Laravel backend is maintained separately. Configure its environment variables, database connection, and API routes before running the mobile application.

## Learning Objectives

This project was developed to practice Flutter development, REST API integration, authentication, database-backed CRUD operations, and communication between a mobile frontend and a Laravel backend.

## Future Improvements

- Add automated tests.
- Improve error handling and loading states.
- Add task search and filtering.
- Prepare screenshots and a demo of the application.

---

**Developer:** Wasif Amjad Butt  
**Project:** SmartTasks — Flutter + Laravel REST API
