import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'job_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialDept;

  const BrowseScreen({super.key, this.initialSearch, this.initialDept});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  String _selectedDept = 'All';
  String? _selectedJobType;
  String _sortBy = 'newest';

  final _depts = ['All', 'NABCB', 'NABH', 'NABET', 'NABL', 'NBQP', 'IT', 'Finance', 'HR', 'Media'];
  final _jobTypes = ['Full-time', 'Part-time', 'Contract', 'Internship', 'Remote'];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) _searchController.text = widget.initialSearch!;
    if (widget.initialDept != null) _selectedDept = widget.initialDept!;
    _loadJobs();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_loadingMore && _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _loadJobs() async {
    setState(() { _loading = true; _error = null; _page = 1; _jobs = []; });
    try {
      final data = await ApiService.getJobs(
        search: _searchController.text,
        department: _selectedDept == 'All' ? null : _selectedDept,
        jobType: _selectedJobType,
        page: 1,
        limit: 20,
      );
      // Backend returns { jobs, total, page, pages }
      final list = (data['jobs'] as List?) ?? const [];
      setState(() {
        _jobs = List<Map<String, dynamic>>.from(list);
        _hasMore = list.length == 20;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.getJobs(
        search: _searchController.text,
        department: _selectedDept == 'All' ? null : _selectedDept,
        jobType: _selectedJobType,
        page: _page + 1,
        limit: 20,
      );
      final list = (data['jobs'] as List?) ?? const [];
      setState(() {
        _jobs.addAll(List<Map<String, dynamic>>.from(list));
        _page++;
        _hasMore = list.length == 20;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        selectedDept: _selectedDept,
        selectedJobType: _selectedJobType,
        depts: _depts,
        jobTypes: _jobTypes,
        onApply: (dept, jobType) {
          setState(() {
            _selectedDept = dept;
            _selectedJobType = jobType;
          });
          _loadJobs();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadJobs(),
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadJobs();
                      },
                    )
                  : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Department chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _depts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final dept = _depts[i];
                final selected = _selectedDept == dept;
                final color = dept == 'All' ? AppTheme.primary : AppTheme.getDeptColor(dept);
                return FilterChip(
                  label: Text(dept),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedDept = dept);
                    _loadJobs();
                  },
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    color: selected ? color : Colors.grey[700],
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: selected ? BorderSide(color: color.withOpacity(0.5)) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          // Active filter badges
          if (_selectedJobType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ActionChip(
                    label: Text(_selectedJobType!),
                    avatar: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      setState(() => _selectedJobType = null);
                      _loadJobs();
                    },
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12, color: AppTheme.primary),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

          // Results count
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_jobs.length} jobs found',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Job list
          Expanded(
            child: _loading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ShimmerCard(),
                )
              : _error != null
                ? ErrorView(message: _error!, onRetry: _loadJobs)
                : _jobs.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'No jobs found',
                      subtitle: 'Try adjusting your search or filters',
                      actionLabel: 'Clear filters',
                      onAction: () {
                        _searchController.clear();
                        setState(() {
                          _selectedDept = 'All';
                          _selectedJobType = null;
                        });
                        _loadJobs();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _jobs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return JobCard(
                            job: _jobs[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) =>
                                JobDetailScreen(jobId: _jobs[i]['id'])),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String selectedDept;
  final String? selectedJobType;
  final List<String> depts;
  final List<String> jobTypes;
  final void Function(String dept, String? jobType) onApply;

  const _FilterSheet({
    required this.selectedDept,
    required this.selectedJobType,
    required this.depts,
    required this.jobTypes,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _dept;
  String? _jobType;

  @override
  void initState() {
    super.initState();
    _dept = widget.selectedDept;
    _jobType = widget.selectedJobType;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() { _dept = 'All'; _jobType = null; });
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const Divider(),
            const Text('Job Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.jobTypes.map((type) {
                final selected = _jobType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) => setState(() => _jobType = selected ? null : type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_dept, _jobType);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
