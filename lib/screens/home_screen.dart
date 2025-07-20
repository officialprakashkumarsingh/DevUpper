import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../models/agent_task.dart';
import '../services/github_service.dart';
import '../services/ai_service.dart';
import '../widgets/repository_card.dart';
import '../widgets/task_card.dart';
import '../widgets/agent_chat.dart';
import '../screens/auth_screen.dart';
import '../screens/repository_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GitHubService _githubService = GitHubService();
  final AIService _aiService = AIService();
  
  List<Repository> _repositories = [];
  List<AgentTask> _tasks = [];
  bool _isLoading = false;
  String? _error;
  int _selectedTab = 0;
  Repository? _selectedRepository;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  void _checkAuthenticationStatus() {
    if (!_githubService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      });
    } else {
      _loadRepositories();
    }
  }

  Future<void> _loadRepositories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repositories = await _githubService.fetchUserRepositories();
      setState(() {
        _repositories = repositories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createTask({
    required String title,
    required String description,
    required TaskType type,
    Repository? repository,
  }) async {
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      createdAt: DateTime.now(),
      repositoryId: repository?.id,
    );

    setState(() {
      _tasks.insert(0, task);
    });

    // Process the task with AI
    try {
      final result = await _aiService.processAgentTask(task, repository: repository);
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(
            status: TaskStatus.completed,
            result: result,
            completedAt: DateTime.now(),
            progress: 1.0,
          );
        }
      });
    } catch (e) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(
            status: TaskStatus.failed,
            error: e.toString(),
            completedAt: DateTime.now(),
          );
        }
      });
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(
        repositories: _repositories,
        onCreateTask: _createTask,
      ),
    );
  }

  void _logout() {
    _githubService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 1 ? FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.code,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DevUpper',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _githubService.username ?? 'AI Development Assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _logout,
            icon: Icon(
              Icons.logout,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Repositories',
              icon: Icons.folder_outlined,
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Tasks',
              icon: Icons.assignment_outlined,
              index: 1,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Agent',
              icon: Icons.smart_toy_outlined,
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRepositoriesTab();
      case 1:
        return _buildTasksTab();
      case 2:
        return _buildAgentTab();
      default:
        return _buildRepositoriesTab();
    }
  }

  Widget _buildRepositoriesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading repositories',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRepositories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_repositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No repositories found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a repository on GitHub to get started',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRepositories,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _repositories.length,
        itemBuilder: (context, index) {
          final repository = _repositories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RepositoryCard(
              repository: repository,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepositoryScreen(repository: repository),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a task to get started with AI assistance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            task: task,
            onTap: () {
              // Show task details
            },
            onCancel: task.canCancel ? () {
              setState(() {
                final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
                if (taskIndex != -1) {
                  _tasks[taskIndex] = task.copyWith(status: TaskStatus.cancelled);
                }
              });
            } : null,
          ),
        );
      },
    );
  }

  Widget _buildAgentTab() {
    return AgentChat(
      aiService: _aiService,
      selectedRepository: _selectedRepository,
      repositories: _repositories,
      onRepositoryChanged: (repository) {
        setState(() {
          _selectedRepository = repository;
        });
      },
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  final List<Repository> repositories;
  final Function({
    required String title,
    required String description,
    required TaskType type,
    Repository? repository,
  }) onCreateTask;

  const _CreateTaskDialog({
    required this.repositories,
    required this.onCreateTask,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskType _selectedType = TaskType.codeGeneration;
  Repository? _selectedRepository;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Add user authentication',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of what you want to accomplish',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Task Type',
              ),
              items: TaskType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTaskTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Repository?>(
              value: _selectedRepository,
              decoration: const InputDecoration(
                labelText: 'Repository (Optional)',
              ),
              items: [
                const DropdownMenuItem<Repository?>(
                  value: null,
                  child: Text('No repository'),
                ),
                ...widget.repositories.map((repo) {
                  return DropdownMenuItem<Repository?>(
                    value: repo,
                    child: Text(repo.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRepository = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty &&
                _descriptionController.text.trim().isNotEmpty) {
              widget.onCreateTask(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                type: _selectedType,
                repository: _selectedRepository,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getTaskTypeDisplayName(TaskType type) {
    switch (type) {
      case TaskType.codeGeneration:
        return 'Code Generation';
      case TaskType.codeReview:
        return 'Code Review';
      case TaskType.refactoring:
        return 'Refactoring';
      case TaskType.bugFix:
        return 'Bug Fix';
      case TaskType.testing:
        return 'Testing';
      case TaskType.documentation:
        return 'Documentation';
      case TaskType.gitOperation:
        return 'Git Operation';
      case TaskType.fileOperation:
        return 'File Operation';
      case TaskType.analysis:
        return 'Analysis';
      case TaskType.custom:
        return 'Custom';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}