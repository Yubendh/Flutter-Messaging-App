import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ProfileData {
  final String name;
  final String studentId;
  final String university;
  final String location;
  final String major;
  final String bio;
  final List<String> courses;
  final bool isLookingForGroup;
  final String? avatarUrl;

  const ProfileData({
    required this.name,
    required this.studentId,
    required this.university,
    required this.location,
    required this.major,
    required this.bio,
    required this.courses,
    required this.isLookingForGroup,
    this.avatarUrl,
  });

  ProfileData copyWith({
    String? name,
    String? studentId,
    String? university,
    String? location,
    String? major,
    String? bio,
    List<String>? courses,
    bool? isLookingForGroup,
    String? avatarUrl,
  }) {
    return ProfileData(
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      university: university ?? this.university,
      location: location ?? this.location,
      major: major ?? this.major,
      bio: bio ?? this.bio,
      courses: courses ?? this.courses,
      isLookingForGroup: isLookingForGroup ?? this.isLookingForGroup,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final ProfileData initial;

  const EditProfileScreen({super.key, required this.initial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _majorCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _courseInputCtrl;

  late List<String> _courses;
  late bool _isLookingForGroup;

  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl = TextEditingController(text: d.name);
    _idCtrl = TextEditingController(text: d.studentId);
    _universityCtrl = TextEditingController(text: d.university);
    _locationCtrl = TextEditingController(text: d.location);
    _majorCtrl = TextEditingController(text: d.major);
    _bioCtrl = TextEditingController(text: d.bio);
    _courseInputCtrl = TextEditingController();
    _courses = List.from(d.courses);
    _isLookingForGroup = d.isLookingForGroup;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _universityCtrl.dispose();
    _locationCtrl.dispose();
    _majorCtrl.dispose();
    _bioCtrl.dispose();
    _courseInputCtrl.dispose();
    super.dispose();
  }

  void _addCourse() {
    final val = _courseInputCtrl.text.trim().toUpperCase();
    if (val.isEmpty || _courses.contains(val)) return;
    setState(() => _courses.add(val));
    _courseInputCtrl.clear();
  }

  void _removeCourse(String course) {
    setState(() => _courses.remove(course));
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {

      String? newAvatarUrl = widget.initial.avatarUrl;
      if (_pickedImage != null) {
        newAvatarUrl = await StorageService().uploadProfilePicture(_pickedImage!);
      }

      final updated = widget.initial.copyWith(
        name: _nameCtrl.text.trim(),
        studentId: _idCtrl.text.trim(),
        university: _universityCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        major: _majorCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        courses: List.from(_courses),
        isLookingForGroup: _isLookingForGroup,
        avatarUrl: newAvatarUrl,
      );

      await FirestoreService().updateUserProfile({
        'displayName': updated.name,
        'studentId': updated.studentId,
        'university': updated.university,
        'location': updated.location,
        'major': updated.major,
        'bio': updated.bio,
        'subjects': updated.courses,
        'isLookingForGroup': updated.isLookingForGroup,
        if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl,
      });

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildAvatarSection(),
              const SizedBox(height: 32),

              _buildSectionLabel('BASIC INFO'),
              _buildCard([
                _buildField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                _buildDivider(),
                _buildField(
                  controller: _idCtrl,
                  label: 'Student ID',
                  icon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Student ID is required' : null,
                ),
                _buildDivider(),
                _buildField(
                  controller: _universityCtrl,
                  label: 'University',
                  icon: Icons.school_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'University is required' : null,
                ),
                _buildDivider(),
                _buildField(
                  controller: _majorCtrl,
                  label: 'Major',
                  icon: Icons.menu_book_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Major is required' : null,
                ),
                _buildDivider(),
                _buildField(
                  controller: _locationCtrl,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionLabel('BIO'),
              _buildCard([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Tell others about yourself...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                      counterStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionLabel('COURSES & SUBJECTS'),
              _buildCard([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_courses.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _courses.map((c) => _buildCourseChip(c)).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _courseInputCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Add course (e.g. CS110)',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onFieldSubmitted: (_) => _addCourse(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _addCourse,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionLabel('AVAILABILITY'),
              _buildCard([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isLookingForGroup,
                    onChanged: (val) => setState(() => _isLookingForGroup = val),
                    activeThumbColor: AppTheme.primary,
                    activeTrackColor: AppTheme.accent,
                    title: Text(
                      'Looking for a Group',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Let others know you\'re available to join a study group',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (widget.initial.avatarUrl != null) {
      imageProvider = NetworkImage(widget.initial.avatarUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? Icon(Icons.person, size: 56, color: AppTheme.primary)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Text(
              'Change Profile Photo',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          border: InputBorder.none,
          filled: false,
          errorStyle: TextStyle(fontSize: 11),
        ),
        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 52, color: AppTheme.divider);
  }

  Widget _buildCourseChip(String course) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            course,
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeCourse(course),
            child: Icon(Icons.close, size: 14, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
