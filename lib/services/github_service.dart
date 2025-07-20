import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/repository.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  String? _token;
  String? _username;

  bool get isAuthenticated => _token != null;
  String? get username => _username;

  Future<bool> authenticate(String token) async {
    try {
      _token = token;
      
      // Verify token by getting user info
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _username = data['login'];
        return true;
      } else {
        _token = null;
        _username = null;
        return false;
      }
    } catch (e) {
      _token = null;
      _username = null;
      return false;
    }
  }

  void logout() {
    _token = null;
    _username = null;
  }

  Future<List<Repository>> fetchUserRepositories() async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final repositories = <Repository>[];
      int page = 1;
      const int perPage = 100;

      while (true) {
        final response = await http.get(
          Uri.parse('$_baseUrl/user/repos?page=$page&per_page=$perPage&sort=updated&type=all'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          
          if (data.isEmpty) break;

          for (final repoData in data) {
            repositories.add(Repository.fromJson(repoData));
          }

          page++;
        } else {
          throw Exception('Failed to fetch repositories: ${response.statusCode}');
        }
      }

      return repositories;
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Repository>> searchRepositories(String query) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/repositories?q=$query+user:$_username&sort=updated&order=desc'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        return items.map((item) => Repository.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search repositories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub Search Error: $e');
    }
  }

  Future<Repository> getRepository(String owner, String name) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$name'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        return Repository.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get repository: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBranches(String owner, String repo) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/branches'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((branch) => {
          'name': branch['name'],
          'sha': branch['commit']['sha'],
          'protected': branch['protected'] ?? false,
        }).toList();
      } else {
        throw Exception('Failed to get branches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCommits(String owner, String repo, {String? branch, int? limit}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      String url = '$_baseUrl/repos/$owner/$repo/commits';
      final queryParams = <String>[];
      
      if (branch != null) queryParams.add('sha=$branch');
      if (limit != null) queryParams.add('per_page=$limit');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((commit) => {
          'sha': commit['sha'],
          'message': commit['commit']['message'],
          'author': commit['commit']['author']['name'],
          'date': commit['commit']['author']['date'],
          'url': commit['html_url'],
        }).toList();
      } else {
        throw Exception('Failed to get commits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getIssues(String owner, String repo, {String state = 'open'}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/issues?state=$state'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.where((issue) => issue['pull_request'] == null).map((issue) => {
          'number': issue['number'],
          'title': issue['title'],
          'body': issue['body'],
          'state': issue['state'],
          'created_at': issue['created_at'],
          'updated_at': issue['updated_at'],
          'user': issue['user']['login'],
          'labels': (issue['labels'] as List).map((label) => label['name']).toList(),
          'url': issue['html_url'],
        }).toList();
      } else {
        throw Exception('Failed to get issues: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPullRequests(String owner, String repo, {String state = 'open'}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/pulls?state=$state'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((pr) => {
          'number': pr['number'],
          'title': pr['title'],
          'body': pr['body'],
          'state': pr['state'],
          'created_at': pr['created_at'],
          'updated_at': pr['updated_at'],
          'user': pr['user']['login'],
          'head_branch': pr['head']['ref'],
          'base_branch': pr['base']['ref'],
          'url': pr['html_url'],
          'mergeable': pr['mergeable'],
          'merged': pr['merged'],
        }).toList();
      } else {
        throw Exception('Failed to get pull requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String head,
    required String base,
    String? body,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final requestBody = {
        'title': title,
        'head': head,
        'base': base,
        if (body != null) 'body': body,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/repos/$owner/$repo/pulls'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'number': data['number'],
          'title': data['title'],
          'url': data['html_url'],
          'head_branch': data['head']['ref'],
          'base_branch': data['base']['ref'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create pull request: ${error['message']}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<bool> mergePullRequest({
    required String owner,
    required String repo,
    required int pullNumber,
    String? commitTitle,
    String? commitMessage,
    String mergeMethod = 'merge',
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final requestBody = {
        if (commitTitle != null) 'commit_title': commitTitle,
        if (commitMessage != null) 'commit_message': commitMessage,
        'merge_method': mergeMethod,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/repos/$owner/$repo/pulls/$pullNumber/merge'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> createBranch({
    required String owner,
    required String repo,
    required String branchName,
    required String fromSha,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final requestBody = {
        'ref': 'refs/heads/$branchName',
        'sha': fromSha,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/repos/$owner/$repo/git/refs'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'ref': data['ref'],
          'sha': data['object']['sha'],
          'url': data['url'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create branch: ${error['message']}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> getFileContent({
    required String owner,
    required String repo,
    required String path,
    String? ref,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      String url = '$_baseUrl/repos/$owner/$repo/contents/$path';
      if (ref != null) url += '?ref=$ref';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'name': data['name'],
          'path': data['path'],
          'sha': data['sha'],
          'size': data['size'],
          'content': data['content'],
          'encoding': data['encoding'],
          'download_url': data['download_url'],
        };
      } else {
        throw Exception('Failed to get file content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateFile({
    required String owner,
    required String repo,
    required String path,
    required String message,
    required String content,
    required String sha,
    String? branch,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final requestBody = {
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        'sha': sha,
        if (branch != null) 'branch': branch,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'commit': data['commit'],
          'content': data['content'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to update file: ${error['message']}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> createFile({
    required String owner,
    required String repo,
    required String path,
    required String message,
    required String content,
    String? branch,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final requestBody = {
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        if (branch != null) 'branch': branch,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'commit': data['commit'],
          'content': data['content'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create file: ${error['message']}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRepositoryTree({
    required String owner,
    required String repo,
    String? treeSha,
    bool recursive = false,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      String url = '$_baseUrl/repos/$owner/$repo/git/trees/${treeSha ?? 'HEAD'}';
      if (recursive) url += '?recursive=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> tree = data['tree'];
        
        return tree.map((item) => {
          'path': item['path'],
          'mode': item['mode'],
          'type': item['type'],
          'sha': item['sha'],
          'size': item['size'],
          'url': item['url'],
        }).toList();
      } else {
        throw Exception('Failed to get repository tree: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<Map<String, dynamic>> forkRepository(String owner, String repo) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/repos/$owner/$repo/forks'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 202) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to fork repository: ${error['message']}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<bool> starRepository(String owner, String repo) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/starred/$owner/$repo'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<bool> unstarRepository(String owner, String repo) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/user/starred/$owner/$repo'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }

  Future<bool> isRepositoryStarred(String owner, String repo) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/starred/$owner/$repo'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GitHub API Error: $e');
    }
  }
}