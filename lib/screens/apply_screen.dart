import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class ApplyScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  const ApplyScreen({super.key, required this.job});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _resumeFile;
  String? _resumeName;
  bool _submitting = false;
  bool _submitted = false;

  late final _nameCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _pincodeCtrl = TextEditingController();
  late final _cityCtrl = TextEditingController();
  late final _stateCtrl = TextEditingController();
  late final _expCtrl = TextEditingController();
  late final _currentCompanyCtrl = TextEditingController();
  late final _currentCtcCtrl = TextEditingController();
  late final _expectedCtcCtrl = TextEditingController();
  late final _noticePeriodCtrl = TextEditingController();
  late final _coverLetterCtrl = TextEditingController();
  late final _skillsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
      _cityCtrl.text = user.city ?? '';
      _stateCtrl.text = user.state ?? '';
      _expCtrl.text = user.experienceYears?.toString() ?? '';
      _currentCompanyCtrl.text = user.currentCompany ?? '';
      _skillsCtrl.text = user.skills ?? '';
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload your resume'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.applyToJob(
        widget.job['id'],
        {
          'full_name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'phone': _phoneCtrl.text,
          'pincode': _pincodeCtrl.text,
          'city': _cityCtrl.text,
          'state': _stateCtrl.text,
          'experience_years': _expCtrl.text,
          'current_company': _currentCompanyCtrl.text,
          'current_ctc': _currentCtcCtrl.text,
          'expected_ctc': _expectedCtcCtrl.text,
          'notice_period': _noticePeriodCtrl.text,
          'cover_letter': _coverLetterCtrl.text,
          'skills': _skillsCtrl.text,
        },
        _resumeFile,
      );
      setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(job: widget.job);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Job')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Job header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.job['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(widget.job['company'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Info
            const _FormSection(title: 'Personal Information'),
            AppTextField(label: 'Full Name *', controller: _nameCtrl,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Email *', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone *', controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'City', controller: _cityCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(label: 'State', controller: _stateCtrl),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Pincode *', controller: _pincodeCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 20),

            // Professional Info
            const _FormSection(title: 'Professional Details'),
            AppTextField(
              label: 'Experience (years) *',
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Current Company', controller: _currentCompanyCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Current CTC', controller: _currentCtcCtrl)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Expected CTC', controller: _expectedCtcCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Notice Period', controller: _noticePeriodCtrl,
              hint: 'e.g. 30 days, Immediate'),
            const SizedBox(height: 12),
            AppTextField(label: 'Skills', controller: _skillsCtrl,
              hint: 'Comma-separated: Python, SQL, ML'),
            const SizedBox(height: 20),

            // Resume Upload
            const _FormSection(title: 'Resume'),
            GestureDetector(
              onTap: _pickResume,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _resumeFile != null
                    ? AppTheme.success.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _resumeFile != null ? AppTheme.success : Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resumeFile != null ? Icons.check_circle : Icons.upload_file,
                      color: _resumeFile != null ? AppTheme.success : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resumeFile != null ? _resumeName! : 'Upload Resume *',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _resumeFile != null ? AppTheme.success : Colors.grey[700],
                            ),
                          ),
                          Text(
                            'PDF, DOC or DOCX (max 5MB)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: _pickResume, child: const Text('Browse')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cover Letter
            const _FormSection(title: 'Cover Letter (Optional)'),
            AppTextField(
              label: 'Why are you a good fit for this role?',
              controller: _coverLetterCtrl,
              maxLines: 5,
              hint: 'Briefly describe your interest and relevant experience...',
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit Application', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  const _FormSection({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.grey[200])),
      ],
    ),
  );
}

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic> job;
  const _SuccessView({required this.job});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.success, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Application Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'Your application for "${job['title']}" at ${job['company']} has been received.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                  ..pop()..pop()..pop(),
                child: const Text('Browse More Jobs'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context)
                  ..pop()..pop(),
                child: const Text('View My Applications'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
