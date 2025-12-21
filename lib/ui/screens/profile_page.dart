import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final user = userState.value;
    final isGuest = user == null;

    if (userState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isGuest) {
      return _buildLoginPrompt(context);
    }

    return _buildAuthenticatedProfile(context, ref, user);
  }

  // --- 1. GUEST VIEW ---
  Widget _buildLoginPrompt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: 0.06,
                  child: Icon(
                    Icons.person_outline,
                    size: MediaQuery.of(context).size.width * 0.9,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 72, color: Colors.grey[700]),
                    const SizedBox(height: 18),
                    Text(
                      'Đăng nhập để tiếp tục',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đăng nhập để xem đơn hàng, địa chỉ và các quyền lợi cá nhân của bạn.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => context.push('/login'),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Về trang chủ',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. AUTHENTICATED VIEW ---
  Widget _buildAuthenticatedProfile(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      color: colorScheme.primary,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildOfflineAvatar(user.name),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // EDIT INFO BUTTON
                              GestureDetector(
                                onTap: () {
                                  context.push('/profile/update-info');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Sửa hồ sơ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- PERSONAL INFO (Fixed Duplication) ---
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // 1. Phone Number (Replaces Duplicate Email)
                                ListTile(
                                  leading: const Icon(
                                    Icons.phone_android,
                                    color: Colors.grey,
                                  ),
                                  title: const Text(
                                    'Số điện thoại',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    (user.phoneNumber != null &&
                                            user.phoneNumber!.isNotEmpty)
                                        ? user.phoneNumber!
                                        : 'Chưa cập nhật',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  dense: true,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // 2. Change Password Link
                                ListTile(
                                  leading: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey,
                                  ),
                                  title: const Text(
                                    'Mật khẩu',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  subtitle: const Text(
                                    '*********',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  dense: true,
                                  onTap: () {
                                    context.push('/profile/change-password');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- SHOPPING INFO GRID ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin mua sắm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildShoppingInfoCard(
                                'Đơn hàng',
                                Icons.shopping_bag_outlined,
                                onTap: () {
                                  context.push('/orders');
                                },
                              ),
                              _buildShoppingInfoCard(
                                'Địa chỉ',
                                Icons.location_on_outlined,
                                onTap: () {
                                  context.push('/addresses');
                                },
                              ),
                              _buildShoppingInfoCard(
                                'Yêu thích',
                                Icons.favorite_outline,
                              ),
                              _buildShoppingInfoCard(
                                'Hỗ trợ',
                                Icons.help_outline,
                                onTap: () {
                                  context.push('/support');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- LOGOUT BUTTON ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  // UPDATE: Added onTap parameter
  Widget _buildShoppingInfoCard(
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Hook up the callback
        behavior: HitTestBehavior.opaque, // Ensure tap target is good
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.green[700], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineAvatar(String name) {
    return Container(
      color: _getAvatarColor(name),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return "${nameParts.first[0]}${nameParts.last[0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.brown,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
