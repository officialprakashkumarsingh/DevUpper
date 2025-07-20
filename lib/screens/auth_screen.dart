import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/github_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GitHubService _githubService = GitHubService();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isTokenVisible = false;

  Future<void> _authenticate() async {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      setState(() {
        _error = 'Please enter your GitHub token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _githubService.authenticate(token);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _error = 'Invalid GitHub token. Please check your token and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showTokenHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to get GitHub Token'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Go to GitHub.com and sign in'),
              SizedBox(height: 8),
              Text('2. Click your profile → Settings'),
              SizedBox(height: 8),
              Text('3. Go to Developer settings → Personal access tokens → Tokens (classic)'),
              SizedBox(height: 8),
              Text('4. Click "Generate new token (classic)"'),
              SizedBox(height: 8),
              Text('5. Select these scopes:'),
              SizedBox(height: 4),
              Text('   • repo (Full repository access)'),
              Text('   • user (Read user profile)'),
              Text('   • workflow (Update workflows)'),
              SizedBox(height: 8),
              Text('6. Copy the generated token'),
              SizedBox(height: 16),
              Text(
                'Note: Keep your token secure and never share it publicly.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildTokenInput(),
              const SizedBox(height: 24),
              _buildAuthButton(),
              const SizedBox(height: 16),
              _buildHelpButton(),
              if (_error != null) ...[
                const SizedBox(height: 24),
                _buildErrorMessage(),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.code,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'DevUpper',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI-powered development assistant\nfor your GitHub repositories',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _tokenController,
        obscureText: !_isTokenVisible,
        decoration: InputDecoration(
          hintText: 'Enter your GitHub Personal Access Token',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.key,
            color: Colors.grey[600],
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isTokenVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isTokenVisible = !_isTokenVisible;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onSubmitted: (_) => _authenticate(),
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Connect to GitHub',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildHelpButton() {
    return TextButton.icon(
      onPressed: _showTokenHelp,
      icon: Icon(
        Icons.help_outline,
        size: 18,
        color: Colors.grey[600],
      ),
      label: Text(
        'How to get GitHub token?',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}