import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/agent_task.dart';
import '../models/repository.dart';
import 'codebase_analyzer.dart';

class AIService {
  static const String _apiKey = 'AIzaSyBUiSSswKvLvEK7rydCCRPF50eIDI_KOGc';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  final CodebaseAnalyzer _codebaseAnalyzer = CodebaseAnalyzer();
  
  // Available tools for the AI agent
  final List<Map<String, dynamic>> _availableTools = [
    {
      'name': 'analyze_codebase',
      'description': 'Analyze the structure and content of a codebase',
      'parameters': {
        'type': 'object',
        'properties': {
          'repository_path': {
            'type': 'string',
            'description': 'Path to the repository to analyze'
          },
          'focus_areas': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Specific areas to focus on (e.g., architecture, dependencies, code quality)'
          }
        },
        'required': ['repository_path']
      }
    },
    {
      'name': 'search_code',
      'description': 'Search for specific patterns, functions, or content in the codebase',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'Search query or pattern to find'
          },
          'file_types': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'File extensions to search in (e.g., [".dart", ".yaml"])'
          },
          'repository_path': {
            'type': 'string',
            'description': 'Path to the repository to search in'
          }
        },
        'required': ['query', 'repository_path']
      }
    },
    {
      'name': 'generate_code',
      'description': 'Generate new code based on requirements',
      'parameters': {
        'type': 'object',
        'properties': {
          'requirements': {
            'type': 'string',
            'description': 'Detailed requirements for the code to generate'
          },
          'language': {
            'type': 'string',
            'description': 'Programming language (e.g., dart, python, javascript)'
          },
          'file_path': {
            'type': 'string',
            'description': 'Target file path for the generated code'
          },
          'context': {
            'type': 'string',
            'description': 'Additional context about the project structure'
          }
        },
        'required': ['requirements', 'language']
      }
    },
    {
      'name': 'refactor_code',
      'description': 'Refactor existing code to improve quality or structure',
      'parameters': {
        'type': 'object',
        'properties': {
          'file_path': {
            'type': 'string',
            'description': 'Path to the file to refactor'
          },
          'refactor_type': {
            'type': 'string',
            'description': 'Type of refactoring (extract_method, rename, optimize, etc.)'
          },
          'instructions': {
            'type': 'string',
            'description': 'Specific refactoring instructions'
          }
        },
        'required': ['file_path', 'refactor_type']
      }
    },
    {
      'name': 'review_code',
      'description': 'Review code for quality, bugs, and best practices',
      'parameters': {
        'type': 'object',
        'properties': {
          'file_path': {
            'type': 'string',
            'description': 'Path to the file to review'
          },
          'review_type': {
            'type': 'string',
            'description': 'Type of review (security, performance, style, bugs)'
          },
          'context': {
            'type': 'string',
            'description': 'Additional context about the code'
          }
        },
        'required': ['file_path']
      }
    },
    {
      'name': 'create_pull_request',
      'description': 'Create a pull request with the changes',
      'parameters': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title for the pull request'
          },
          'description': {
            'type': 'string',
            'description': 'Description of the changes'
          },
          'branch_name': {
            'type': 'string',
            'description': 'Name for the new branch'
          },
          'base_branch': {
            'type': 'string',
            'description': 'Base branch to merge into (default: main)'
          }
        },
        'required': ['title', 'description', 'branch_name']
      }
    },
    {
      'name': 'run_tests',
      'description': 'Run tests for the project',
      'parameters': {
        'type': 'object',
        'properties': {
          'test_type': {
            'type': 'string',
            'description': 'Type of tests to run (unit, integration, all)'
          },
          'specific_files': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Specific test files to run'
          }
        }
      }
    }
  ];

  Future<String> processAgentTask(AgentTask task, {Repository? repository}) async {
    try {
      // Step 1: Think about the task
      await _updateTaskStatus(task, TaskStatus.thinking);
      final thinking = await _thinkAboutTask(task, repository);
      
      // Step 2: Create a plan
      await _updateTaskStatus(task, TaskStatus.planning);
      final plan = await _createPlan(task, thinking, repository);
      
      // Step 3: Execute the plan
      await _updateTaskStatus(task, TaskStatus.executing);
      final result = await _executePlan(task, plan, repository);
      
      await _updateTaskStatus(task, TaskStatus.completed);
      
      // If code changes were made and repository is available, suggest git operations
      if (repository != null && _hasCodeChanges(result)) {
        // Add metadata to indicate git operations are needed
        task = task.copyWith(
          metadata: {
            ...task.metadata,
            'requiresGitOps': true,
            'suggestedCommitMessage': '${task.typeDisplayName}: ${task.title}',
          },
        );
      }
      
      return result;
    } catch (e) {
      await _updateTaskStatus(task, TaskStatus.failed);
      throw Exception('AI Service Error: $e');
    }
  }

  Future<String> _thinkAboutTask(AgentTask task, Repository? repository) async {
    final prompt = '''
    You are an advanced AI coding agent like Cursor AI. You need to think about this task:
    
    Task: ${task.title}
    Description: ${task.description}
    Type: ${task.typeDisplayName}
    Repository: ${repository?.fullName ?? 'Unknown'}
    
    Think about:
    1. What information do you need to complete this task?
    2. What tools will you need to use?
    3. What are the potential challenges?
    4. What is the best approach?
    
    Provide your analysis and initial thoughts.
    ''';

    return await _generateResponse(prompt);
  }

  Future<String> _createPlan(AgentTask task, String thinking, Repository? repository) async {
    final toolsDescription = _availableTools.map((tool) => 
      '- ${tool['name']}: ${tool['description']}'
    ).join('\n');

    final prompt = '''
    Based on your thinking: "$thinking"
    
    Create a detailed step-by-step plan to complete this task:
    Task: ${task.title}
    Description: ${task.description}
    
    Available tools:
    $toolsDescription
    
    Create a plan with specific steps, including which tools to use and when.
    Format as a numbered list with clear actions.
    ''';

    return await _generateResponse(prompt);
  }

  Future<String> _executePlan(AgentTask task, String plan, Repository? repository) async {
    final prompt = '''
    Execute this plan step by step:
    
    Plan: $plan
    
    Task Details:
    - Title: ${task.title}
    - Description: ${task.description}
    - Repository: ${repository?.fullName ?? 'Unknown'}
    
    Execute each step and provide detailed results. Use function calls when appropriate.
    If you need to use tools, specify which ones and with what parameters.
    
    Provide a comprehensive execution report.
    ''';

    return await _generateResponse(prompt, useFunctionCalling: true);
  }

  Future<TaskType> determineTaskType(String title, String description) async {
    final prompt = '''
    Analyze this task and determine the most appropriate task type:
    
    Title: $title
    Description: $description
    
    Available task types:
    - codeGeneration: Creating new code, functions, classes, or features
    - codeReview: Reviewing existing code for quality, bugs, or improvements
    - refactoring: Restructuring existing code without changing functionality
    - bugFix: Fixing bugs or errors in existing code
    - testing: Writing tests, test cases, or testing code
    - documentation: Creating or updating documentation, comments, README files
    - gitOperation: Git-related tasks like merging, branching, versioning
    - fileOperation: File system operations like moving, renaming, organizing files
    - analysis: Code analysis, performance analysis, security analysis
    - custom: Any other type of task
    
    Return only the task type name (one word) that best matches this task.
    ''';

    try {
      final response = await _generateResponse(prompt);
      final taskTypeName = response.trim().toLowerCase();
      
      // Map response to TaskType enum
      switch (taskTypeName) {
        case 'codegeneration':
          return TaskType.codeGeneration;
        case 'codereview':
          return TaskType.codeReview;
        case 'refactoring':
          return TaskType.refactoring;
        case 'bugfix':
          return TaskType.bugFix;
        case 'testing':
          return TaskType.testing;
        case 'documentation':
          return TaskType.documentation;
        case 'gitoperation':
          return TaskType.gitOperation;
        case 'fileoperation':
          return TaskType.fileOperation;
        case 'analysis':
          return TaskType.analysis;
        default:
          return TaskType.custom;
      }
    } catch (e) {
      // Fallback logic based on keywords
      final combinedText = '$title $description'.toLowerCase();
      
      if (combinedText.contains('bug') || combinedText.contains('fix') || combinedText.contains('error')) {
        return TaskType.bugFix;
      } else if (combinedText.contains('test') || combinedText.contains('unit test') || combinedText.contains('testing')) {
        return TaskType.testing;
      } else if (combinedText.contains('review') || combinedText.contains('check') || combinedText.contains('audit')) {
        return TaskType.codeReview;
      } else if (combinedText.contains('refactor') || combinedText.contains('restructure') || combinedText.contains('optimize')) {
        return TaskType.refactoring;
      } else if (combinedText.contains('document') || combinedText.contains('readme') || combinedText.contains('comment')) {
        return TaskType.documentation;
      } else if (combinedText.contains('git') || combinedText.contains('commit') || combinedText.contains('merge') || combinedText.contains('branch')) {
        return TaskType.gitOperation;
      } else if (combinedText.contains('create') || combinedText.contains('add') || combinedText.contains('implement') || combinedText.contains('build')) {
        return TaskType.codeGeneration;
      } else if (combinedText.contains('analyze') || combinedText.contains('analysis') || combinedText.contains('performance')) {
        return TaskType.analysis;
      } else {
        return TaskType.custom;
      }
    }
  }

  Future<String> _generateResponse(String prompt, {bool useFunctionCalling = false}) async {
    try {
      final url = Uri.parse('$_baseUrl/gemini-2.0-flash-exp:generateContent?key=$_apiKey');
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192,
        },
      };

      if (useFunctionCalling) {
        requestBody['tools'] = [
          {
            'functionDeclarations': _availableTools.map((tool) => {
              'name': tool['name'],
              'description': tool['description'],
              'parameters': tool['parameters'],
            }).toList(),
          }
        ];
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // Check for function calls
          if (candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            String result = '';
            
            for (final part in parts) {
              if (part['text'] != null) {
                result += part['text'];
              } else if (part['functionCall'] != null) {
                // Handle function call
                final functionCall = part['functionCall'];
                final functionResult = await _executeFunctionCall(
                  functionCall['name'],
                  functionCall['args'] ?? {},
                );
                result += '\n\nFunction Call Result:\n$functionResult\n';
              }
            }
            
            return result.trim();
          }
        }
      }

      throw Exception('Failed to generate response: ${response.statusCode}');
    } catch (e) {
      throw Exception('AI API Error: $e');
    }
  }

  bool _hasCodeChanges(String result) {
    // Check if the result indicates code changes were made
    final codeIndicators = [
      'created file',
      'modified file',
      'updated file',
      'added function',
      'implemented',
      'refactored',
      'fixed bug',
      'added test',
      'wrote code',
      'generated code',
    ];
    
    final resultLower = result.toLowerCase();
    return codeIndicators.any((indicator) => resultLower.contains(indicator));
  }

  Future<String> _executeFunctionCall(String functionName, Map<String, dynamic> args) async {
    try {
      switch (functionName) {
        case 'analyze_codebase':
          return await _analyzeCodebase(args);
        case 'search_code':
          return await _searchCode(args);
        case 'generate_code':
          return await _generateCode(args);
        case 'refactor_code':
          return await _refactorCode(args);
        case 'review_code':
          return await _reviewCode(args);
        case 'create_pull_request':
          return await _createPullRequest(args);
        case 'run_tests':
          return await _runTests(args);
        default:
          return 'Unknown function: $functionName';
      }
    } catch (e) {
      return 'Error executing $functionName: $e';
    }
  }

  Future<String> _analyzeCodebase(Map<String, dynamic> args) async {
    final repositoryPath = args['repository_path'] as String;
    final focusAreas = (args['focus_areas'] as List<dynamic>?)?.cast<String>() ?? [];
    
    final analysis = await _codebaseAnalyzer.analyzeRepository(repositoryPath);
    
    String result = 'Codebase Analysis Results:\n\n';
    result += 'Structure: ${analysis['structure']}\n';
    result += 'Languages: ${analysis['languages']}\n';
    result += 'Dependencies: ${analysis['dependencies']}\n';
    result += 'Metrics: ${analysis['metrics']}\n';
    
    if (focusAreas.isNotEmpty) {
      result += '\nFocus Areas Analysis:\n';
      for (final area in focusAreas) {
        result += '- $area: ${analysis[area] ?? 'Not available'}\n';
      }
    }
    
    return result;
  }

  Future<String> _searchCode(Map<String, dynamic> args) async {
    final query = args['query'] as String;
    final repositoryPath = args['repository_path'] as String;
    final fileTypes = (args['file_types'] as List<dynamic>?)?.cast<String>();
    
    final results = await _codebaseAnalyzer.searchInCodebase(repositoryPath, query, fileTypes);
    
    String result = 'Search Results for "$query":\n\n';
    if (results.isEmpty) {
      result += 'No matches found.';
    } else {
      for (final match in results) {
        result += '${match['file']}: Line ${match['line']}\n';
        result += '  ${match['content']}\n\n';
      }
    }
    
    return result;
  }

  Future<String> _generateCode(Map<String, dynamic> args) async {
    final requirements = args['requirements'] as String;
    final language = args['language'] as String;
    final filePath = args['file_path'] as String?;
    final context = args['context'] as String?;
    
    final prompt = '''
    Generate $language code based on these requirements:
    $requirements
    
    ${context != null ? 'Project Context: $context' : ''}
    ${filePath != null ? 'Target File: $filePath' : ''}
    
    Provide clean, well-documented, production-ready code.
    Include proper error handling and follow best practices.
    ''';
    
    final generatedCode = await _generateResponse(prompt);
    
    if (filePath != null) {
      // Save the generated code to file
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(generatedCode);
      return 'Code generated and saved to $filePath:\n\n$generatedCode';
    }
    
    return 'Generated Code:\n\n$generatedCode';
  }

  Future<String> _refactorCode(Map<String, dynamic> args) async {
    final filePath = args['file_path'] as String;
    final refactorType = args['refactor_type'] as String;
    final instructions = args['instructions'] as String?;
    
    if (!File(filePath).existsSync()) {
      return 'Error: File $filePath does not exist';
    }
    
    final originalCode = await File(filePath).readAsString();
    
    final prompt = '''
    Refactor this code:
    
    File: $filePath
    Refactor Type: $refactorType
    ${instructions != null ? 'Instructions: $instructions' : ''}
    
    Original Code:
    ```
    $originalCode
    ```
    
    Provide the refactored code with explanations of changes made.
    ''';
    
    final refactoredCode = await _generateResponse(prompt);
    
    return 'Refactoring Results for $filePath:\n\n$refactoredCode';
  }

  Future<String> _reviewCode(Map<String, dynamic> args) async {
    final filePath = args['file_path'] as String;
    final reviewType = args['review_type'] as String? ?? 'general';
    final context = args['context'] as String?;
    
    if (!File(filePath).existsSync()) {
      return 'Error: File $filePath does not exist';
    }
    
    final code = await File(filePath).readAsString();
    
    final prompt = '''
    Review this code for $reviewType issues:
    
    File: $filePath
    ${context != null ? 'Context: $context' : ''}
    
    Code:
    ```
    $code
    ```
    
    Provide a detailed review including:
    1. Issues found
    2. Suggestions for improvement
    3. Best practice recommendations
    4. Security considerations (if applicable)
    ''';
    
    final review = await _generateResponse(prompt);
    
    return 'Code Review for $filePath:\n\n$review';
  }

  Future<String> _createPullRequest(Map<String, dynamic> args) async {
    final title = args['title'] as String;
    final description = args['description'] as String;
    final branchName = args['branch_name'] as String;
    final baseBranch = args['base_branch'] as String? ?? 'main';
    
    // This would integrate with GitHubService in a real implementation
    return '''
    Pull Request Created:
    
    Title: $title
    Description: $description
    Branch: $branchName
    Base: $baseBranch
    
    Note: This is a simulation. In a real implementation, this would create an actual PR.
    ''';
  }

  Future<String> _runTests(Map<String, dynamic> args) async {
    final testType = args['test_type'] as String? ?? 'all';
    final specificFiles = (args['specific_files'] as List<dynamic>?)?.cast<String>();
    
    // This would run actual tests in a real implementation
    return '''
    Test Results:
    
    Test Type: $testType
    ${specificFiles != null ? 'Specific Files: ${specificFiles.join(', ')}' : 'All test files'}
    
    Status: PASSED
    Duration: 2.3s
    Coverage: 85%
    
    Note: This is a simulation. In a real implementation, this would run actual tests.
    ''';
  }

  Future<void> _updateTaskStatus(AgentTask task, TaskStatus status) async {
    // This would update the task status in the UI/database
    // For now, we'll just simulate a delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<String>> getSuggestions(String input, {Repository? repository}) async {
    final prompt = '''
    Based on this input: "$input"
    ${repository != null ? 'For repository: ${repository.fullName}' : ''}
    
    Suggest 3-5 specific, actionable tasks that an AI coding agent could help with.
    Focus on practical development tasks like code generation, refactoring, bug fixes, etc.
    
    Return suggestions as a simple list, one per line.
    ''';

    try {
      final response = await _generateResponse(prompt);
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*|\-\s*|\*\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .take(5)
          .toList();
    } catch (e) {
      return [
        'Generate boilerplate code',
        'Review code for improvements',
        'Add unit tests',
        'Refactor for better performance',
        'Fix potential bugs'
      ];
    }
  }

  Future<String> chatWithAgent(String message, {Repository? repository, List<String>? conversationHistory}) async {
    final context = conversationHistory?.join('\n') ?? '';
    
    final prompt = '''
    You are an AI coding assistant like Cursor AI. Respond to this message:
    
    User: $message
    
    ${repository != null ? 'Current Repository: ${repository.fullName}' : ''}
    ${context.isNotEmpty ? 'Conversation History:\n$context' : ''}
    
    Provide helpful, actionable responses. If the user is asking for code help, be specific and practical.
    If they need clarification, ask follow-up questions.
    ''';

    return await _generateResponse(prompt);
  }
}