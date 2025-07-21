import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/agent_task.dart';
import '../widgets/git_operations_widget.dart';
import '../services/github_service.dart';
import '../models/repository.dart';

class TaskCard extends StatelessWidget {
  final AgentTask task;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final Repository? repository;
  final GitHubService? githubService;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onCancel,
    this.repository,
    this.githubService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildDescription(),
            const SizedBox(height: 10),
            if (task.isRunning) _buildProgress(),
            if (task.isRunning) const SizedBox(height: 10),
            _buildFooter(),
            // Add git operations section for completed tasks
            if (task.isCompleted && repository != null && githubService != null) ...[
              const SizedBox(height: 12),
              _buildGitOperationsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getStatusGradient(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.typeDisplayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.statusDisplayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onCancel != null && task.canCancel)
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                CupertinoIcons.xmark,
                size: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      task.description,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(task.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: task.progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(_getStatusColor()),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          CupertinoIcons.clock,
          size: 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(task.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
        ),
        if (task.duration != null) ...[
          const SizedBox(width: 12),
          Icon(
            CupertinoIcons.timer,
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(task.duration!),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const Spacer(),
        if (task.priority != TaskPriority.normal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priorityDisplayName,
              style: TextStyle(
                fontSize: 10,
                color: _getPriorityColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGitOperationsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Task Completed - Update Repository',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickGitActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickGitActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildGitActionButton(
            'Commit',
            Icons.save, // Changed to valid save icon
            Colors.blue,
            () => _showGitOperations(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGitActionButton(
            'Push',
            Icons.upload_rounded,
            Colors.green,
            () => _showGitOperations(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGitActionButton(
            'Pull',
            Icons.download_rounded,
            Colors.orange,
            () => _showGitOperations(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGitActionButton(
            'More',
            Icons.more_horiz,
            Colors.purple,
            () => _showGitOperations(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGitActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        minimumSize: const Size(0, 32),
      ),
    );
  }

  void _showGitOperations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Git Operations - ${repository!.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
                             Expanded(
                 child: GitOperationsWidget(
                   repository: repository!,
                   githubService: githubService!,
                   completedTask: task,
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.pending:
        return Colors.grey.shade600;
      case TaskStatus.thinking:
        return const Color(0xFF007AFF); // iOS Blue
      case TaskStatus.planning:
        return const Color(0xFFFF9500); // iOS Orange
      case TaskStatus.executing:
        return const Color(0xFF5856D6); // iOS Purple
      case TaskStatus.completed:
        return const Color(0xFF34C759); // iOS Green
      case TaskStatus.failed:
        return const Color(0xFFFF3B30); // iOS Red
      case TaskStatus.cancelled:
        return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return CupertinoIcons.clock;
      case TaskStatus.thinking:
        return CupertinoIcons.lightbulb; // Changed to valid thinking icon
      case TaskStatus.planning:
        return CupertinoIcons.list_bullet_below_rectangle; // Changed to valid planning icon
      case TaskStatus.executing:
        return CupertinoIcons.play_fill;
      case TaskStatus.completed:
        return CupertinoIcons.checkmark_circle_fill;
      case TaskStatus.failed:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case TaskStatus.cancelled:
        return CupertinoIcons.xmark_circle_fill;
    }
  }

  Color _getTypeColor() {
    switch (task.type) {
      case TaskType.codeGeneration:
        return const Color(0xFF007AFF); // iOS Blue
      case TaskType.codeReview:
        return const Color(0xFF5856D6); // iOS Purple
      case TaskType.refactoring:
        return const Color(0xFFFF9500); // iOS Orange
      case TaskType.bugFix:
        return const Color(0xFFFF3B30); // iOS Red
      case TaskType.testing:
        return const Color(0xFF34C759); // iOS Green
      case TaskType.documentation:
        return const Color(0xFF5AC8FA); // iOS Light Blue
      case TaskType.gitOperation:
        return const Color(0xFF8E8E93); // iOS Gray
      case TaskType.fileOperation:
        return const Color(0xFFAF52DE); // iOS Purple2
      case TaskType.analysis:
        return const Color(0xFF007AFF); // iOS Blue
      case TaskType.custom:
        return const Color(0xFFFF2D92); // iOS Pink
    }
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return const Color(0xFF34C759); // iOS Green
      case TaskPriority.normal:
        return const Color(0xFF007AFF); // iOS Blue
      case TaskPriority.high:
        return const Color(0xFFFF9500); // iOS Orange
      case TaskPriority.critical:
        return const Color(0xFFFF3B30); // iOS Red
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  List<Color> _getStatusGradient() {
    switch (task.status) {
      case TaskStatus.pending:
        return [Colors.grey.shade500, Colors.grey.shade600];
      case TaskStatus.thinking:
        return [const Color(0xFF007AFF), const Color(0xFF5856D6)];
      case TaskStatus.planning:
        return [const Color(0xFFFF9500), const Color(0xFFFF6B35)];
      case TaskStatus.executing:
        return [const Color(0xFF5856D6), const Color(0xFFAF52DE)];
      case TaskStatus.completed:
        return [const Color(0xFF34C759), const Color(0xFF30D158)];
      case TaskStatus.failed:
        return [const Color(0xFFFF3B30), const Color(0xFFD70015)];
      case TaskStatus.cancelled:
        return [Colors.grey.shade400, Colors.grey.shade500];
    }
  }
}