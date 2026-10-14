import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/validators/auth_validators.dart';
import '../../blogs/pages/blog_pages.dart';
import '../../technician_application/pages/technician_application_page.dart';
import '../../technician_portal/pages/technician_portal_page.dart';

String _displayDate(String? value, String fallback) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return fallback;
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('account'),
            style: TextStyle(
              color: context.appText,
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
                color: context.appSoftSurface,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appText,
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
                            color: CoolCareColors.mutedText,
                            fontSize: 9,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          context.tr('viewProfile'),
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
          _AccountSectionTitle(context.tr('yourServices')),

          // My Addresses
          _AccountRow(
            icon: Icons.location_on_outlined,
            label: context.tr('myAddresses'),
            onTap: onViewAddresses,
          ),

          _AccountRow(
            icon: Icons.local_offer_outlined,
            label: context.tr('availableOffers'),
          ),

          _AccountRow(
            icon: Icons.receipt_long_outlined,
            label: context.tr('paymentHistory'),
          ),

          _AccountRow(
            icon: Icons.article_outlined,
            label: context.tr('articles'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BlogListPage())),
          ),

          const SizedBox(height: 18),
          _AccountSectionTitle(context.tr('security')),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: context.tr('changePassword'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(controller: controller),
              ),
            ),
          ),

          const SizedBox(height: 20),
          // TECHNICIAN
          _AccountSectionTitle(context.tr('forTechnicians')),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appAccentSurface,
              border: Border.all(color: context.appBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isTechnicianVerified
                      ? context.tr('technicianPortal')
                      : context.tr('becomeTechnician'),
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  user.isTechnicianVerified
                      ? context.tr('technicianPortalHint')
                      : context.tr('becomeTechnicianHint'),
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => user.isTechnicianVerified
                            ? TechnicianPortalPage(user: user)
                            : const TechnicianApplicationPage(),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      user.isTechnicianVerified
                          ? context.tr('openTechnicianPortal')
                          : context.tr('registerTechnician'),
                      style: const TextStyle(
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
              label: Text(context.tr('logout')),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.error_outline_rounded,
          color: CoolCareColors.error,
        ),
        title: Text(context.tr('logoutConfirmTitle')),
        content: Text(context.tr('logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('stay')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: CoolCareColors.error,
            ),
            child: Text(context.tr('logout')),
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
      backgroundColor: context.appBackground,

      appBar: AppBar(
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        title: Text(
          context.tr('personalProfile'),
          style: TextStyle(
            color: context.appText,
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
                style: TextStyle(
                  color: context.appText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                context.tr('customer'),
                style: TextStyle(color: context.appMuted, fontSize: 13),
              ),
              const SizedBox(height: 34),
              _ProfileSectionTitle(context.tr('personalInfo')),
              _ProfileField(
                label: context.tr('fullName'),
                value: user.fullName,
              ),
              _ProfileField(
                label: context.tr('dateOfBirth'),
                value: _displayDate(user.dateOfBirth, context.tr('notUpdated')),
              ),
              _ProfileField(
                label: context.tr('gender'),
                value: switch (user.gender) {
                  'MALE' => context.tr('male'),
                  'FEMALE' => context.tr('female'),
                  'OTHER' => context.tr('other'),
                  _ => context.tr('notUpdated'),
                },
              ),
              const SizedBox(height: 26),
              _ProfileSectionTitle(context.tr('contactInfo')),
              _ProfileField(label: 'Email', value: user.email),
              _ProfileField(
                label: context.tr('phoneNumber'),
                value: user.phone?.trim().isNotEmpty == true
                    ? user.phone!
                    : context.tr('notUpdated'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.tr('editProfile')),
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
                  label: Text(context.tr('changePassword')),
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
      return context.tr('passwordMinLength');
    }
    if (password.length > 72) {
      return context.tr('passwordMaxLength');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return context.tr('passwordComposition');
    }
    if (password == _current.text) {
      return context.tr('passwordMustDiffer');
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
            widget.controller.errorMessage ??
            context.tr('unableUpdatePassword'),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('passwordUpdatedSuccessfully'))),
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
      borderSide: BorderSide(color: context.appBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: context.appBorder),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      backgroundColor: context.appSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        context.tr('changePassword'),
        style: TextStyle(
          color: context.appText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: context.appBorder),
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
                    Text(
                      context.tr('createNewPasswordHeading'),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('strongPasswordHint'),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PasswordLabel(context.tr('currentPassword')),
                    TextFormField(
                      controller: _current,
                      obscureText: !_showCurrent,
                      decoration: _passwordDecoration(
                        context.tr('enterPassword'),
                        _showCurrent,
                        () => setState(() => _showCurrent = !_showCurrent),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? context.tr('requiredCurrentPassword')
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _PasswordLabel(context.tr('newPassword')),
                    TextFormField(
                      controller: _next,
                      obscureText: !_showNext,
                      decoration: _passwordDecoration(
                        context.tr('newPassword'),
                        _showNext,
                        () => setState(() => _showNext = !_showNext),
                      ),
                      validator: _newPasswordError,
                    ),
                    const SizedBox(height: 18),
                    _PasswordLabel(context.tr('confirmNewPassword')),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showConfirm,
                      decoration: _passwordDecoration(
                        context.tr('reenterPassword'),
                        _showConfirm,
                        () => setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('requiredConfirmPassword');
                        }
                        return value != _next.text
                            ? context.tr('passwordMismatch')
                            : null;
                      },
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appSoftSurface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: CoolCareColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('passwordRequirements'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.tr('passwordRequirementDetails'),
                            style: TextStyle(
                              color: context.appMuted,
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
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appBorder)),
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
                        _saving
                            ? context.tr('updating')
                            : context.tr('updatePassword'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
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
      style: TextStyle(
        color: context.appText,
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
      backgroundColor: context.appSurface,
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
              label: context.tr('takePhoto'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.camera);
              },
            ),
            _AvatarOption(
              label: context.tr('chooseFromLibrary'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            _AvatarOption(
              label: context.tr('removeCurrentPhoto'),
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
              label: context.tr('cancel'),
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
    fillColor: readOnly
        ? CoolCareColors.primary.withValues(
            alpha: context.isDarkMode ? .14 : .08,
          )
        : context.appSoftSurface,
    labelStyle: TextStyle(color: context.appMuted, fontSize: 12),
    hintStyle: TextStyle(color: context.appMuted, fontSize: 14),
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
    backgroundColor: context.appBackground,
    appBar: AppBar(
      backgroundColor: context.appSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        context.tr('editProfile'),
        style: TextStyle(
          color: context.appText,
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
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: context.appSurface,
                            child: const CircleAvatar(
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
                    Text(
                      context.tr('changePhoto'),
                      style: const TextStyle(
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
            _ProfileSectionTitle(context.tr('personalInfo')),
            TextField(
              controller: _name,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: _input(
                context.tr('fullName'),
                Icons.person_outline,
              ).copyWith(counterText: ''),
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
                  context.tr('dateOfBirth'),
                  Icons.calendar_today_outlined,
                  showIcon: true,
                ),
                child: Text(
                  _birthDate == null
                      ? context.tr('selectBirthDate')
                      : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  style: TextStyle(
                    color: _birthDate == null
                        ? context.appMuted
                        : context.appText,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              hint: Text(
                context.tr('selectGender'),
                style: TextStyle(color: context.appMuted, fontSize: 14),
              ),
              decoration: _input(
                context.tr('gender'),
                Icons.keyboard_arrow_down_rounded,
              ),
              items: [
                DropdownMenuItem(
                  value: 'MALE',
                  child: Text(context.tr('male')),
                ),
                DropdownMenuItem(
                  value: 'FEMALE',
                  child: Text(context.tr('female')),
                ),
                DropdownMenuItem(
                  value: 'OTHER',
                  child: Text(context.tr('other')),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 24),
            _ProfileSectionTitle(context.tr('contactInfo')),
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
                context.tr('phoneNumber'),
                Icons.phone_outlined,
                showIcon: true,
                hintText: context.tr('enterPhone'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 9),
              child: Text(
                context.tr('existingBookingContactNote'),
                style: TextStyle(
                  color: context.appMuted,
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
                  context.tr(_saving ? 'saving' : 'saveChanges'),
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
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) {
      return 'CC';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
class _AccountSectionTitle extends StatelessWidget {
  const _AccountSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: context.appMuted,
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          children: [
            Icon(icon, color: CoolCareColors.primaryDark, size: 18),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: context.appText, fontSize: 11),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// PROFILE SECTION TITLE
class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          text,
          style: TextStyle(
            color: context.appMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// PROFILE FIELD
class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.appMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.appText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
