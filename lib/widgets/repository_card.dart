import 'package:flutter/material.dart';
import '../models/repository.dart';

class RepositoryCard extends StatelessWidget {
  final Repository repository;
  final VoidCallback onTap;

  const RepositoryCard({
    super.key,
    required this.repository,
    required this.onTap,
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
            if (repository.description != null) ...[
              const SizedBox(height: 8),
              _buildDescription(),
            ],
            const SizedBox(height: 12),
            _buildMetrics(),
            const SizedBox(height: 12),
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
            color: _getLanguageColor(repository.language),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getLanguageIcon(repository.language),
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
                repository.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                repository.fullName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (repository.isPrivate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Private',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      repository.description!,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        _buildMetric(
          icon: Icons.star_outline,
          value: repository.stargazersCount.toString(),
          color: Colors.amber.shade600,
        ),
        const SizedBox(width: 16),
        _buildMetric(
          icon: Icons.fork_right,
          value: repository.forksCount.toString(),
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 16),
        _buildMetric(
          icon: Icons.bug_report_outlined,
          value: repository.openIssuesCount.toString(),
          color: Colors.red.shade600,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getLanguageColor(repository.language).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            repository.language,
            style: TextStyle(
              fontSize: 12,
              color: _getLanguageColor(repository.language),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
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
          'Updated ${_formatDate(repository.updatedAt)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const Spacer(),
        if (repository.isFork)
          Row(
            children: [
              Icon(
                Icons.fork_right,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                'Fork',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF0175C2);
      case 'python':
        return const Color(0xFF3776AB);
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'java':
        return const Color(0xFFED8B00);
      case 'kotlin':
        return const Color(0xFF7F52FF);
      case 'swift':
        return const Color(0xFFFA7343);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'rust':
        return const Color(0xFF000000);
      case 'cpp':
      case 'c++':
        return const Color(0xFF00599C);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
        return const Color(0xFF1572B6);
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getLanguageIcon(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return Icons.flutter_dash;
      case 'python':
        return Icons.code;
      case 'javascript':
      case 'typescript':
        return Icons.javascript;
      case 'java':
      case 'kotlin':
        return Icons.coffee;
      case 'swift':
        return Icons.phone_iphone;
      case 'go':
        return Icons.speed;
      case 'rust':
        return Icons.security;
      case 'cpp':
      case 'c++':
        return Icons.memory;
      case 'html':
      case 'css':
        return Icons.web;
      default:
        return Icons.code;
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
}