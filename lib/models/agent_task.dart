enum TaskStatus {
  pending,
  thinking,
  planning,
  executing,
  completed,
  failed,
  cancelled,
}

enum TaskType {
  codeGeneration,
  codeReview,
  refactoring,
  bugFix,
  testing,
  documentation,
  gitOperation,
  fileOperation,
  analysis,
  custom,
}

enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

class AgentTask {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? repositoryId;
  final String? filePath;
  final List<String> affectedFiles;
  final String? result;
  final String? error;
  final Map<String, dynamic> metadata;
  final List<TaskStep> steps;
  final double progress;
  final int estimatedDuration; // in minutes
  final String? assignedAgent;

  AgentTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.normal,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.repositoryId,
    this.filePath,
    this.affectedFiles = const [],
    this.result,
    this.error,
    this.metadata = const {},
    this.steps = const [],
    this.progress = 0.0,
    this.estimatedDuration = 5,
    this.assignedAgent,
  });

  factory AgentTask.fromJson(Map<String, dynamic> json) {
    return AgentTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.custom,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.normal,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      repositoryId: json['repository_id'],
      filePath: json['file_path'],
      affectedFiles: List<String>.from(json['affected_files'] ?? []),
      result: json['result'],
      error: json['error'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((step) => TaskStep.fromJson(step))
          .toList() ?? [],
      progress: (json['progress'] ?? 0.0).toDouble(),
      estimatedDuration: json['estimated_duration'] ?? 5,
      assignedAgent: json['assigned_agent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'repository_id': repositoryId,
      'file_path': filePath,
      'affected_files': affectedFiles,
      'result': result,
      'error': error,
      'metadata': metadata,
      'steps': steps.map((step) => step.toJson()).toList(),
      'progress': progress,
      'estimated_duration': estimatedDuration,
      'assigned_agent': assignedAgent,
    };
  }

  AgentTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? repositoryId,
    String? filePath,
    List<String>? affectedFiles,
    String? result,
    String? error,
    Map<String, dynamic>? metadata,
    List<TaskStep>? steps,
    double? progress,
    int? estimatedDuration,
    String? assignedAgent,
  }) {
    return AgentTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      repositoryId: repositoryId ?? this.repositoryId,
      filePath: filePath ?? this.filePath,
      affectedFiles: affectedFiles ?? this.affectedFiles,
      result: result ?? this.result,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      steps: steps ?? this.steps,
      progress: progress ?? this.progress,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      assignedAgent: assignedAgent ?? this.assignedAgent,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.thinking:
        return 'Thinking...';
      case TaskStatus.planning:
        return 'Planning';
      case TaskStatus.executing:
        return 'Executing';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeDisplayName {
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

  String get priorityDisplayName {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isFailed => status == TaskStatus.failed;
  bool get isRunning => [TaskStatus.thinking, TaskStatus.planning, TaskStatus.executing].contains(status);
  bool get canCancel => [TaskStatus.pending, TaskStatus.thinking, TaskStatus.planning, TaskStatus.executing].contains(status);

  @override
  String toString() {
    return 'AgentTask(id: $id, title: $title, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TaskStep {
  final String id;
  final String name;
  final String description;
  final TaskStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? result;
  final String? error;
  final Map<String, dynamic> metadata;

  TaskStep({
    required this.id,
    required this.name,
    required this.description,
    this.status = TaskStatus.pending,
    this.startedAt,
    this.completedAt,
    this.result,
    this.error,
    this.metadata = const {},
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      result: json['result'],
      error: json['error'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result': result,
      'error': error,
      'metadata': metadata,
    };
  }

  TaskStep copyWith({
    String? id,
    String? name,
    String? description,
    TaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? result,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return TaskStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isFailed => status == TaskStatus.failed;
  bool get isRunning => [TaskStatus.thinking, TaskStatus.planning, TaskStatus.executing].contains(status);

  @override
  String toString() {
    return 'TaskStep(id: $id, name: $name, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskStep && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}