import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'browse_screen.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _featuredJobs = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _boards = [
    {'name': 'NABH', 'label': 'Healthcare', 'icon': Icons.local_hospital_outlined, 'color': 0xFF0D9488},
    {'name': 'NABL', 'label': 'Laboratories', 'icon': Icons.science_outlined, 'color': 0xFFEA580C},
    {'name': 'NABCB', 'label': 'Certification', 'icon': Icons.verified_outlined, 'color': 0xFF4F46E5},
    {'name': 'NABET', 'label': 'Education', 'icon': Icons.school_outlined, 'color': 0xFF7C3AED},
    {'name': 'IT', 'label': 'Technology', 'icon': Icons.computer_outlined, 'color': 0xFF0284C7},
    {'name': 'Finance', 'label': 'Finance', 'icon': Icons.account_balance_outlined, 'color': 0xFF16A34A},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final jobs = await ApiService.getJobs(limit: 6);
      // Backend returns { jobs: [...], total, page, pages }
      final jobList = (jobs['jobs'] as List?) ?? const [];
      setState(() {
        _featuredJobs = List<Map<String, dynamic>>.from(jobList);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ─── Hero AppBar ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
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
                                      user != null ? 'Hello, ${user.name.split(' ').first}! 👋' : 'Find Your Dream Job',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user != null
                                        ? 'Explore opportunities waiting for you'
                                        : 'Join thousands of professionals',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (user == null)
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/login'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Sign In'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (q) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BrowseScreen(initialSearch: q)),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search jobs, skills, departments...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune, color: AppTheme.primary),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrowseScreen()),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Content ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Quick Stats Bar
                  _StatsBar(),
                  const SizedBox(height: 20),

                  // Department Boards
                  const SectionHeader(title: 'Explore by Board'),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _boards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final board = _boards[i];
                        final color = Color(board['color'] as int);
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>
                              BrowseScreen(initialDept: board['name'] as String)),
                          ),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(board['icon'] as IconData, color: color, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  board['name'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  board['label'] as String,
                                  style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Featured Jobs
                  SectionHeader(
                    title: 'Latest Jobs',
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BrowseScreen()),
                    ),
                  ),

                  if (_loading)
                    ...List.generate(3, (_) => const ShimmerCard())
                  else if (_error != null)
                    ErrorView(message: _error!, onRetry: _loadData)
                  else if (_featuredJobs.isEmpty)
                    const EmptyState(
                      icon: Icons.work_outline,
                      title: 'No jobs yet',
                      subtitle: 'Check back soon for new opportunities',
                    )
                  else
                    ..._featuredJobs.map((job) => JobCard(
                      job: job,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job['id'])),
                      ),
                    )),

                  if (!_loading && _featuredJobs.isNotEmpty)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrowseScreen()),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Browse all jobs'),
                      ),
                    ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          _Stat(label: 'Open Jobs', value: '500+', icon: Icons.work),
          _divider(),
          _Stat(label: 'Departments', value: '14', icon: Icons.category),
          _divider(),
          _Stat(label: 'Companies', value: '5+', icon: Icons.business),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 36, color: const Color(0xFFBFDBFE), margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    ),
  );
}
