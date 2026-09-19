// lib/screens/task_result_screen.dart — Stub (redirected to /tasks)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class TaskResultScreen extends StatelessWidget {
  const TaskResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect handled by router; this is a fallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/tasks');
    });
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accentCyan),
      ),
    );
  }
}
