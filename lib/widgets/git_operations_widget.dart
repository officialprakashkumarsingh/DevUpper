import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/git_service.dart';
import '../services/github_service.dart';
import '../models/repository.dart';

class GitOperationsWidget extends StatefulWidget {
  final Repository repository;
  final GitHubService githubService;

  const GitOperationsWidget({
    super.key,
    required this.repository,
    required this.githubService,
  });

  @override
  State<GitOperationsWidget> createState() => _GitOperationsWidgetState();
}

class _GitOperationsWidgetState extends State<GitOperationsWidget> {
  final GitService _gitService = GitService.instance;
  final TextEditingController _commitMessageController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _gitStatus;
  String? _currentBranch;
  List<Map<String, dynamic>> _recentCommits = [];
  List<String> _branches = [];
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _initializeGitRepo();
  }

  Future<void> _initializeGitRepo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if git is available
      final isGitAvailable = await _gitService.isGitAvailable();
      if (!isGitAvailable) {
        setState(() {
          _error = 'Git is not installed on this system';
          _isLoading = false;
        });
        return;
      }

      // Get default repo path
      final repoPath = await _gitService.getDefaultRepoPath(widget.repository.name);
      
      // Initialize or clone repository
      await _setupRepository(repoPath);
      
      // Load git information
      await _loadGitInfo();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setupRepository(String repoPath) async {
    // Check if repository already exists locally
    final repoDir = Directory(repoPath);
    
    if (!repoDir.existsSync()) {
      // Clone the repository
      final cloneUrl = widget.repository.cloneUrl;
      final token = widget.githubService.token;
      
      final clonedPath = await _gitService.cloneRepository(
        repoUrl: cloneUrl,
        localPath: repoPath,
        token: token,
      );
      
      if (clonedPath == null) {
        throw Exception('Failed to clone repository');
      }
    } else {
      // Initialize existing repository
      await _gitService.initRepository(repoPath);
    }
  }

  Future<void> _loadGitInfo() async {
    try {
      final status = await _gitService.getStatus();
      final branch = await _gitService.getCurrentBranch();
      final commits = await _gitService.getCommitHistory(limit: 5);
      final branches = await _gitService.getBranches();

      setState(() {
        _gitStatus = status;
        _currentBranch = branch;
        _recentCommits = commits;
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performGitOperation(String operation) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      bool success = false;
      String successMessage = '';

      switch (operation) {
        case 'pull':
          success = await _gitService.pull();
          successMessage = 'Successfully pulled latest changes';
          break;
        case 'push':
          success = await _gitService.push();
          successMessage = 'Successfully pushed changes';
          break;
        case 'add_all':
          success = await _gitService.addAll();
          successMessage = 'Added all files to staging';
          break;
        case 'commit':
          final message = _commitMessageController.text.trim();
          if (message.isEmpty) {
            throw Exception('Please enter a commit message');
          }
          success = await _gitService.commit(message);
          successMessage = 'Successfully committed changes';
          _commitMessageController.clear();
          break;
      }

      if (success) {
        setState(() {
          _success = successMessage;
        });
        await _loadGitInfo();
        HapticFeedback.lightImpact();
      } else {
        throw Exception('Operation failed');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Git Operations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorCard(),
            ],
            
            if (_success != null) ...[
              const SizedBox(height: 12),
              _buildSuccessCard(),
            ],

            if (_currentBranch != null) ...[
              const SizedBox(height: 16),
              _buildBranchInfo(),
            ],

            if (_gitStatus != null) ...[
              const SizedBox(height: 16),
              _buildStatusInfo(),
            ],

            const SizedBox(height: 16),
            _buildCommitSection(),

            const SizedBox(height: 16),
            _buildActionButtons(),

            if (_recentCommits.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecentCommits(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _success!,
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Current branch: $_currentBranch',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final status = _gitStatus!;
    final hasChanges = !(status['clean'] as bool);

    if (!hasChanges) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Working directory clean',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Changes:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if ((status['modified'] as List).isNotEmpty)
          _buildFileChangesList('Modified', status['modified'], Colors.orange),
        if ((status['added'] as List).isNotEmpty)
          _buildFileChangesList('Added', status['added'], Colors.green),
        if ((status['deleted'] as List).isNotEmpty)
          _buildFileChangesList('Deleted', status['deleted'], Colors.red),
        if ((status['untracked'] as List).isNotEmpty)
          _buildFileChangesList('Untracked', status['untracked'], Colors.blue),
      ],
    );
  }

  Widget _buildFileChangesList(String label, List<dynamic> files, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${files.length}):',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...files.take(3).map((file) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 2),
            child: Text(
              '• $file',
              style: const TextStyle(fontSize: 11),
            ),
          )),
          if (files.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '... and ${files.length - 3} more',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commit Message:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commitMessageController,
          decoration: InputDecoration(
            hintText: 'Enter commit message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Pull',
                Icons.download_rounded,
                () => _performGitOperation('pull'),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Push',
                Icons.upload_rounded,
                () => _performGitOperation('push'),
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add All',
                Icons.add_circle_outline,
                () => _performGitOperation('add_all'),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Commit',
                Icons.commit,
                () => _performGitOperation('commit'),
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }

  Widget _buildRecentCommits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Commits:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recentCommits.length,
            itemBuilder: (context, index) {
              final commit = _recentCommits[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commit['message'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            commit['author'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            commit['hash']?.substring(0, 7) ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commitMessageController.dispose();
    super.dispose();
  }
}