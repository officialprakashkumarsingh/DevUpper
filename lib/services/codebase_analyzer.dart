import 'dart:io';
import 'dart:convert';
import 'dart:async';

class CodebaseAnalyzer {
  static const int _maxFileSize = 1024 * 1024; // 1MB max file size
  static const List<String> _textFileExtensions = [
    '.dart', '.py', '.js', '.ts', '.tsx', '.jsx', '.java', '.kt',
    '.swift', '.go', '.rs', '.cpp', '.c', '.h', '.hpp',
    '.html', '.css', '.scss', '.sass', '.vue', '.svelte',
    '.json', '.yaml', '.yml', '.xml', '.toml', '.ini',
    '.md', '.txt', '.config', '.conf', '.env',
    '.gradle', '.properties', '.lock', '.gitignore',
    '.dockerfile', '.sql', '.sh', '.bat', '.ps1',
  ];

  static const List<String> _configFiles = [
    'package.json', 'pubspec.yaml', 'requirements.txt', 'Cargo.toml',
    'build.gradle', 'pom.xml', 'composer.json', 'Gemfile',
    'setup.py', 'pyproject.toml', 'go.mod', 'Makefile',
  ];

  static const List<String> _ignorePatterns = [
    'node_modules', '.git', '.svn', '.hg',
    'build', 'dist', 'out', 'target',
    '.dart_tool', '.packages', '.pub',
    '__pycache__', '*.pyc', '*.pyo',
    '.env', '.env.local', '.env.production',
    '*.log', '*.tmp', '*.temp',
    '.idea', '.vscode', '.vs',
    'coverage', '.nyc_output',
  ];

  Future<Map<String, dynamic>> analyzeRepository(String repositoryPath) async {
    try {
      final directory = Directory(repositoryPath);
      if (!directory.existsSync()) {
        throw Exception('Repository path does not exist: $repositoryPath');
      }

      print('Analyzing repository: $repositoryPath');

      final analysis = <String, dynamic>{};
      
      // Analyze structure
      analysis['structure'] = await _analyzeStructure(directory);
      
      // Analyze languages
      analysis['languages'] = await _analyzeLanguages(directory);
      
      // Analyze dependencies
      analysis['dependencies'] = await _analyzeDependencies(directory);
      
      // Analyze metrics
      analysis['metrics'] = await _analyzeMetrics(directory);
      
      // Analyze patterns
      analysis['patterns'] = await _analyzePatterns(directory);
      
      // Create file index for fast searching
      analysis['fileIndex'] = await _createFileIndex(directory);
      
      print('Repository analysis completed');
      return analysis;
    } catch (e) {
      print('Error analyzing repository: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _analyzeStructure(Directory directory) async {
    final structure = <String, dynamic>{
      'rootPath': directory.path,
      'directories': <String>[],
      'files': <String>[],
      'totalFiles': 0,
      'totalDirectories': 0,
      'maxDepth': 0,
    };

    await _traverseDirectory(directory, (entity, depth) {
      if (entity is Directory) {
        structure['directories'].add(entity.path);
        structure['totalDirectories']++;
        if (depth > structure['maxDepth']) {
          structure['maxDepth'] = depth;
        }
      } else if (entity is File) {
        structure['files'].add(entity.path);
        structure['totalFiles']++;
      }
    });

    return structure;
  }

  Future<Map<String, dynamic>> _analyzeLanguages(Directory directory) async {
    final languages = <String, int>{};
    final filesByLanguage = <String, List<String>>{};
    int totalLines = 0;

    await _traverseDirectory(directory, (entity, depth) async {
      if (entity is File && _isTextFile(entity.path)) {
        final extension = _getFileExtension(entity.path);
        final language = _getLanguageFromExtension(extension);
        
        languages[language] = (languages[language] ?? 0) + 1;
        filesByLanguage.putIfAbsent(language, () => []).add(entity.path);

        try {
          final lines = await _countLines(entity);
          totalLines += lines;
        } catch (e) {
          // Skip files that can't be read
        }
      }
    });

    return {
      'languages': languages,
      'filesByLanguage': filesByLanguage,
      'totalLines': totalLines,
      'primaryLanguage': _getPrimaryLanguage(languages),
    };
  }

  Future<Map<String, dynamic>> _analyzeDependencies(Directory directory) async {
    final dependencies = <String, dynamic>{
      'packageManagers': <String>[],
      'dependencies': <String, List<String>>{},
      'configFiles': <String>[],
    };

    await _traverseDirectory(directory, (entity, depth) async {
      if (entity is File) {
        final fileName = entity.path.split('/').last;
        
        if (_configFiles.contains(fileName)) {
          dependencies['configFiles'].add(entity.path);
          
          try {
            final deps = await _extractDependencies(entity, fileName);
            if (deps.isNotEmpty) {
              dependencies['dependencies'][fileName] = deps;
              dependencies['packageManagers'].add(_getPackageManager(fileName));
            }
          } catch (e) {
            // Skip files that can't be parsed
          }
        }
      }
    });

    return dependencies;
  }

  Future<Map<String, dynamic>> _analyzeMetrics(Directory directory) async {
    int totalFiles = 0;
    int totalLines = 0;
    int totalSize = 0;
    final fileSizes = <int>[];
    final complexityScores = <String, int>{};

    await _traverseDirectory(directory, (entity, depth) async {
      if (entity is File && _isTextFile(entity.path)) {
        totalFiles++;
        
        try {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileSizes.add(stat.size);

          final lines = await _countLines(entity);
          totalLines += lines;

          // Simple complexity analysis
          final complexity = await _analyzeComplexity(entity);
          if (complexity > 0) {
            complexityScores[entity.path] = complexity;
          }
        } catch (e) {
          // Skip files that can't be analyzed
        }
      }
    });

    return {
      'totalFiles': totalFiles,
      'totalLines': totalLines,
      'totalSize': totalSize,
      'averageFileSize': totalFiles > 0 ? totalSize / totalFiles : 0,
      'averageLinesPerFile': totalFiles > 0 ? totalLines / totalFiles : 0,
      'largestFiles': _getLargestFiles(fileSizes),
      'complexityScores': complexityScores,
      'averageComplexity': complexityScores.isEmpty ? 0 : 
          complexityScores.values.reduce((a, b) => a + b) / complexityScores.length,
    };
  }

  Future<Map<String, dynamic>> _analyzePatterns(Directory directory) async {
    final patterns = <String, dynamic>{
      'architecturalPatterns': <String>[],
      'designPatterns': <String>[],
      'testingPatterns': <String>[],
      'folderStructure': <String, int>{},
    };

    await _traverseDirectory(directory, (entity, depth) {
      if (entity is Directory) {
        final dirName = entity.path.split('/').last.toLowerCase();
        patterns['folderStructure'][dirName] = (patterns['folderStructure'][dirName] ?? 0) + 1;

        // Detect architectural patterns
        if (dirName.contains('controller') || dirName.contains('view') || dirName.contains('model')) {
          if (!patterns['architecturalPatterns'].contains('MVC')) {
            patterns['architecturalPatterns'].add('MVC');
          }
        }
        if (dirName.contains('service') || dirName.contains('repository')) {
          if (!patterns['architecturalPatterns'].contains('Service Layer')) {
            patterns['architecturalPatterns'].add('Service Layer');
          }
        }
        if (dirName.contains('widget') || dirName.contains('component')) {
          if (!patterns['architecturalPatterns'].contains('Component-Based')) {
            patterns['architecturalPatterns'].add('Component-Based');
          }
        }
      } else if (entity is File) {
        final fileName = entity.path.split('/').last.toLowerCase();
        
        // Detect testing patterns
        if (fileName.contains('test') || fileName.contains('spec')) {
          if (!patterns['testingPatterns'].contains('Unit Testing')) {
            patterns['testingPatterns'].add('Unit Testing');
          }
        }
        if (fileName.contains('mock') || fileName.contains('stub')) {
          if (!patterns['testingPatterns'].contains('Mocking')) {
            patterns['testingPatterns'].add('Mocking');
          }
        }
      }
    });

    return patterns;
  }

  Future<Map<String, dynamic>> _createFileIndex(Directory directory) async {
    final index = <String, dynamic>{
      'files': <Map<String, dynamic>>[],
      'searchIndex': <String, List<String>>{},
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _traverseDirectory(directory, (entity, depth) async {
      if (entity is File && _isTextFile(entity.path)) {
        try {
          final stat = await entity.stat();
          final relativePath = entity.path.replaceFirst(directory.path, '');
          
          final fileInfo = {
            'path': relativePath,
            'fullPath': entity.path,
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
            'extension': _getFileExtension(entity.path),
            'language': _getLanguageFromExtension(_getFileExtension(entity.path)),
          };

          index['files'].add(fileInfo);

          // Create search index
          if (stat.size < _maxFileSize) {
            try {
              final content = await entity.readAsString();
              final keywords = _extractKeywords(content);
              index['searchIndex'][relativePath] = keywords;
            } catch (e) {
              // Skip files that can't be read as text
            }
          }
        } catch (e) {
          // Skip files that can't be analyzed
        }
      }
    });

    return index;
  }

  Future<List<Map<String, dynamic>>> searchInCodebase(
    String repositoryPath,
    String query,
    List<String>? fileTypes,
  ) async {
    final results = <Map<String, dynamic>>[];
    final directory = Directory(repositoryPath);
    
    if (!directory.existsSync()) {
      return results;
    }

    final queryLower = query.toLowerCase();
    final searchTerms = queryLower.split(' ').where((term) => term.isNotEmpty).toList();

    await _traverseDirectory(directory, (entity, depth) async {
      if (entity is File && _isTextFile(entity.path)) {
        // Filter by file types if specified
        if (fileTypes != null && fileTypes.isNotEmpty) {
          final extension = _getFileExtension(entity.path);
          if (!fileTypes.contains(extension)) return;
        }

        try {
          final content = await entity.readAsString();
          final lines = content.split('\n');
          
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            final lineLower = line.toLowerCase();
            
            // Check if line contains all search terms
            if (searchTerms.every((term) => lineLower.contains(term))) {
              results.add({
                'file': entity.path.replaceFirst(repositoryPath, ''),
                'line': i + 1,
                'content': line.trim(),
                'context': _getContext(lines, i),
              });
            }
          }
        } catch (e) {
          // Skip files that can't be read
        }
      }
    });

    return results;
  }

  Future<void> _traverseDirectory(
    Directory directory,
    Function(FileSystemEntity entity, int depth) callback,
    [int depth = 0]
  ) async {
    try {
      await for (final entity in directory.list()) {
        if (_shouldIgnore(entity.path)) continue;

        await callback(entity, depth);

        if (entity is Directory && depth < 20) { // Prevent infinite recursion
          await _traverseDirectory(entity, callback, depth + 1);
        }
      }
    } catch (e) {
      // Skip directories that can't be accessed
    }
  }

  bool _shouldIgnore(String path) {
    final pathLower = path.toLowerCase();
    return _ignorePatterns.any((pattern) => pathLower.contains(pattern));
  }

  bool _isTextFile(String path) {
    final extension = _getFileExtension(path);
    return _textFileExtensions.contains(extension) || 
           _configFiles.contains(path.split('/').last);
  }

  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }

  String _getLanguageFromExtension(String extension) {
    switch (extension) {
      case '.dart': return 'Dart';
      case '.py': return 'Python';
      case '.js': return 'JavaScript';
      case '.ts': return 'TypeScript';
      case '.tsx': return 'TypeScript JSX';
      case '.jsx': return 'JavaScript JSX';
      case '.java': return 'Java';
      case '.kt': return 'Kotlin';
      case '.swift': return 'Swift';
      case '.go': return 'Go';
      case '.rs': return 'Rust';
      case '.cpp': case '.c': case '.h': case '.hpp': return 'C/C++';
      case '.html': return 'HTML';
      case '.css': case '.scss': case '.sass': return 'CSS';
      case '.vue': return 'Vue';
      case '.svelte': return 'Svelte';
      case '.json': return 'JSON';
      case '.yaml': case '.yml': return 'YAML';
      case '.xml': return 'XML';
      case '.md': return 'Markdown';
      case '.sql': return 'SQL';
      case '.sh': return 'Shell';
      default: return 'Other';
    }
  }

  String _getPrimaryLanguage(Map<String, int> languages) {
    if (languages.isEmpty) return 'Unknown';
    
    var maxCount = 0;
    var primaryLanguage = 'Unknown';
    
    languages.forEach((language, count) {
      if (count > maxCount) {
        maxCount = count;
        primaryLanguage = language;
      }
    });
    
    return primaryLanguage;
  }

  Future<int> _countLines(File file) async {
    try {
      final content = await file.readAsString();
      return content.split('\n').length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<String>> _extractDependencies(File file, String fileName) async {
    try {
      final content = await file.readAsString();
      final dependencies = <String>[];

      switch (fileName) {
        case 'package.json':
          final json = jsonDecode(content);
          if (json['dependencies'] != null) {
            dependencies.addAll((json['dependencies'] as Map).keys.cast<String>());
          }
          if (json['devDependencies'] != null) {
            dependencies.addAll((json['devDependencies'] as Map).keys.cast<String>());
          }
          break;
        case 'pubspec.yaml':
          final lines = content.split('\n');
          bool inDependencies = false;
          for (final line in lines) {
            if (line.trim() == 'dependencies:') {
              inDependencies = true;
              continue;
            }
            if (inDependencies && line.startsWith('  ') && line.contains(':')) {
              final depName = line.trim().split(':')[0];
              if (!depName.startsWith('#')) {
                dependencies.add(depName);
              }
            } else if (inDependencies && !line.startsWith('  ')) {
              inDependencies = false;
            }
          }
          break;
        case 'requirements.txt':
          final lines = content.split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
              final depName = trimmed.split('==')[0].split('>=')[0].split('<=')[0];
              dependencies.add(depName);
            }
          }
          break;
      }

      return dependencies;
    } catch (e) {
      return [];
    }
  }

  String _getPackageManager(String fileName) {
    switch (fileName) {
      case 'package.json': return 'npm';
      case 'pubspec.yaml': return 'pub';
      case 'requirements.txt': return 'pip';
      case 'Cargo.toml': return 'cargo';
      case 'go.mod': return 'go modules';
      case 'Gemfile': return 'bundler';
      case 'composer.json': return 'composer';
      default: return 'unknown';
    }
  }

  Future<int> _analyzeComplexity(File file) async {
    try {
      final content = await file.readAsString();
      int complexity = 1; // Base complexity

      // Simple complexity metrics
      complexity += 'if '.allMatches(content).length;
      complexity += 'else'.allMatches(content).length;
      complexity += 'while '.allMatches(content).length;
      complexity += 'for '.allMatches(content).length;
      complexity += 'switch '.allMatches(content).length;
      complexity += 'case '.allMatches(content).length;
      complexity += 'catch '.allMatches(content).length;
      complexity += '&& '.allMatches(content).length;
      complexity += '|| '.allMatches(content).length;

      return complexity;
    } catch (e) {
      return 0;
    }
  }

  List<int> _getLargestFiles(List<int> fileSizes) {
    fileSizes.sort((a, b) => b.compareTo(a));
    return fileSizes.take(10).toList();
  }

  List<String> _extractKeywords(String content) {
    final keywords = <String>{};
    final words = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();
    
    keywords.addAll(words);
    
    // Extract function and class names (simplified)
    final functionPattern = RegExp(r'\b(?:function|def|class|interface|enum)\s+(\w+)', caseSensitive: false);
    for (final match in functionPattern.allMatches(content)) {
      keywords.add(match.group(1)!.toLowerCase());
    }
    
    return keywords.toList();
  }

  List<String> _getContext(List<String> lines, int lineIndex) {
    final context = <String>[];
    final start = (lineIndex - 2).clamp(0, lines.length);
    final end = (lineIndex + 3).clamp(0, lines.length);
    
    for (int i = start; i < end; i++) {
      context.add('${i + 1}: ${lines[i]}');
    }
    
    return context;
  }
}