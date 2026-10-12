import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color ink = Color(0xFF17213B);
  static const Color purple = Color(0xFF6558F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: purple,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 29),
                      ),
                      const SizedBox(width: 12),
                      const Text('SmartTasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(30)),
                        child: const Text('STAY FOCUSED', style: TextStyle(color: purple, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6558F5), Color(0xFF8D82FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(30)),
                          child: const Text('YOUR DAY, ORGANIZED', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Make room for\nwhat matters.', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text('Plan your tasks, build momentum, and celebrate every little win.', style: TextStyle(color: Colors.white.withOpacity(.88), height: 1.5, fontSize: 14)),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE8A3), size: 20),
                            const SizedBox(width: 8),
                            Text('One step at a time.', style: TextStyle(color: Colors.white.withOpacity(.95), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('A calmer way to get things done', style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Keep your tasks in one place and make progress at your own pace.', style: TextStyle(color: Color(0xFF7B8298), height: 1.5, fontSize: 14)),
                  const SizedBox(height: 22),
                  const _FeatureRow(icon: Icons.check_circle_outline_rounded, title: 'Stay on track', detail: 'See what needs your attention'),
                  const SizedBox(height: 15),
                  const _FeatureRow(icon: Icons.bolt_rounded, title: 'Build momentum', detail: 'Turn small steps into progress'),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Log in'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: Color(0xFFE3E5EF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Create an account', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(child: Text('SIMPLE PLANS. CLEAR PROGRESS.', style: TextStyle(color: Color(0xFF9AA0B2), fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: const Color(0xFF6558F5), size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF17213B), fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: Color(0xFF7B8298), fontSize: 12)),
        ])),
      ],
    );
  }
}
