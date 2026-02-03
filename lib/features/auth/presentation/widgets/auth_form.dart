import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/helpers.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final bool isLoading;
  final String? errorMessage;
  final void Function(String email, String password, String? displayName) onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback? onForgotPassword;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.isLoading,
    this.errorMessage,
    required this.onSubmit,
    required this.onToggleMode,
    this.onForgotPassword,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
        widget.isLogin ? null : _displayNameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display Name (only for registration)
          if (!widget.isLogin) ...[
            CustomTextField(
              controller: _displayNameController,
              label: 'Display Name',
              hint: 'Enter your name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!Helpers.isValidEmail(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          PasswordTextField(
            controller: _passwordController,
            label: 'Password',
            hint: widget.isLogin ? 'Enter your password' : 'Create a password',
            textInputAction: widget.isLogin ? TextInputAction.done : TextInputAction.next,
            onSubmitted: widget.isLogin ? (_) => _handleSubmit() : null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!widget.isLogin && !Helpers.isValidPassword(value)) {
                return 'Password must be at least 8 characters with uppercase, lowercase, and number';
              }
              return null;
            },
          ),

          // Confirm Password (only for registration)
          if (!widget.isLogin) ...[
            const SizedBox(height: 16),
            PasswordTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],

          // Forgot Password (only for login)
          if (widget.isLogin && widget.onForgotPassword != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPassword,
                child: const Text('Forgot Password?'),
              ),
            ),
          ],

          // Error Message
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button
          CustomButton(
            text: widget.isLogin ? 'Sign In' : 'Create Account',
            onPressed: _handleSubmit,
            isLoading: widget.isLoading,
            width: double.infinity,
          ),

          const SizedBox(height: 16),

          // Toggle Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLogin
                    ? "Don't have an account?"
                    : 'Already have an account?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: widget.onToggleMode,
                child: Text(widget.isLogin ? 'Sign Up' : 'Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
