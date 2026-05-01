import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Job Card Widget ───────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;
  final bool? isBookmarked;
  final VoidCallback? onBookmark;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.isBookmarked,
    this.onBookmark,
  });

  String _formatSalary() {
    final min = job['salary_min'];
    final max = job['salary_max'];
    if (min == null && max == null) return 'Not disclosed';
    String fmt(num n) => n >= 100000
      ? '₹${(n / 100000).toStringAsFixed(1)}L'
      : '₹${n.toStringAsFixed(0)}';
    if (min != null && max != null) return '${fmt(min)} – ${fmt(max)}';
    if (min != null) return 'From ${fmt(min)}';
    return 'Up to ${fmt(max)}';
  }

  Color _deptColor() => AppTheme.getDeptColor(job['department']);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dept = job['department'];
    final deptColor = _deptColor();
    final skills = (job['skills'] as String? ?? '')
      .split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).take(3).toList();
    final matchScore = job['match_score'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: deptColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (job['company'] as String? ?? 'C').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: deptColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job['company'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onBookmark != null)
                    IconButton(
                      icon: Icon(
                        isBookmarked == true ? Icons.bookmark : Icons.bookmark_outline,
                        color: isBookmarked == true ? AppTheme.primary : Colors.grey,
                        size: 22,
                      ),
                      onPressed: onBookmark,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Tags row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (dept != null && dept != 'General')
                    _Tag(dept, color: deptColor, filled: true),
                  _Tag(job['job_type'] ?? ''),
                  _Tag('${job['experience_min'] ?? 0}–${job['experience_max'] ?? 0} yrs'),
                  if (matchScore != null)
                    _Tag('${matchScore.toStringAsFixed(0)}% match',
                      color: Colors.green, filled: true),
                ],
              ),
              const SizedBox(height: 10),

              // Location & Salary
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                    size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job['location'] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Text(
                    _formatSalary(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: skills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )).toList(),
                ),
              ],

              // Footer
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people_outline,
                    size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${job['openings'] ?? 1} opening${(job['openings'] ?? 1) > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(job['created_at']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) { return ''; }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool filled;
  const _Tag(this.label, {this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: filled ? Border.all(color: c.withOpacity(0.3), width: 1) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? c : Colors.grey[600],
        ),
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color {
    switch (status) {
      case 'shortlisted': return Colors.blue;
      case 'interviewed': return Colors.purple;
      case 'hired': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String get _label {
    switch (status) {
      case 'shortlisted': return 'Shortlisted';
      case 'interviewed': return 'Interviewed';
      case 'hired': return '🎉 Hired';
      case 'rejected': return 'Rejected';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withOpacity(0.4)),
    ),
    child: Text(
      _label,
      style: TextStyle(
        color: _color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

// ─── Loading Shimmer ──────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(44, 44, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(16, double.infinity),
                      const SizedBox(height: 6),
                      _shimmerBox(12, 120),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _shimmerBox(12, 200),
            const SizedBox(height: 8),
            _shimmerBox(12, 160),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 6}) =>
    Container(
      height: height,
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
}

// ─── App Text Field ───────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        maxLines: maxLines,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon,
          suffix: suffix,
        ),
      ),
    ],
  );
}

// ─── Section Header ───────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    ),
  );
}

// ─── Empty State ──────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.primary.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

// ─── Error View ───────────────────────────────────────────────────────
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}
