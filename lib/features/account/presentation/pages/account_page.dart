import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/coolcare_theme.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/domain/auth_validators.dart';
import '../../../auth/presentation/auth_controller.dart';

String _displayDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return 'Not updated';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String? _apiDate(DateTime? value) {
  if (value == null) return null;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class AccountPage extends StatelessWidget {
  const AccountPage({
    required this.user,
    required this.controller,
    required this.onViewProfile,
    required this.onViewAddresses,
    required this.onLogout,
    super.key,
  });

  final AuthUser user;
  final AuthController controller;
  final VoidCallback onViewProfile;

  // NEW: mở màn hình My Addresses
  final VoidCallback onViewAddresses;

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('account-page'),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              color: CoolCareColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.45,
            ),
          ),

          const SizedBox(height: 14),

          // PROFILE
          InkWell(
            onTap: onViewProfile,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  _InitialAvatar(
                    name: user.fullName,
                    size: 48,
                    imageUrl: user.avatarUrl,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoolCareColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            CoolCareColors.mutedText,
                            fontSize: 9,
                          ),
                        ),

                        const SizedBox(height: 2),

                        const Text(
                          'View profile  →',
                          style: TextStyle(
                            color: CoolCareColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // YOUR SERVICES
          const _AccountSectionTitle(
            'YOUR SERVICES',
          ),

          // My Addresses
          _AccountRow(
            icon: Icons.location_on_outlined,
            label: 'My Addresses',
            onTap: onViewAddresses,
          ),

          const _AccountRow(
            icon: Icons.local_offer_outlined,
            label: 'Available Offers',
          ),

          const _AccountRow(
            icon: Icons.receipt_long_outlined,
            label: 'Payment History',
          ),

          const _AccountRow(
            icon: Icons.forum_outlined,
            label: 'My Complaints',
          ),

          const SizedBox(height: 18),
          const _AccountSectionTitle('SECURITY'),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(controller: controller),
              ),
            ),
          ),

          const SizedBox(height: 20),
          // TECHNICIAN
          const _AccountSectionTitle(
            'FOR TECHNICIANS',
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              border: Border.all(
                color: const Color(0xFFC9EDEE),
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Become a CoolCare Technician',
                  style: TextStyle(
                    color: CoolCareColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Register as a technician to provide services on the platform.',
                  style: TextStyle(
                    color: CoolCareColors.mutedText,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize:
                      const Size.fromHeight(39),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'Register as Technician',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CoolCareColors.error,
                side: BorderSide(
                  color: CoolCareColors.error.withValues(alpha: .28),
                ),
                backgroundColor: CoolCareColors.error.withValues(alpha: .04),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context,
      ) async {
    final shouldLogout =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.error_outline_rounded,
          color: CoolCareColors.error,
        ),
        title: const Text(
          'Log out of CoolCare?',
        ),
        content: const Text(
          'You can log in again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(
                  dialogContext,
                ).pop(false),
            child: const Text(
              'Stay',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(
                  dialogContext,
                ).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
              CoolCareColors.error,
            ),
            child: const Text(
              'Log Out',
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await onLogout();
    }
  }
}

class PersonalProfilePage extends StatelessWidget {
  const PersonalProfilePage({
    required this.user,
    required this.controller,
    super.key,
  });

  final AuthUser user;
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () =>
              Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Personal Profile',
          style: TextStyle(
            color: CoolCareColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: [
              _InitialAvatar(
                name: user.fullName,
                size: 76,
                imageUrl: user.avatarUrl,
              ),
              const SizedBox(height: 14),
              Text(
                user.fullName,
                style: const TextStyle(
                  color: CoolCareColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'Customer',
                style: TextStyle(color: CoolCareColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 34),
              const _ProfileSectionTitle('Personal Info'),
              _ProfileField(label: 'Full Name', value: user.fullName),
              _ProfileField(
                label: 'Date of Birth',
                value: _displayDate(user.dateOfBirth),
              ),
              _ProfileField(
                label: 'Gender',
                value: switch (user.gender) {
                  'MALE' => 'Male',
                  'FEMALE' => 'Female',
                  'OTHER' => 'Other',
                  _ => 'Not updated',
                },
              ),
              const SizedBox(height: 26),
              const _ProfileSectionTitle('Contact Info'),
              _ProfileField(label: 'Email', value: user.email),
              _ProfileField(
                label: 'Phone Number',
                value:
                user.phone?.trim().isNotEmpty ==
                    true
                    ? user.phone!
                    : 'Not updated',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _changePassword(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: user, controller: controller),
      ),
    );
    final currentUser = controller.user;
    if (updated == true && context.mounted && currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              PersonalProfilePage(user: currentUser, controller: controller),
        ),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(controller: controller),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _newPasswordError(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Password must contain at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Include upper/lowercase letters, a number and a special character.';
    }
    if (password == _current.text) {
      return 'New password must differ from your current password.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    final success = await widget.controller.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!success) {
      setState(
        () => _error =
            widget.controller.errorMessage ?? 'Unable to update password.',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully.')),
    );
    Navigator.of(context).pop();
  }

  InputDecoration _passwordDecoration(
    String hint,
    bool visible,
    VoidCallback toggle,
  ) => InputDecoration(
    hintText: hint,
    suffixIcon: IconButton(
      onPressed: toggle,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE5E7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE5E7)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Change Password',
        style: TextStyle(
          color: CoolCareColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: CoolCareColors.border),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a new password',
                      style: TextStyle(
                        color: CoolCareColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Use a strong password you haven't used before to keep your CoolCare account secure.",
                      style: TextStyle(
                        color: CoolCareColors.mutedText,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _PasswordLabel('Current password'),
                    TextFormField(
                      controller: _current,
                      obscureText: !_showCurrent,
                      decoration: _passwordDecoration(
                        'Enter current password',
                        _showCurrent,
                        () => setState(() => _showCurrent = !_showCurrent),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your current password.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    const _PasswordLabel('New password'),
                    TextFormField(
                      controller: _next,
                      obscureText: !_showNext,
                      decoration: _passwordDecoration(
                        'Enter new password',
                        _showNext,
                        () => setState(() => _showNext = !_showNext),
                      ),
                      validator: _newPasswordError,
                    ),
                    const SizedBox(height: 18),
                    const _PasswordLabel('Confirm new password'),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showConfirm,
                      decoration: _passwordDecoration(
                        'Re-enter new password',
                        _showConfirm,
                        () => setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (value) => value != _next.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: CoolCareColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Password requirements',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '• At least 8 characters\n• Include an uppercase letter and a number\n• Different from your current password',
                            style: TextStyle(
                              color: CoolCareColors.mutedText,
                              fontSize: 12,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: CoolCareColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CoolCareColors.border)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _saving ? 'Updating...' : 'Update Password',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PasswordLabel extends StatelessWidget {
  const _PasswordLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: CoolCareColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    required this.user,
    required this.controller,
    super.key,
  });

  final AuthUser user;
  final AuthController controller;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.user.fullName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phone ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email,
  );
  DateTime? _birthDate;
  String? _gender;
  String? _error;
  String? _avatarPath;
  bool _avatarChanged = false;
  bool _saving = false;

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image != null && mounted) {
        setState(() {
          _avatarPath = image.path;
          _avatarChanged = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Unable to open the camera. Please check camera permission.'
                : 'Unable to open the photo library. Please check photo permission.',
          ),
        ),
      );
    }
  }

  Future<void> _showAvatarOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E1E3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            _AvatarOption(
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.camera);
              },
            ),
            _AvatarOption(
              label: 'Choose from Library',
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            _AvatarOption(
              label: 'Remove Current Photo',
              destructive: true,
              onTap: () {
                setState(() {
                  _avatarPath = null;
                  _avatarChanged = true;
                });
                Navigator.pop(sheetContext);
              },
            ),
            const Divider(height: 1, color: CoolCareColors.border),
            _AvatarOption(
              label: 'Cancel',
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _birthDate = DateTime.tryParse(widget.user.dateOfBirth ?? '');
    _gender = widget.user.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.replaceAll(RegExp(r'[\s.-]'), '');
    if (name.length < 2 ||
        name.length > 100 ||
        !RegExp(r"^[\p{L}\s'-]+$", unicode: true).hasMatch(name)) {
      setState(
        () => _error = 'Enter a valid full name between 2 and 100 characters.',
      );
      return;
    }
    if (phone.isNotEmpty && AuthValidators.phone(phone) != null) {
      setState(
        () => _error =
            'Enter a valid Vietnamese phone number and avoid repeated digits.',
      );
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final success = await widget.controller.updateProfile(
      fullName: name,
      phone: phone.isEmpty ? null : phone,
      dateOfBirth: _apiDate(_birthDate),
      gender: _gender,
      avatarPath: _avatarPath,
      avatarChanged: _avatarChanged,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!success) {
      setState(() => _error = widget.controller.errorMessage);
      return;
    }
    Navigator.of(context).pop(true);
  }

  InputDecoration _input(
    String label,
    IconData icon, {
    bool readOnly = false,
    bool showIcon = false,
    String? hintText,
  }) => InputDecoration(
    labelText: label,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: readOnly ? const Color(0xFFEAF8FA) : Colors.white,
    labelStyle: const TextStyle(color: CoolCareColors.mutedText, fontSize: 12),
    hintStyle: const TextStyle(color: Color(0xFFABB4B8), fontSize: 14),
    suffixIcon: showIcon
        ? Icon(icon, color: CoolCareColors.mutedText, size: 19)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE5E7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE5E7)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: CoolCareColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: InkWell(
                onTap: _showAvatarOptions,
                borderRadius: BorderRadius.circular(48),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _InitialAvatar(
                          name: _name.text,
                          size: 76,
                          imagePath: _avatarPath,
                          imageUrl: !_avatarChanged
                              ? widget.user.avatarUrl
                              : null,
                        ),
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: CoolCareColors.primary,
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Change Photo',
                      style: TextStyle(
                        color: CoolCareColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _ProfileSectionTitle('Personal Info'),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: _input('Full name', Icons.person_outline),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  initialDate: _birthDate ?? DateTime(2000),
                );
                if (date != null) setState(() => _birthDate = date);
              },
              child: InputDecorator(
                decoration: _input(
                  'Date of birth',
                  Icons.calendar_today_outlined,
                  showIcon: true,
                ),
                child: Text(
                  _birthDate == null
                      ? 'Select date of birth'
                      : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  style: TextStyle(
                    color: _birthDate == null
                        ? const Color(0xFFABB4B8)
                        : CoolCareColors.text,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              hint: const Text(
                'Select gender',
                style: TextStyle(color: Color(0xFFABB4B8), fontSize: 14),
              ),
              decoration: _input('Gender', Icons.keyboard_arrow_down_rounded),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 24),
            const _ProfileSectionTitle('Contact Info'),
            TextField(
              enabled: false,
              controller: _email,
              decoration: _input('Email', Icons.email_outlined, readOnly: true),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _input(
                'Phone number',
                Icons.phone_outlined,
                showIcon: true,
                hintText: 'Enter phone number',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 9),
              child: Text(
                'Profile changes do not affect contact info on existing bookings.',
                style: TextStyle(
                  color: CoolCareColors.mutedText,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: CoolCareColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color: destructive ? CoolCareColors.error : CoolCareColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ),
  );
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.name,
    required this.size,
    this.imagePath,
    this.imageUrl,
  });

  final String name;
  final double size;
  final String? imagePath;
  final String? imageUrl;

  String get initials {
    final parts =
    name.trim().split(
      RegExp(r'\s+'),
    );

    if (parts.isEmpty ||
        parts.first.isEmpty) {
      return 'CC';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CoolCareColors.primary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null
          ? Image.file(
              File(imagePath!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackAvatar(),
            )
          : imageUrl?.trim().isNotEmpty == true
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackAvatar(),
            )
          : _fallbackAvatar(),
    );
  }

  Widget _fallbackAvatar() => Text(
    initials,
    style: TextStyle(
      color: Colors.white,
      fontSize: size * .27,
      fontWeight: FontWeight.w800,
    ),
  );
}
// ACCOUNT SECTION TITLE
class _AccountSectionTitle
    extends StatelessWidget {
  const _AccountSectionTitle(
      this.text,
      );

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color:
          CoolCareColors.mutedText,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: .25,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CoolCareColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: CoolCareColors.primaryDark, size: 18),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: CoolCareColors.text,
                  fontSize: 11,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CoolCareColors.mutedText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
// PROFILE SECTION TITLE
class _ProfileSectionTitle
    extends StatelessWidget {
  const _ProfileSectionTitle(
      this.text,
      );

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      Alignment.centerLeft,
      child: Padding(
        padding:
        const EdgeInsets.only(
          bottom: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: CoolCareColors.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
// PROFILE FIELD
class _ProfileField
    extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CoolCareColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CoolCareColors.mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: CoolCareColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}