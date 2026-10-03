import 'package:flutter/material.dart';

import '../../../../app/theme/coolcare_theme.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/screens/login_page.dart';
import '../../../services/presentation/pages/services_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  Future<void> _openLogin(BuildContext context) async {
    final destination = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LoginPage(controller: widget.controller),
      ),
    );
    if (destination == 'services' && mounted) _selectTab(1);
  }

  void _openProfile() {
    final user = widget.controller.user;
    if (user == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PersonalProfilePage(user: user)));
  }

  Widget _selectedPage() {
    return switch (_selectedIndex) {
      0 => _HomeBody(onExploreServices: () => _selectTab(1)),
      1 => const ServicesPage(),
      2 =>
        widget.controller.status == AuthStatus.authenticated
            ? const _BookingsPage()
            : _RestrictedPage(onLogin: () => _openLogin(context)),
      3 =>
        widget.controller.user == null
            ? _RestrictedPage(onLogin: () => _openLogin(context))
            : AccountPage(
                user: widget.controller.user!,
                onViewProfile: _openProfile,
                onLogout: () async {
                  await widget.controller.logout();
                  if (mounted) setState(() => _selectedIndex = 0);
                },
              ),
      _ => const SizedBox.shrink(),
    };
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _HomeHeader(
                  controller: widget.controller,
                  onLogin: () => _openLogin(context),
                ),
                Expanded(child: _selectedPage()),
                _HomeNavigation(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller, required this.onLogin});

  final AuthController controller;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EEEE))),
      ),
      child: Row(
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cool',
                  style: TextStyle(color: CoolCareColors.text),
                ),
                TextSpan(
                  text: 'Care',
                  style: TextStyle(color: CoolCareColors.primary),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.status == AuthStatus.authenticated) {
                return const Row(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: CoolCareColors.primaryDark,
                      size: 20,
                    ),
                    SizedBox(width: 14),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: CoolCareColors.primaryDark,
                      size: 18,
                    ),
                  ],
                );
              }
              return TextButton.icon(
                onPressed: onLogin,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.north_east_rounded, size: 14),
                label: const Text('Log In'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.onExploreServices});

  final VoidCallback onExploreServices;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(onExploreServices: onExploreServices),
          const SizedBox(height: 26),
          const _SectionTitle('How can we help?'),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ServiceShortcut(
                icon: Icons.cleaning_services_outlined,
                label: 'Cleaning',
                onTap: onExploreServices,
              ),
              _ServiceShortcut(
                icon: Icons.build_outlined,
                label: 'Repair',
                onTap: onExploreServices,
              ),
              _ServiceShortcut(
                icon: Icons.air_rounded,
                label: 'Installation',
                onTap: onExploreServices,
              ),
            ],
          ),
          const SizedBox(height: 27),
          const _SectionTitle('Booking made simple'),
          const SizedBox(height: 13),
          const Row(
            children: [
              Expanded(
                child: _BookingStep(number: '01', label: 'Choose service'),
              ),
              Expanded(
                child: _BookingStep(number: '02', label: 'Schedule'),
              ),
              Expanded(
                child: _BookingStep(number: '03', label: 'Choose\ntechnician'),
              ),
            ],
          ),
          const SizedBox(height: 27),
          const Row(
            children: [
              Expanded(child: _SectionTitle('AC Care')),
              Text(
                'See more  →',
                style: TextStyle(
                  color: CoolCareColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _CareArticle(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onExploreServices});

  final VoidCallback onExploreServices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 19, 16, 18),
      decoration: BoxDecoration(
        color: CoolCareColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 3,
            top: 40,
            child: Icon(
              Icons.air_rounded,
              size: 54,
              color: CoolCareColors.primary.withValues(alpha: .18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HOME AC CARE SERVICE',
                style: TextStyle(
                  color: CoolCareColors.primaryDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cool comfort, every\nday.\nPeace of mind,\nalways.',
                style: TextStyle(
                  color: CoolCareColors.text,
                  fontSize: 21,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find the right service,\nbook at your convenience.',
                style: TextStyle(
                  color: CoolCareColors.mutedText,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onExploreServices,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: const Text(
                  'Explore Services',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CoolCareColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ServiceShortcut extends StatelessWidget {
  const _ServiceShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: CoolCareColors.surfaceTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: CoolCareColors.primary, size: 25),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: const TextStyle(
                color: CoolCareColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingStep extends StatelessWidget {
  const _BookingStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: CoolCareColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: CoolCareColors.mutedText,
            fontSize: 9,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CareArticle extends StatelessWidget {
  const _CareArticle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: CoolCareColors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.ac_unit_rounded,
              color: CoolCareColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIPS & TRICKS',
                  style: TextStyle(
                    color: CoolCareColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'When should you clean your AC?',
                  style: TextStyle(
                    color: CoolCareColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Read article  →',
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
    );
  }
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      color: CoolCareColors.primary,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Services',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _NavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'My Bookings',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Account',
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (selected)
                Container(
                  width: 48,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              Column(
                children: [
                  const SizedBox(height: 7),
                  Icon(icon, color: Colors.white, size: 19),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: selected ? 1 : .9,
                        ),
                        fontSize: 8,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 58,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestrictedPage extends StatelessWidget {
  const _RestrictedPage({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: CoolCareColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: CoolCareColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign in to continue',
              style: TextStyle(
                color: CoolCareColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Log in to view your bookings and manage your CoolCare account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoolCareColors.mutedText,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: onLogin,
                child: const Text('Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsPage extends StatelessWidget {
  const _BookingsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(
              color: CoolCareColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: CoolCareColors.primary,
                  size: 38,
                ),
                SizedBox(height: 12),
                Text(
                  'No active bookings',
                  style: TextStyle(
                    color: CoolCareColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your upcoming services will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CoolCareColors.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
