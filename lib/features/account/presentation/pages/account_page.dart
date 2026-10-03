import 'package:flutter/material.dart';

import '../../../../app/theme/coolcare_theme.dart';
import '../../../auth/domain/auth_user.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    required this.user,
    required this.onViewProfile,
    required this.onLogout,
    super.key,
  });

  final AuthUser user;
  final VoidCallback onViewProfile;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('account-page'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
                  _InitialAvatar(name: user.fullName, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: CoolCareColors.mutedText,
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
          const _AccountSectionTitle('YOUR SERVICES'),
          const _AccountRow(
            icon: Icons.location_on_outlined,
            label: 'My Addresses',
          ),
          const _AccountRow(
            icon: Icons.local_offer_outlined,
            label: 'Available Offers',
          ),
          const _AccountRow(
            icon: Icons.receipt_long_outlined,
            label: 'Payment History',
          ),
          const _AccountRow(icon: Icons.forum_outlined, label: 'My Complaints'),
          const SizedBox(height: 18),
          const _AccountSectionTitle('SECURITY'),
          const _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
          ),
          const SizedBox(height: 20),
          const _AccountSectionTitle('FOR TECHNICIANS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              border: Border.all(color: const Color(0xFFC9EDEE)),
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
                      minimumSize: const Size.fromHeight(39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
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
          TextButton(
            onPressed: () => _confirmLogout(context),
            style: TextButton.styleFrom(
              foregroundColor: CoolCareColors.error,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
        title: const Text('Log out of CoolCare?'),
        content: const Text('You can log in again anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: CoolCareColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) await onLogout();
  }
}

class PersonalProfilePage extends StatelessWidget {
  const PersonalProfilePage({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              _InitialAvatar(name: user.fullName, size: 76),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                  color: CoolCareColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Customer',
                style: TextStyle(color: CoolCareColors.mutedText, fontSize: 10),
              ),
              const SizedBox(height: 28),
              const _ProfileSectionTitle('Personal Info'),
              _ProfileField(label: 'Full Name', value: user.fullName),
              const _ProfileField(label: 'Date of Birth', value: 'Not updated'),
              const _ProfileField(label: 'Gender', value: 'Not updated'),
              const SizedBox(height: 22),
              const _ProfileSectionTitle('Contact Info'),
              _ProfileField(label: 'Email', value: user.email),
              _ProfileField(
                label: 'Phone Number',
                value: user.phone?.trim().isNotEmpty == true
                    ? user.phone!
                    : 'Not updated',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.size});

  final String name;
  final double size;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CC';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
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
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .27,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AccountSectionTitle extends StatelessWidget {
  const _AccountSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: CoolCareColors.mutedText,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: .25,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              style: const TextStyle(color: CoolCareColors.text, fontSize: 11),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: CoolCareColors.mutedText,
            size: 18,
          ),
        ],
      ),
    );
  }
}

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
          style: const TextStyle(
            color: CoolCareColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CoolCareColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CoolCareColors.mutedText,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: CoolCareColors.text, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
