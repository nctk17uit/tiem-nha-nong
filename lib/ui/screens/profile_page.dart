import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final user = userState.value;
    final isGuest = user == null;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: userState.isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Avatar Section ---
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: isGuest
                          ? Colors.grey.shade200
                          : Colors.indigo.shade50,
                      child: Icon(
                        isGuest
                            ? Icons.account_circle_outlined
                            : Icons.verified_user,
                        size: 60,
                        color: isGuest ? Colors.grey : Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Conditional UI ---
                    if (isGuest) ...[
                      const Text(
                        "You are currently a Guest.",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Sign in to view your orders, points, and personal details.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text("Sign In"),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () => context.push('/login'),
                      ),
                    ] else ...[
                      // --- Logged In View ---
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Details Card
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.phone,
                                "Phone",
                                user.phoneNumber,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                Icons.badge,
                                "Role",
                                user.role.toUpperCase(),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                Icons.lock_outline,
                                "Status",
                                user.isLocked ? "Locked" : "Active",
                                valueColor: user.isLocked
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // Helper widget for the info rows
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
