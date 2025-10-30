import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  final User user;

  const UserEditScreen({super.key, required this.user});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  late int _selectedRoleId;
  late bool _isActive;
  late bool _emailVerified;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _usernameController.text = widget.user.username;
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _selectedRoleId = widget.user.role.id;
    _isActive = widget.user.isActive;
    _emailVerified = widget.user.emailVerified;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());

      // Build update data
      final Map<String, dynamic> updateData = {
        'role_id': _selectedRoleId,
        'is_active': _isActive,
        'email_verified': _emailVerified,
      };

      // Add email if changed
      if (_emailController.text != widget.user.email) {
        updateData['email'] = _emailController.text;
      }

      // Add username if changed
      if (_usernameController.text != widget.user.username) {
        updateData['username'] = _usernameController.text;
      }

      // Add first_name if provided or changed
      if (_firstNameController.text.isNotEmpty) {
        updateData['first_name'] = _firstNameController.text;
      }

      // Add last_name if provided or changed
      if (_lastNameController.text.isNotEmpty) {
        updateData['last_name'] = _lastNameController.text;
      }

      // Add password if provided
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      await apiClient.updateUser(widget.user.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пользователь обновлен'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Редактирование пользователя'),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveUser,
                tooltip: 'Сохранить',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User basic info
                GlassCard(
                  child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация о пользователе',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Дата регистрации:',
                        _formatDate(widget.user.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('ID:', widget.user.id.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Credentials Section
              Text(
                'Учетные данные',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Email Field
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.email),
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
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Логин (username)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите логин';
                    }
                    if (value.length < 3 || value.length > 20) {
                      return 'Логин должен быть от 3 до 20 символов';
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
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Last Name Field
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль (необязательно)',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    helperText:
                        'Оставьте пустым, если не хотите менять пароль',
                  ),
                  obscureText: _obscurePassword,
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
              const SizedBox(height: 24),

              // Settings Section
              Text(
                'Настройки',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Role dropdown
              GlassCard(
                padding: EdgeInsets.zero,
                child: DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Роль',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem<int>(
                      value: 1,
                      child: Text('User (обычный пользователь)'),
                    ),
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text('Admin (администратор)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRoleId = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Active status switch
              SwitchListTile(
                title: const Text('Активен'),
                subtitle: Text(
                  _isActive
                      ? 'Пользователь может входить в систему'
                      : 'Пользователь заблокирован',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isActive ? Colors.green : Colors.red,
                  ),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.block,
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
              const Divider(),

              // Email verified switch
              SwitchListTile(
                title: const Text('Email подтвержден'),
                subtitle: Text(
                  _emailVerified
                      ? 'Email адрес подтвержден'
                      : 'Email адрес не подтвержден',
                  style: TextStyle(
                    fontSize: 12,
                    color: _emailVerified ? Colors.green : Colors.orange,
                  ),
                ),
                value: _emailVerified,
                onChanged: (value) {
                  setState(() {
                    _emailVerified = value;
                  });
                },
                secondary: Icon(
                  _emailVerified ? Icons.verified : Icons.warning,
                  color: _emailVerified ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),

              // Save button (large)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveUser,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text(
                    'Сохранить изменения',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
