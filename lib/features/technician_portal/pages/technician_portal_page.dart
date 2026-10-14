import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/models/auth_user.dart';
import '../models/technician_dashboard.dart';
import '../models/set_availability_status.dart';
import '../repositories/technician_portal_repository.dart';
import 'certification_status_page.dart';
import 'manage_skills_page.dart';
import 'manage_service_areas_page.dart';

class TechnicianPortalPage extends StatefulWidget {
  const TechnicianPortalPage({required this.user, super.key});

  final AuthUser user;

  @override
  State<TechnicianPortalPage> createState() => _TechnicianPortalPageState();
}

class _TechnicianPortalPageState extends State<TechnicianPortalPage> {
  late final TechnicianPortalRepository _repository;
  TechnicianDashboard? _dashboard;
  String? _error;
  int _tab = 0;
  bool _changingAvailability = false;

  @override
  void initState() {
    super.initState();
    _repository = TechnicianPortalRepository(
      apiClient: ApiClient.fromEnvironment(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await Future.wait([
        _repository.dashboard(),
        _repository.availabilityStatus(),
      ]);
      final value = result[0] as TechnicianDashboard;
      final availability = result[1] as SetAvailabilityStatus;
      if (mounted) {
        setState(() {
          _dashboard = value.withAvailability(availability.status);
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load Technician Mode.');
      }
    }
  }

  Future<void> _toggleAvailability(bool online) async {
    if (_changingAvailability) return;
    setState(() => _changingAvailability = true);
    try {
      final status = await _repository.setAvailabilityStatus(online);
      if (mounted) {
        setState(() {
          _dashboard = _dashboard?.withAvailability(status.status);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              online
                  ? 'Bạn đang Online và có thể nhận đơn mới.'
                  : 'Bạn đã Offline và sẽ không nhận đơn mới.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _changingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'CoolCare',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _dashboard == null
              ? _error == null
                    ? const Center(child: CircularProgressIndicator())
                    : _ErrorView(message: _error!, onRetry: _load)
              : IndexedStack(
                  index: _tab,
                  children: [
                    _DashboardHome(
                      dashboard: _dashboard!,
                      changingAvailability: _changingAvailability,
                      onAvailabilityChanged: _toggleAvailability,
                      onRefresh: _load,
                    ),
                    const _EmptyTab(
                      icon: Icons.assignment_outlined,
                      title: 'Jobs',
                      message: 'Your assigned jobs will appear here.',
                    ),
                    const _EmptyTab(
                      icon: Icons.forum_outlined,
                      title: 'Messages',
                      message: 'Chat with customers for each assigned job.',
                    ),
                    _WalletTab(amount: _dashboard!.earningsToday),
                    _TechnicianProfile(
                      user: widget.user,
                      dashboard: _dashboard!,
                      changingAvailability: _changingAvailability,
                      onAvailabilityChanged: _toggleAvailability,
                      onSwitchCustomer: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: CoolCareColors.primary,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? CoolCareColors.primary
                          : Colors.white,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _tab,
                  backgroundColor: CoolCareColors.primary,
                  indicatorColor: const Color(0xFFDDF7FA),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (value) =>
                      setState(() => _tab = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assignment_outlined),
                      label: 'Jobs',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.forum_outlined),
                      label: 'Messages',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: 'Wallet',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.dashboard,
    required this.changingAvailability,
    required this.onAvailabilityChanged,
    required this.onRefresh,
  });

  final TechnicianDashboard dashboard;
  final bool changingAvailability;
  final ValueChanged<bool> onAvailabilityChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final online = dashboard.availability == 'ONLINE';
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: dashboard.avatarUrl == null
                      ? null
                      : NetworkImage(dashboard.avatarUrl!),
                  child: dashboard.avatarUrl == null
                      ? Text(_initials(dashboard.name))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dashboard.name} 👋',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _qualification(dashboard.qualification),
                        style: const TextStyle(
                          color: CoolCareColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      online ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: online
                            ? CoolCareColors.primary
                            : CoolCareColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      height: 28,
                      child: FittedBox(
                        child: Switch(
                          value: online,
                          onChanged: changingAvailability
                              ? null
                              : onAvailabilityChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dashboard.pendingRequests > 0)
            Container(
              color: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF92400E),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have ${dashboard.pendingRequests} new service requests nearby!',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NextJobCard(job: dashboard.nextJob),
                const SizedBox(height: 16),
                SizedBox(
                  height: 76,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Jobs Today',
                          value: '${dashboard.jobsToday} jobs',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Earnings',
                          value: _money(dashboard.earningsToday),
                          accent: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Rating',
                          value: dashboard.rating == 0
                              ? 'No ratings'
                              : '${dashboard.rating.toStringAsFixed(1)} ★',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Requests (${dashboard.pendingRequests})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'View All →',
                      style: TextStyle(
                        color: CoolCareColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextJobCard extends StatelessWidget {
  const _NextJobCard({this.job});
  final TechnicianNextJob? job;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CoolCareColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: job == null
        ? const Column(
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 38,
                color: CoolCareColors.primary,
              ),
              SizedBox(height: 8),
              Text(
                'No upcoming jobs',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Accepted jobs will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CoolCareColors.mutedText),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'UPCOMING JOB',
                    style: TextStyle(
                      color: CoolCareColors.mutedText,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Chip(
                    label: Text(
                      job!.status == 'ACCEPTED' ? 'Accepted' : 'Selected',
                    ),
                  ),
                ],
              ),
              Text(
                job!.serviceName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text('📅  ${_date(job!.scheduledAt)}'),
              const SizedBox(height: 6),
              Text(
                '📍  ${job!.address}',
                style: const TextStyle(color: CoolCareColors.mutedText),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CoolCareColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CoolCareColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent ? CoolCareColors.primary : CoolCareColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _TechnicianProfile extends StatelessWidget {
  const _TechnicianProfile({
    required this.user,
    required this.dashboard,
    required this.changingAvailability,
    required this.onAvailabilityChanged,
    required this.onSwitchCustomer,
  });
  final AuthUser user;
  final TechnicianDashboard dashboard;
  final bool changingAvailability;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onSwitchCustomer;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'My Profile',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CoolCareColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.avatarUrl == null
                      ? null
                      : NetworkImage(user.avatarUrl!),
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person_outline, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_user_rounded,
                            color: CoolCareColors.primary,
                            size: 17,
                          ),
                        ],
                      ),
                      Text(
                        _qualification(dashboard.qualification),
                        style: const TextStyle(
                          color: CoolCareColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dashboard.rating == 0
                            ? 'No ratings yet'
                            : '${dashboard.rating.toStringAsFixed(1)} ★',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working Status',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Toggle to receive booking requests',
                        style: TextStyle(
                          color: CoolCareColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dashboard.availability == 'ONLINE' ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: dashboard.availability == 'ONLINE'
                        ? CoolCareColors.primary
                        : CoolCareColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Switch(
                  value: dashboard.availability == 'ONLINE',
                  onChanged: changingAvailability
                      ? null
                      : onAvailabilityChanged,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'SETTINGS & PERFORMANCE',
        style: TextStyle(
          color: CoolCareColors.mutedText,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 10),
      _ProfileSection(
        title: 'VERIFICATION & SKILLS',
        children: [
          _ProfileLink(
            icon: Icons.workspace_premium_outlined,
            label: 'Certification Status',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CertificationStatusPage(),
              ),
            ),
          ),
          const Divider(height: 1),
          _ProfileLink(
            icon: Icons.build_outlined,
            label: 'My Skills',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ManageSkillsPage())),
          ),
          const Divider(height: 1),
          _ProfileLink(
            icon: Icons.location_on_outlined,
            label: 'Service Areas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageServiceAreasPage()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      FilledButton.tonalIcon(
        onPressed: onSwitchCustomer,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Switch to Customer Mode'),
      ),
    ],
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CoolCareColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CoolCareColors.mutedText,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Icon(icon, color: CoolCareColors.primary, size: 20),
    title: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _WalletTab extends StatelessWidget {
  const _WalletTab({required this.amount});
  final double amount;
  @override
  Widget build(BuildContext context) => _EmptyTab(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Technician Wallet',
    message: "Today's earnings: ${_money(amount)}",
  );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: CoolCareColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoolCareColors.mutedText),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Try Again')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Return to Customer Mode'),
        ),
      ],
    ),
  );
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((e) => e.isNotEmpty)
    .take(2)
    .map((e) => e[0].toUpperCase())
    .join();
String _qualification(String value) =>
    {
      'BEGINNER': 'Junior AC Technician',
      'INTERMEDIATE': 'AC Technician',
      'ADVANCED': 'Senior AC Technician',
      'EXPERT': 'AC Specialist',
    }[value] ??
    'CoolCare Technician';
String _date(DateTime? value) => value == null
    ? 'Not scheduled'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} - ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _money(double value) {
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+$)'),
    (_) => '.',
  );
  return '$formatted ₫';
}
