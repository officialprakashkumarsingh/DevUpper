import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../models/agent_task.dart';
import '../services/github_service.dart';
import '../services/ai_service.dart';
import '../services/git_service.dart';
import '../widgets/repository_card.dart';
import '../widgets/task_card.dart';
import '../widgets/agent_chat.dart';
import '../screens/auth_screen.dart';
import '../screens/repository_screen.dart';
import 'package:flutter/cupertino.dart';

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

  Future<void> _checkAuthenticationStatus() async {
    // First, try to load saved credentials
    final hasCredentials = await _githubService.loadSavedCredentials();
    
    if (!hasCredentials || !_githubService.isAuthenticated) {
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
    TaskType? type,
    Repository? repository,
  }) async {
    // Use AI to determine task type if not provided
    TaskType finalType = type ?? await _determineTaskType(title, description);
    
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: finalType,
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

  Future<TaskType> _determineTaskType(String title, String description) async {
    try {
      final taskType = await _aiService.determineTaskType(title, description);
      return taskType;
    } catch (e) {
      // Fallback to default type if AI determination fails
      return TaskType.custom;
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
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.square_arrow_right,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Repositories',
              icon: CupertinoIcons.folder,
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Tasks',
              icon: CupertinoIcons.list_bullet,
              index: 1,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Agent',
              icon: CupertinoIcons.chat_bubble_2, // Changed to valid chat icon
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(7),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        child: CupertinoActivityIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading repositories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadRepositories,
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(10),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
              CupertinoIcons.folder,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No repositories found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a repository on GitHub to get started',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRepositories,
      color: const Color(0xFF007AFF),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _repositories.length,
        itemBuilder: (context, index) {
          final repository = _repositories[index];
          return RepositoryCard(
            repository: repository,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => RepositoryScreen(repository: repository),
                ),
              );
            },
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
              CupertinoIcons.list_bullet,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
            repository: task.repositoryId != null 
                ? _repositories.firstWhere((r) => r.id == task.repositoryId, orElse: () => _repositories.first)
                : null,
            githubService: _githubService,
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
  TaskType? _selectedType; // Make optional, AI will determine if null
  Repository? _selectedRepository;
  bool _useAITypeDetection = true;
  bool _isGeneratingAISuggestions = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Task'),
                content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'e.g., Add user authentication',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isGeneratingAISuggestions ? null : _generateAISuggestions,
                      icon: _isGeneratingAISuggestions 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      tooltip: 'Generate AI suggestions',
                    ),
                  ],
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
            // AI Type Detection Toggle
            Row(
              children: [
                Switch(
                  value: _useAITypeDetection,
                  onChanged: (value) {
                    setState(() {
                      _useAITypeDetection = value;
                      if (value) {
                        _selectedType = null;
                      } else {
                        _selectedType = TaskType.codeGeneration;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _useAITypeDetection 
                        ? 'AI will determine task type automatically' 
                        : 'Manual task type selection',
                    style: TextStyle(
                      fontSize: 14,
                      color: _useAITypeDetection ? Colors.blue.shade700 : Colors.grey.shade600,
                      fontWeight: _useAITypeDetection ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (!_useAITypeDetection) ...[
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
            ],
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
                _descriptionController.text.trim().isNotEmpty &&
                (_useAITypeDetection || _selectedType != null)) {
              widget.onCreateTask(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                type: _selectedType ?? TaskType.custom, // Use custom as fallback when AI detection is enabled
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

  Future<void> _generateAISuggestions() async {
    if (_selectedRepository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a repository first')),
      );
      return;
    }

    setState(() {
      _isGeneratingAISuggestions = true;
    });

    try {
      // This would be implemented in AI service to analyze repository and suggest tasks
      final suggestions = await _generateTaskSuggestions(_selectedRepository!);
      
      if (suggestions.isNotEmpty) {
        final suggestion = suggestions.first;
        setState(() {
          _titleController.text = suggestion['title'] ?? '';
          _descriptionController.text = suggestion['description'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate suggestions: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingAISuggestions = false;
      });
    }
  }

  Future<List<Map<String, String>>> _generateTaskSuggestions(Repository repository) async {
    // Placeholder implementation - this would analyze the repository
    // and suggest relevant tasks based on the codebase
    return [
      {
        'title': 'Improve code documentation',
        'description': 'Add comprehensive documentation and comments to improve code readability and maintainability',
      },
      {
        'title': 'Add unit tests',
        'description': 'Create unit tests for critical functions to improve code reliability and catch bugs early',
      },
      {
        'title': 'Refactor legacy code',
        'description': 'Modernize and refactor outdated code sections to improve performance and maintainability',
      },
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}