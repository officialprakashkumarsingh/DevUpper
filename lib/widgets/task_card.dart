import 'package:flutter/material.dart';
import '../models/agent_task.dart';

class TaskCard extends StatelessWidget {
  final AgentTask task;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildDescription(),
            const SizedBox(height: 12),
            if (task.isRunning) _buildProgress(),
            if (task.isRunning) const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey[600],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      task.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.3,
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
        LinearProgressIndicator(
          value: task.progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(_getStatusColor()),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(task.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        if (task.duration != null) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.timer,
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(task.duration!),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
        const Spacer(),
        if (task.priority != TaskPriority.normal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
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

  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.pending:
        return Colors.grey.shade600;
      case TaskStatus.thinking:
        return Colors.blue.shade600;
      case TaskStatus.planning:
        return Colors.orange.shade600;
      case TaskStatus.executing:
        return Colors.purple.shade600;
      case TaskStatus.completed:
        return Colors.green.shade600;
      case TaskStatus.failed:
        return Colors.red.shade600;
      case TaskStatus.cancelled:
        return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.thinking:
        return Icons.psychology;
      case TaskStatus.planning:
        return Icons.map;
      case TaskStatus.executing:
        return Icons.play_arrow;
      case TaskStatus.completed:
        return Icons.check;
      case TaskStatus.failed:
        return Icons.error;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getTypeColor() {
    switch (task.type) {
      case TaskType.codeGeneration:
        return Colors.blue.shade600;
      case TaskType.codeReview:
        return Colors.purple.shade600;
      case TaskType.refactoring:
        return Colors.orange.shade600;
      case TaskType.bugFix:
        return Colors.red.shade600;
      case TaskType.testing:
        return Colors.green.shade600;
      case TaskType.documentation:
        return Colors.teal.shade600;
      case TaskType.gitOperation:
        return Colors.grey.shade700;
      case TaskType.fileOperation:
        return Colors.brown.shade600;
      case TaskType.analysis:
        return Colors.indigo.shade600;
      case TaskType.custom:
        return Colors.pink.shade600;
    }
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return Colors.green.shade600;
      case TaskPriority.normal:
        return Colors.blue.shade600;
      case TaskPriority.high:
        return Colors.orange.shade600;
      case TaskPriority.critical:
        return Colors.red.shade600;
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
}