class Repository {
  final String id;
  final String name;
  final String fullName;
  final String? description;
  final String htmlUrl;
  final String cloneUrl;
  final String defaultBranch;
  final String language;
  final int stargazersCount;
  final int forksCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate;
  final bool isFork;
  final String? owner;
  final String? ownerAvatarUrl;
  final int size;
  final bool hasIssues;
  final bool hasProjects;
  final bool hasWiki;
  final int openIssuesCount;

  Repository({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.htmlUrl,
    required this.cloneUrl,
    required this.defaultBranch,
    required this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isPrivate,
    required this.isFork,
    this.owner,
    this.ownerAvatarUrl,
    required this.size,
    required this.hasIssues,
    required this.hasProjects,
    required this.hasWiki,
    required this.openIssuesCount,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      fullName: json['full_name'] ?? '',
      description: json['description'],
      htmlUrl: json['html_url'] ?? '',
      cloneUrl: json['clone_url'] ?? '',
      defaultBranch: json['default_branch'] ?? 'main',
      language: json['language'] ?? 'Unknown',
      stargazersCount: json['stargazers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isPrivate: json['private'] ?? false,
      isFork: json['fork'] ?? false,
      owner: json['owner']?['login'],
      ownerAvatarUrl: json['owner']?['avatar_url'],
      size: json['size'] ?? 0,
      hasIssues: json['has_issues'] ?? false,
      hasProjects: json['has_projects'] ?? false,
      hasWiki: json['has_wiki'] ?? false,
      openIssuesCount: json['open_issues_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'description': description,
      'html_url': htmlUrl,
      'clone_url': cloneUrl,
      'default_branch': defaultBranch,
      'language': language,
      'stargazers_count': stargazersCount,
      'forks_count': forksCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'private': isPrivate,
      'fork': isFork,
      'owner': {
        'login': owner,
        'avatar_url': ownerAvatarUrl,
      },
      'size': size,
      'has_issues': hasIssues,
      'has_projects': hasProjects,
      'has_wiki': hasWiki,
      'open_issues_count': openIssuesCount,
    };
  }

  Repository copyWith({
    String? id,
    String? name,
    String? fullName,
    String? description,
    String? htmlUrl,
    String? cloneUrl,
    String? defaultBranch,
    String? language,
    int? stargazersCount,
    int? forksCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    bool? isFork,
    String? owner,
    String? ownerAvatarUrl,
    int? size,
    bool? hasIssues,
    bool? hasProjects,
    bool? hasWiki,
    int? openIssuesCount,
  }) {
    return Repository(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      cloneUrl: cloneUrl ?? this.cloneUrl,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      language: language ?? this.language,
      stargazersCount: stargazersCount ?? this.stargazersCount,
      forksCount: forksCount ?? this.forksCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isFork: isFork ?? this.isFork,
      owner: owner ?? this.owner,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      size: size ?? this.size,
      hasIssues: hasIssues ?? this.hasIssues,
      hasProjects: hasProjects ?? this.hasProjects,
      hasWiki: hasWiki ?? this.hasWiki,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
    );
  }

  @override
  String toString() {
    return 'Repository(name: $name, fullName: $fullName, language: $language, stars: $stargazersCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Repository && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}