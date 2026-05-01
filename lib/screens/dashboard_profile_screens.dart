import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'job_detail_screen.dart';

// ─── Dashboard / My Applications ─────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _bookmarks = [];
  bool _loadingApps = true;
  bool _loadingBookmarks = true;
  String? _errorApps;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadApplications();
    _loadBookmarks();
  }

  Future<void> _loadApplications() async {
    setState(() { _loadingApps = true; _errorApps = null; });
    try {
      // Backend returns array directly
      final list = await ApiService.getMyApplications();
      setState(() {
        _applications = List<Map<String, dynamic>>.from(list);
        _loadingApps = false;
      });
    } catch (e) {
      setState(() { _errorApps = e.toString(); _loadingApps = false; });
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loadingBookmarks = true);
    try {
      final list = await ApiService.getBookmarks();
      setState(() {
        _bookmarks = List<Map<String, dynamic>>.from(list);
        _loadingBookmarks = false;
      });
    } catch (_) {
      setState(() => _loadingBookmarks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Applications', icon: Icon(Icons.assignment_outlined, size: 18)),
            Tab(text: 'Saved Jobs', icon: Icon(Icons.bookmark_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Applications Tab
          _loadingApps
            ? const Center(child: CircularProgressIndicator())
            : _errorApps != null
              ? ErrorView(message: _errorApps!, onRetry: _loadApplications)
              : _applications.isEmpty
                ? EmptyState(
                    icon: Icons.work_outline,
                    title: 'No applications yet',
                    subtitle: 'Apply to jobs to see them here',
                    actionLabel: 'Browse Jobs',
                    onAction: () => Navigator.pushNamed(context, '/browse'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadApplications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _applications.length,
                      itemBuilder: (_, i) => _ApplicationCard(app: _applications[i]),
                    ),
                  ),

          // Bookmarks Tab
          _loadingBookmarks
            ? const Center(child: CircularProgressIndicator())
            : _bookmarks.isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'No saved jobs',
                  subtitle: 'Bookmark jobs to revisit them later',
                )
              : RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookmarks.length,
                    itemBuilder: (_, i) => JobCard(
                      job: _bookmarks[i],
                      isBookmarked: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>
                          JobDetailScreen(jobId: _bookmarks[i]['id'])),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;
  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = app['status'] as String? ?? 'pending';
    final statusColors = {
      'shortlisted': Colors.blue,
      'interviewed': Colors.purple,
      'hired': Colors.green,
      'rejected': Colors.red,
    };
    final statusColor = statusColors[status] ?? Colors.orange;
    final statusLabels = {
      'shortlisted': 'Shortlisted',
      'interviewed': 'Interviewed',
      'hired': '🎉 Hired!',
      'rejected': 'Not Selected',
    };
    final statusLabel = statusLabels[status] ?? 'Pending Review';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['job_title'] ?? 'Job',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app['company'] ?? '',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(app['location'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.work_outline, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(app['job_type'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            if (app['match_score'] != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Match: ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((app['match_score'] as num) / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        color: AppTheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${app['match_score'].toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;

  late final _nameCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _cityCtrl = TextEditingController();
  late final _stateCtrl = TextEditingController();
  late final _bioCtrl = TextEditingController();
  late final _skillsCtrl = TextEditingController();
  late final _expCtrl = TextEditingController();
  late final _currentCompanyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
      _cityCtrl.text = user.city ?? '';
      _stateCtrl.text = user.state ?? '';
      _bioCtrl.text = user.bio ?? '';
      _skillsCtrl.text = user.skills ?? '';
      _expCtrl.text = user.experienceYears?.toString() ?? '';
      _currentCompanyCtrl.text = user.currentCompany ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateUser({
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'city': _cityCtrl.text,
        'state': _stateCtrl.text,
        'bio': _bioCtrl.text,
        'skills': _skillsCtrl.text,
        'experience_years': int.tryParse(_expCtrl.text),
        'current_company': _currentCompanyCtrl.text,
      });
      setState(() { _editing = false; _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar section
            Container(
              color: theme.cardColor,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Personal Information'),
                    AppTextField(label: 'Full Name', controller: _nameCtrl, enabled: _editing,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Phone', controller: _phoneCtrl, enabled: _editing,
                      keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'City', controller: _cityCtrl, enabled: _editing)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'State', controller: _stateCtrl, enabled: _editing)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Bio', controller: _bioCtrl, enabled: _editing, maxLines: 3),
                    const SizedBox(height: 20),

                    if (user.isJobseeker) ...[
                      const SectionHeader(title: 'Professional Details'),
                      AppTextField(label: 'Experience (years)', controller: _expCtrl, enabled: _editing,
                        keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      AppTextField(label: 'Current Company', controller: _currentCompanyCtrl, enabled: _editing),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Skills',
                        controller: _skillsCtrl,
                        enabled: _editing,
                        hint: 'Comma-separated: Python, SQL, ML',
                        maxLines: 2,
                      ),
                      if (!_editing && user.skillsList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: user.skillsList.map((s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppTheme.primary.withOpacity(0.08),
                            side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                            labelStyle: const TextStyle(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          )).toList(),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
