import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  bool get _longEnough => _password.text.length >= 8;

  bool get _hasDigit => RegExp(r'\d').hasMatch(_password.text);

  bool get _hasSpecial => RegExp(r'[^a-zA-Z0-9]').hasMatch(_password.text);

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите имя и фамилию';
    }

    final words = text.split(RegExp(r'\s+'));

    if (words.length < 2) {
      return 'Введите имя и фамилию';
    }

    final wordPattern = RegExp(
      r"^[A-Za-zА-Яа-яЁё]+(?:[-'][A-Za-zА-Яа-яЁё]+)*$",
    );

    if (!words.every((word) => wordPattern.hasMatch(word))) {
      return 'Используйте буквы и дефис';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';

    if (!RegExp(r'^[a-zA-Z0-9_.-]{3,32}$').hasMatch(text)) {
      return 'От 3 до 32 символов: латиница, цифры, . _ -';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';

    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(text)) {
      return 'Введите корректный email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (!_longEnough || !_hasDigit || !_hasSpecial) {
      return 'Пароль должен соответствовать требованиям ниже';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<AuthNotifier>().register(
            username: _username.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            fullName: _fullName.text.trim(),
          );

      if (!mounted) return;

      context.go('/login?registered=true');
    } on ValidationException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.errors.isEmpty
            ? error.message
            : error.errors.values.join('\n');
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _passwordRule(String text, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF30232A);
    const deepPink = Color(0xFF8F4A68);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6DCE7),
        foregroundColor: darkText,
        title: const Text('Регистрация'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Создать аккаунт',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          labelText: 'Имя и фамилия',
                          hintText: 'Анна Иванова',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          hintText: 'anna_ivanova',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Электронная почта',
                          hintText: 'anna@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 15),

                      // 4. Пароль.
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscure = !_obscure;
                              });
                            },
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          setState(() {});
                        },
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 12),

                      _passwordRule(
                        'Не менее 8 символов',
                        _longEnough,
                      ),
                      _passwordRule(
                        'Хотя бы одна цифра',
                        _hasDigit,
                      ),
                      _passwordRule(
                        'Хотя бы один специальный символ',
                        _hasSpecial,
                      ),
                      const SizedBox(height: 13),

                      TextFormField(
                        controller: _repeatPassword,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Пароли не совпадают';
                          }

                          return null;
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: deepPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Зарегистрироваться'),
                      ),

                      TextButton(
                        onPressed: _busy ? null : () => context.go('/login'),
                        child: const Text(
                          'Уже есть аккаунт? Войти',
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Новый аккаунт получает роль «Посетитель». '
                        'Роль сотрудника приюта или администратора '
                        'назначается отдельно.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
