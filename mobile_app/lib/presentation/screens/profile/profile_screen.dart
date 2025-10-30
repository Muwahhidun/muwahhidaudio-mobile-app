import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _emailController.text = user.email;
      _usernameController.text = user.username;
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите текущий пароль для подтверждения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if new password and confirmation match
    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Новые пароли не совпадают'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authProvider).user!;
      final profileUpdate = UserProfileUpdate(
        email: _emailController.text != user.email
            ? _emailController.text
            : null,
        username: _usernameController.text != user.username
            ? _usernameController.text
            : null,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
      );

      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(profileUpdate);

      if (!mounted) return;

      if (success) {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Неверный текущий пароль'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Профиль'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Header
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(user?.role.name ?? ''),
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              Text(
                'Email',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'your@email.com',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.email),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@')) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Username Field
              Text(
                'Имя пользователя',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'username',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.person),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя пользователя';
                    }
                    if (value.length < 3 || value.length > 20) {
                      return 'Имя пользователя должно быть от 3 до 20 символов';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Только латинские буквы, цифры и подчеркивание';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // First Name Field
              Text(
                'Имя',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    hintText: 'Имя (необязательно)',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.badge),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Last Name Field
              Text(
                'Фамилия',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    hintText: 'Фамилия (необязательно)',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.badge),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Section
              Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
              const SizedBox(height: 16),
              Text(
                'Изменить пароль',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Оставьте поля пустыми, если не хотите менять пароль',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),

              // New Password Field
              Text(
                'Новый пароль',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Новый пароль (необязательно)',
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureNewPassword,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 8) {
                        return 'Пароль должен быть минимум 8 символов';
                      }
                      if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                        return 'Пароль должен содержать хотя бы одну букву';
                      }
                      if (!RegExp(r'\d').hasMatch(value)) {
                        return 'Пароль должен содержать хотя бы одну цифру';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              Text(
                'Подтвердите новый пароль',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Подтвердите новый пароль',
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
              ),
              const SizedBox(height: 24),

              // Current Password Required
              Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
              const SizedBox(height: 16),
              Text(
                'Подтверждение',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите текущий пароль для подтверждения изменений',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),

              // Current Password Field
              Text(
                'Текущий пароль *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Введите текущий пароль',
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.security),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureCurrentPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите текущий пароль';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Сохранить изменения',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }
}
