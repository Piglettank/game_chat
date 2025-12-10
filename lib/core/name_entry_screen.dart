import 'package:flutter/material.dart';
import '../services/user_storage.dart';
import 'welcome_screen.dart';

class NameEntryScreen extends StatefulWidget {
  final String chatId;

  const NameEntryScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final userName = _nameController.text.trim();
    final userId = UserStorage.getUserId();

    await UserStorage.saveUser(userId, userName);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(
          chatId: widget.chatId,
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Welcome to Game Night',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Enter your name to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48.0),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your name',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitName(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      if (value.trim().length > 50) {
                        return 'Name must be less than 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitName,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 16.0,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
