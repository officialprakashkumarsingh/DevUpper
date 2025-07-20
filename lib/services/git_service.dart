import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GitService {
  static GitService? _instance;
  GitService._internal();
  
  static GitService get instance {
    _instance ??= GitService._internal();
    return _instance!;
  }

  String? _currentRepoPath;
  String? get currentRepoPath => _currentRepoPath;

  /// Initialize git repository at the given path
  Future<bool> initRepository(String repoPath) async {
    try {
      _currentRepoPath = repoPath;
      
      // Check if .git directory exists
      final gitDir = Directory(path.join(repoPath, '.git'));
      if (!gitDir.existsSync()) {
        final result = await Process.run('git', ['init'], workingDirectory: repoPath);
        return result.exitCode == 0;
      }
      return true;
    } catch (e) {
      print('Error initializing repository: $e');
      return false;
    }
  }

  /// Clone a repository from GitHub
  Future<String?> cloneRepository({
    required String repoUrl,
    required String localPath,
    String? token,
  }) async {
    try {
      // Create the local directory if it doesn't exist
      final dir = Directory(localPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      List<String> args = ['clone'];
      
      // Add authentication if token is provided
      if (token != null) {
        final authenticatedUrl = repoUrl.replaceFirst(
          'https://',
          'https://$token@',
        );
        args.add(authenticatedUrl);
      } else {
        args.add(repoUrl);
      }
      
      args.add(localPath);

      final result = await Process.run('git', args);
      
      if (result.exitCode == 0) {
        _currentRepoPath = localPath;
        return localPath;
      } else {
        throw Exception('Git clone failed: ${result.stderr}');
      }
    } catch (e) {
      print('Error cloning repository: $e');
      return null;
    }
  }

  /// Get current branch name
  Future<String?> getCurrentBranch() async {
    if (_currentRepoPath == null) return null;
    
    try {
      final result = await Process.run(
        'git',
        ['branch', '--show-current'],
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      print('Error getting current branch: $e');
      return null;
    }
  }

  /// Get git status
  Future<Map<String, dynamic>?> getStatus() async {
    if (_currentRepoPath == null) return null;
    
    try {
      final result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n').where((line) => line.isNotEmpty).toList();
        
        final modified = <String>[];
        final added = <String>[];
        final deleted = <String>[];
        final untracked = <String>[];
        
        for (final line in lines) {
          if (line.length >= 3) {
            final status = line.substring(0, 2);
            final file = line.substring(3);
            
            if (status.startsWith('M')) {
              modified.add(file);
            } else if (status.startsWith('A')) {
              added.add(file);
            } else if (status.startsWith('D')) {
              deleted.add(file);
            } else if (status.startsWith('??')) {
              untracked.add(file);
            }
          }
        }
        
        return {
          'modified': modified,
          'added': added,
          'deleted': deleted,
          'untracked': untracked,
          'clean': lines.isEmpty,
        };
      }
      return null;
    } catch (e) {
      print('Error getting git status: $e');
      return null;
    }
  }

  /// Add files to staging area
  Future<bool> addFiles(List<String> files) async {
    if (_currentRepoPath == null) return false;
    
    try {
      final args = ['add', ...files];
      final result = await Process.run(
        'git',
        args,
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error adding files: $e');
      return false;
    }
  }

  /// Add all files to staging area
  Future<bool> addAll() async {
    if (_currentRepoPath == null) return false;
    
    try {
      final result = await Process.run(
        'git',
        ['add', '.'],
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error adding all files: $e');
      return false;
    }
  }

  /// Commit changes
  Future<bool> commit(String message, {String? author}) async {
    if (_currentRepoPath == null) return false;
    
    try {
      List<String> args = ['commit', '-m', message];
      
      if (author != null) {
        args.addAll(['--author', author]);
      }
      
      final result = await Process.run(
        'git',
        args,
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error committing: $e');
      return false;
    }
  }

  /// Pull from remote
  Future<bool> pull({String? remote, String? branch}) async {
    if (_currentRepoPath == null) return false;
    
    try {
      List<String> args = ['pull'];
      
      if (remote != null) {
        args.add(remote);
        if (branch != null) {
          args.add(branch);
        }
      }
      
      final result = await Process.run(
        'git',
        args,
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error pulling: $e');
      return false;
    }
  }

  /// Push to remote
  Future<bool> push({String? remote, String? branch}) async {
    if (_currentRepoPath == null) return false;
    
    try {
      List<String> args = ['push'];
      
      if (remote != null) {
        args.add(remote);
        if (branch != null) {
          args.add(branch);
        }
      }
      
      final result = await Process.run(
        'git',
        args,
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error pushing: $e');
      return false;
    }
  }

  /// Create a new branch
  Future<bool> createBranch(String branchName, {bool checkout = true}) async {
    if (_currentRepoPath == null) return false;
    
    try {
      List<String> args = ['branch', branchName];
      
      final result = await Process.run(
        'git',
        args,
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0 && checkout) {
        return await checkoutBranch(branchName);
      }
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error creating branch: $e');
      return false;
    }
  }

  /// Checkout a branch
  Future<bool> checkoutBranch(String branchName) async {
    if (_currentRepoPath == null) return false;
    
    try {
      final result = await Process.run(
        'git',
        ['checkout', branchName],
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error checking out branch: $e');
      return false;
    }
  }

  /// Get list of branches
  Future<List<String>> getBranches() async {
    if (_currentRepoPath == null) return [];
    
    try {
      final result = await Process.run(
        'git',
        ['branch', '-a'],
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return output
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceFirst('*', '').trim())
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting branches: $e');
      return [];
    }
  }

  /// Get commit history
  Future<List<Map<String, dynamic>>> getCommitHistory({int limit = 10}) async {
    if (_currentRepoPath == null) return [];
    
    try {
      final result = await Process.run(
        'git',
        ['log', '--oneline', '-n', limit.toString(), '--pretty=format:%H|%an|%ad|%s'],
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return output
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) {
              final parts = line.split('|');
              if (parts.length >= 4) {
                return {
                  'hash': parts[0],
                  'author': parts[1],
                  'date': parts[2],
                  'message': parts.skip(3).join('|'),
                };
              }
              return <String, dynamic>{};
            })
            .where((commit) => commit.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting commit history: $e');
      return [];
    }
  }

  /// Set remote URL
  Future<bool> setRemoteUrl(String remoteName, String url, {String? token}) async {
    if (_currentRepoPath == null) return false;
    
    try {
      String authenticatedUrl = url;
      if (token != null && url.startsWith('https://')) {
        authenticatedUrl = url.replaceFirst('https://', 'https://$token@');
      }
      
      final result = await Process.run(
        'git',
        ['remote', 'set-url', remoteName, authenticatedUrl],
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error setting remote URL: $e');
      return false;
    }
  }

  /// Get remote URLs
  Future<Map<String, String>> getRemotes() async {
    if (_currentRepoPath == null) return {};
    
    try {
      final result = await Process.run(
        'git',
        ['remote', '-v'],
        workingDirectory: _currentRepoPath,
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final remotes = <String, String>{};
        
        for (final line in output.split('\n')) {
          if (line.trim().isNotEmpty && line.contains('\t')) {
            final parts = line.split('\t');
            if (parts.length >= 2) {
              final name = parts[0];
              final url = parts[1].split(' ')[0]; // Remove (fetch)/(push)
              remotes[name] = url;
            }
          }
        }
        
        return remotes;
      }
      return {};
    } catch (e) {
      print('Error getting remotes: $e');
      return {};
    }
  }

  /// Merge branch
  Future<bool> merge(String branchName) async {
    if (_currentRepoPath == null) return false;
    
    try {
      final result = await Process.run(
        'git',
        ['merge', branchName],
        workingDirectory: _currentRepoPath,
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error merging: $e');
      return false;
    }
  }

  /// Check if git is available on the system
  Future<bool> isGitAvailable() async {
    try {
      final result = await Process.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get a default local repository path
  Future<String> getDefaultRepoPath(String repoName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'repositories', repoName);
  }
}