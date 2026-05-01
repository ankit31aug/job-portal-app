import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'apply_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Map<String, dynamic>? _job;
  bool _loading = true;
  String? _error;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _loadBookmarkState();
  }

  Future<void> _loadJob() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getJob(widget.jobId);
      setState(() { _job = Map<String, dynamic>.from(data); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadBookmarkState() async {
    if (ApiService.currentToken == null) return;
    try {
      final bookmarked = await ApiService.isBookmarked(widget.jobId);
      if (mounted) setState(() => _bookmarked = bookmarked);
    } catch (_) {
      // ignore — public viewing without auth is fine
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final newState = await ApiService.toggleBookmark(widget.jobId);
      if (!mounted) return;
      setState(() => _bookmarked = newState);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newState ? 'Job saved!' : 'Removed from saved'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update bookmark: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatSalary() {
    if (_job == null) return '';
    final min = _job!['salary_min'];
    final max = _job!['salary_max'];
    if (min == null && max == null) return 'Salary not disclosed';
    String fmt(num n) => n >= 100000 ? '₹${(n / 100000).toStringAsFixed(1)}L' : '₹${n.toStringAsFixed(0)}';
    if (min != null && max != null) return '${fmt(min)} – ${fmt(max)} per annum';
    if (min != null) return 'From ${fmt(min)} per annum';
    return 'Up to ${fmt(max)} per annum';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isJobseeker = auth.user?.isJobseeker ?? true;
    final dept = _job?['department'];
    final deptColor = AppTheme.getDeptColor(dept);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Scaffold(
              appBar: AppBar(),
              body: ErrorView(message: _error!, onRetry: _loadJob),
            )
          : CustomScrollView(
              slivers: [
                // ─── App Bar ─────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: _bookmarked ? AppTheme.primary : null,
                      ),
                      onPressed: isLoggedIn ? _toggleBookmark : () => Navigator.pushNamed(context, '/login'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Header Card ─────────────────────────────
                      Container(
                        color: theme.cardColor,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: deptColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (_job!['company'] as String? ?? 'C').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.w900, color: deptColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _job!['title'] ?? '',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _job!['company'] ?? '',
                                        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Tags
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                if (dept != null && dept != 'General')
                                  _InfoChip(dept, deptColor, filled: true),
                                _InfoChip(_job!['job_type'] ?? '', Colors.grey[600]!),
                                _InfoChip(_job!['category'] ?? '', Colors.grey[600]!),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // ─── Quick Info Grid ──────────────────────────
                      Container(
                        color: theme.cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            _QuickInfo(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: _job!['location'] ?? 'N/A',
                            ),
                            _divider(),
                            _QuickInfo(
                              icon: Icons.work_history_outlined,
                              label: 'Experience',
                              value: '${_job!['experience_min'] ?? 0}–${_job!['experience_max'] ?? 0} yrs',
                            ),
                            _divider(),
                            _QuickInfo(
                              icon: Icons.currency_rupee,
                              label: 'Salary',
                              value: _formatSalary(),
                            ),
                            _divider(),
                            _QuickInfo(
                              icon: Icons.people_outline,
                              label: 'Openings',
                              value: '${_job!['openings'] ?? 1}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ─── Description ──────────────────────────────
                      _Section(
                        title: 'Job Description',
                        child: Text(
                          _job!['description'] ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // ─── Requirements ─────────────────────────────
                      if ((_job!['requirements'] ?? '').isNotEmpty)
                        _Section(
                          title: 'Requirements',
                          child: Text(
                            _job!['requirements'],
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // ─── Skills ───────────────────────────────────
                      if ((_job!['skills'] ?? '').isNotEmpty)
                        _Section(
                          title: 'Required Skills',
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: (_job!['skills'] as String)
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .map((skill) => Chip(
                                label: Text(skill, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppTheme.primary.withOpacity(0.08),
                                side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                                labelStyle: const TextStyle(color: AppTheme.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              )).toList(),
                          ),
                        ),

                      const SizedBox(height: 100), // space for FAB
                    ],
                  ),
                ),
              ],
            ),

      // ─── Apply Button ───────────────────────────────────────────
      bottomNavigationBar: _job != null && (_job!['is_active'] == 1) && isJobseeker
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ElevatedButton(
                onPressed: () {
                  if (!isLoggedIn) {
                    Navigator.pushNamed(context, '/login');
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ApplyScreen(job: _job!),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: deptColor,
                ),
                child: const Text('Apply Now', style: TextStyle(fontSize: 16)),
              ),
            ),
          )
        : null,
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.grey[200]);
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _QuickInfo({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.cardColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _InfoChip(this.label, this.color, {this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: filled ? Border.all(color: color.withOpacity(0.3)) : null,
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: filled ? color : Colors.grey[600],
      ),
    ),
  );
}
