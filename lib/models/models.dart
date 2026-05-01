import 'package:flutter/material.dart';

// ─── User ──────────────────────────────────────────────────────────────
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'jobseeker' | 'employer' | 'hr' | 'super_admin'
  final String? companyName;
  final String? city;
  final String? state;
  final String? pincode;
  final String? bio;
  final String? skills;
  final int? experienceYears;
  final String? currentCompany;
  final String? profileResumePath;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.companyName,
    this.city,
    this.state,
    this.pincode,
    this.bio,
    this.skills,
    this.experienceYears,
    this.currentCompany,
    this.profileResumePath,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    role: json['role'] ?? 'jobseeker',
    companyName: json['company_name'],
    city: json['city'],
    state: json['state'],
    pincode: json['pincode'],
    bio: json['bio'],
    skills: json['skills'],
    experienceYears: json['experience_years'],
    currentCompany: json['current_company'],
    profileResumePath: json['profile_resume_path'],
    createdAt: json['created_at']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'company_name': companyName,
    'city': city,
    'state': state,
    'pincode': pincode,
    'bio': bio,
    'skills': skills,
    'experience_years': experienceYears,
    'current_company': currentCompany,
    'profile_resume_path': profileResumePath,
    'created_at': createdAt,
  };

  bool get isEmployer => role == 'employer' || role == 'hr';
  bool get isJobseeker => role == 'jobseeker';
  bool get isAdmin => role == 'hr' || role == 'super_admin';

  List<String> get skillsList =>
    skills?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
}

// ─── Job ───────────────────────────────────────────────────────────────
class Job {
  final int id;
  final int employerId;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String category;
  final int experienceMin;
  final int experienceMax;
  final int? salaryMin;
  final int? salaryMax;
  final String description;
  final String requirements;
  final String skills;
  final int openings;
  final int isActive;
  final String? department;
  final String createdAt;
  final String? employerName;
  final int? applicationCount;
  final double? matchScore;
  final List<String>? matchedSkills;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.category,
    required this.experienceMin,
    required this.experienceMax,
    this.salaryMin,
    this.salaryMax,
    required this.description,
    required this.requirements,
    required this.skills,
    required this.openings,
    required this.isActive,
    this.department,
    required this.createdAt,
    this.employerName,
    this.applicationCount,
    this.matchScore,
    this.matchedSkills,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'],
    employerId: json['employer_id'] ?? 0,
    title: json['title'] ?? '',
    company: json['company'] ?? '',
    location: json['location'] ?? '',
    jobType: json['job_type'] ?? '',
    category: json['category'] ?? '',
    experienceMin: json['experience_min'] ?? 0,
    experienceMax: json['experience_max'] ?? 0,
    salaryMin: json['salary_min'],
    salaryMax: json['salary_max'],
    description: json['description'] ?? '',
    requirements: json['requirements'] ?? '',
    skills: json['skills'] ?? '',
    openings: json['openings'] ?? 1,
    isActive: json['is_active'] ?? 1,
    department: json['department'],
    createdAt: json['created_at']?.toString() ?? '',
    employerName: json['employer_name'],
    applicationCount: (json['application_count'] is String)
      ? int.tryParse(json['application_count'])
      : json['application_count'],
    matchScore: (json['match_score'] as num?)?.toDouble(),
    matchedSkills: json['matched_skills'] != null
      ? List<String>.from(json['matched_skills'])
      : null,
  );

  List<String> get skillsList =>
    skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  String get formattedSalary {
    if (salaryMin == null && salaryMax == null) return 'Salary not disclosed';
    String fmt(int n) => n >= 100000
      ? '₹${(n / 100000).toStringAsFixed(1)}L'
      : '₹${n.toString()}';
    if (salaryMin != null && salaryMax != null) return '${fmt(salaryMin!)} – ${fmt(salaryMax!)} p.a.';
    if (salaryMin != null) return 'From ${fmt(salaryMin!)} p.a.';
    return 'Up to ${fmt(salaryMax!)} p.a.';
  }

  String get experienceRange => '$experienceMin–$experienceMax yrs';
}

// ─── Application ───────────────────────────────────────────────────────
class Application {
  final int id;
  final int jobId;
  final int applicantId;
  final String fullName;
  final String email;
  final String phone;
  final String pincode;
  final String? city;
  final String? state;
  final int experienceYears;
  final String? currentCompany;
  final String? currentCtc;
  final String? expectedCtc;
  final String? noticePeriod;
  final String? coverLetter;
  final String? resumePath;
  final String? skills;
  final String status;
  final double matchScore;
  final String appliedAt;
  final String? jobTitle;
  final String? company;
  final String? location;
  final String? jobType;

  Application({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.pincode,
    this.city,
    this.state,
    required this.experienceYears,
    this.currentCompany,
    this.currentCtc,
    this.expectedCtc,
    this.noticePeriod,
    this.coverLetter,
    this.resumePath,
    this.skills,
    required this.status,
    required this.matchScore,
    required this.appliedAt,
    this.jobTitle,
    this.company,
    this.location,
    this.jobType,
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    id: json['id'],
    jobId: json['job_id'],
    applicantId: json['applicant_id'],
    fullName: json['full_name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    pincode: json['pincode'] ?? '',
    city: json['city'],
    state: json['state'],
    experienceYears: json['experience_years'] ?? 0,
    currentCompany: json['current_company'],
    currentCtc: json['current_ctc'],
    expectedCtc: json['expected_ctc'],
    noticePeriod: json['notice_period'],
    coverLetter: json['cover_letter'],
    resumePath: json['resume_path'],
    skills: json['skills'],
    status: json['status'] ?? 'pending',
    matchScore: ((json['match_score'] ?? 0) as num).toDouble(),
    appliedAt: json['applied_at']?.toString() ?? '',
    jobTitle: json['job_title'],
    company: json['company'],
    location: json['location'],
    jobType: json['job_type'],
  );

  Color get statusColor {
    switch (status) {
      case 'shortlisted': return const Color(0xFF2563EB);
      case 'interviewed': return const Color(0xFF7C3AED);
      case 'hired': return const Color(0xFF059669);
      case 'rejected': return const Color(0xFFDC2626);
      default: return const Color(0xFFD97706);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'shortlisted': return 'Shortlisted';
      case 'interviewed': return 'Interviewed';
      case 'hired': return '🎉 Hired';
      case 'rejected': return 'Not Selected';
      default: return 'Pending';
    }
  }
}
