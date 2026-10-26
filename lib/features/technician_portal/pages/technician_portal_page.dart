import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/models/auth_user.dart';
import '../../chat/chat_inbox_page.dart';
import '../../chat/chat_unread.dart';
import '../models/technician_dashboard.dart';
import '../models/view_job_request.dart';
import '../models/set_availability_status.dart';
import '../repositories/technician_portal_repository.dart';
import '../repositories/technician_notifications_repository.dart';
import 'technician_notifications_page.dart';
import 'certification_status_page.dart';
import 'manage_skills_page.dart';
import 'manage_service_areas_page.dart';
import 'view_job_requests_page.dart';
import 'view_job_request_detail_page.dart';
import 'my_ratings_page.dart';
import '../../technician_wallet/pages/technician_wallet_page.dart';

class TechnicianPortalPage extends StatefulWidget {
  const TechnicianPortalPage({required this.user, super.key});

  final AuthUser user;

  @override
  State<TechnicianPortalPage> createState() => _TechnicianPortalPageState();
}

class _TechnicianPortalPageState extends State<TechnicianPortalPage> {
  late final TechnicianPortalRepository _repository;
  late final TechnicianNotificationsRepository _notificationsRepository;
  Timer? _notificationRefreshTimer;
  TechnicianDashboard? _dashboard;
  List<ViewJobRequest> _jobRequests = const [];
  String? _error;
  int _tab = 0;
  bool _changingAvailability = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = TechnicianPortalRepository(
      apiClient: ApiClient.fromEnvironment(),
    );
    _notificationsRepository = TechnicianNotificationsRepository();
    ChatUnread.instance.addListener(_onChatChanged);
    ChatUnread.instance.start();
    _load();
    _refreshUnreadNotifications();
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _refreshUnreadNotifications(),
    );
  }

  @override
  void dispose() {
    ChatUnread.instance.removeListener(_onChatChanged);
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  void _onChatChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshUnreadNotifications() async {
    try {
      final result = await _notificationsRepository.list();
      if (mounted) setState(() => _unreadNotificationCount = result.unreadCount);
    } catch (_) {
      // Keep the last known badge count if this background refresh fails.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianNotificationsPage(
          repository: _notificationsRepository,
        ),
      ),
    );
    await _refreshUnreadNotifications();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await Future.wait([
        _repository.dashboard(),
        _repository.availabilityStatus(),
        _repository.viewJobRequests(status: 'ALL'),
      ]);
      final value = result[0] as TechnicianDashboard;
      final availability = result[1] as SetAvailabilityStatus;
      final jobRequests = result[2] as List<ViewJobRequest>;
      if (mounted) {
        setState(() {
          _dashboard = value.withAvailability(availability.status);
          _jobRequests = jobRequests;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('technicianModeLoadFailed'));
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
              context.tr(
                online ? 'technicianOnlineNotice' : 'technicianOfflineNotice',
              ),
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'CoolCare',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: _unreadNotificationCount > 0
                ? '$_unreadNotificationCount unread notifications'
                : 'Notifications',
            onPressed: _openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    top: -7,
                    right: -9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD94B4B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.appSurface, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                      onViewJobRequests: () => setState(() => _tab = 1),
                      onViewNextJob: _openNextJob,
                    ),
                    ViewJobRequestsPage(
                      repository: _repository,
                      onRequestChanged: _load,
                    ),
                    const ChatInboxPage(embedded: true),
                    const TechnicianWalletPage(),
                    _TechnicianProfile(
                      user: widget.user,
                      dashboard: _dashboard!,
                      repository: _repository,
                      changingAvailability: _changingAvailability,
                      onAvailabilityChanged: _toggleAvailability,
                      onRatingsViewed: _load,
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
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: context.tr('home'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.assignment_outlined),
                      label: context.tr('jobs'),
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: ChatUnread.instance.count > 0,
                        label: Text('${ChatUnread.instance.count}'),
                        child: const Icon(Icons.forum_outlined),
                      ),
                      label: context.tr('messages'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: context.tr('wallet'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      label: context.tr('profile'),
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

  Future<void> _openNextJob() async {
    final bookingId = _dashboard?.nextJob?.id;
    ViewJobRequest? request;
    for (final item in _jobRequests) {
      if (item.booking.id == bookingId) {
        request = item;
        break;
      }
    }
    if (request == null) {
      setState(() => _tab = 1);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ViewJobRequestDetailPage(
          request: request!,
          repository: _repository,
        ),
      ),
    );
    if (changed == true && mounted) await _load();
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.dashboard,
    required this.changingAvailability,
    required this.onAvailabilityChanged,
    required this.onRefresh,
    required this.onViewJobRequests,
    required this.onViewNextJob,
  });

  final TechnicianDashboard dashboard;
  final bool changingAvailability;
  final ValueChanged<bool> onAvailabilityChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onViewJobRequests;
  final VoidCallback onViewNextJob;

  @override
  Widget build(BuildContext context) {
    final online = dashboard.availability == 'ONLINE';
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: context.appSurface,
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
                        _qualification(context, dashboard.qualification),
                        style: TextStyle(color: context.appMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(online ? 'online' : 'offline'),
                      style: TextStyle(
                        color: online
                            ? CoolCareColors.primary
                            : context.appMuted,
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
                      context.trArgs('technicianNewRequestsNotice', {
                        'count': dashboard.pendingRequests,
                      }),
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
                _NextJobCard(
                  job: dashboard.nextJob,
                  onViewDetails: onViewNextJob,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 76,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: context.tr('jobsToday'),
                          value: context.trArgs('jobCount', {
                            'count': dashboard.jobsToday,
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: context.tr('earnings'),
                          value: _money(dashboard.earningsToday),
                          accent: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: context.tr('rating'),
                          value: dashboard.rating == 0
                              ? context.tr('noRatings')
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
                      context.trArgs('newRequestsCount', {
                        'count': dashboard.pendingRequests,
                      }),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewJobRequests,
                      child: Text('${context.tr('viewAll')} →'),
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
  const _NextJobCard({required this.onViewDetails, this.job});
  final TechnicianNextJob? job;
  final VoidCallback onViewDetails;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: job == null
        ? Column(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 38,
                color: CoolCareColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('noUpcomingJobs'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('newRequestsAppearHere'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appMuted),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('newRequest').toUpperCase(),
                    style: TextStyle(
                      color: context.appMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Chip(label: Text(context.tr('newRequest'))),
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
              Text('📅  ${_date(context, job!.scheduledAt)}'),
              const SizedBox(height: 6),
              Text(
                '📍  ${job!.address}',
                style: TextStyle(color: context.appMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onViewDetails,
                  child: Text(context.tr('viewDetails')),
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
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appMuted,
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
            color: accent ? CoolCareColors.primary : context.appText,
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
    required this.repository,
    required this.changingAvailability,
    required this.onAvailabilityChanged,
    required this.onRatingsViewed,
    required this.onSwitchCustomer,
  });
  final AuthUser user;
  final TechnicianDashboard dashboard;
  final TechnicianPortalRepository repository;
  final bool changingAvailability;
  final ValueChanged<bool> onAvailabilityChanged;
  final Future<void> Function() onRatingsViewed;
  final VoidCallback onSwitchCustomer;

  Future<void> _openRatings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyRatingsPage(repository: repository)),
    );
    await onRatingsViewed();
  }
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        context.tr('myProfile'),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border.all(color: context.appBorder),
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
                        _qualification(context, dashboard.qualification),
                        style: TextStyle(color: context.appMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 3),
                      Semantics(
                        button: true,
                        label: context.tr('myRatings'),
                        child: InkWell(
                          onTap: () => _openRatings(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              dashboard.rating == 0
                                  ? context.tr('noRatingsYet')
                                  : '${dashboard.rating.toStringAsFixed(1)} ★',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('workingStatus'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        context.tr('workingStatusHint'),
                        style: TextStyle(color: context.appMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  context.tr(
                    dashboard.availability == 'ONLINE' ? 'online' : 'offline',
                  ),
                  style: TextStyle(
                    color: dashboard.availability == 'ONLINE'
                        ? CoolCareColors.primary
                        : context.appMuted,
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
      Text(
        context.tr('settingsPerformance').toUpperCase(),
        style: TextStyle(
          color: context.appMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 10),
      _ProfileSection(
        title: context.tr('verificationSkills').toUpperCase(),
        children: [
          _ProfileLink(
            icon: Icons.star_outline_rounded,
            label: context.tr('myRatings'),
            onTap: () => _openRatings(context),
          ),
          const Divider(height: 1),
          _ProfileLink(
            icon: Icons.workspace_premium_outlined,
            label: context.tr('certificationStatus'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CertificationStatusPage(),
              ),
            ),
          ),
          const Divider(height: 1),
          _ProfileLink(
            icon: Icons.build_outlined,
            label: context.tr('mySkills'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ManageSkillsPage())),
          ),
          const Divider(height: 1),
          _ProfileLink(
            icon: Icons.location_on_outlined,
            label: context.tr('serviceAreas'),
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
        label: Text(context.tr('switchCustomerMode')),
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
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.appMuted,
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
        FilledButton(onPressed: onRetry, child: Text(context.tr('tryAgain'))),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('returnCustomerMode')),
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
String _qualification(BuildContext context, String value) =>
    {
      'BEGINNER': context.tr('qualificationBeginner'),
      'INTERMEDIATE': context.tr('qualificationIntermediate'),
      'ADVANCED': context.tr('qualificationAdvanced'),
      'EXPERT': context.tr('qualificationExpert'),
    }[value] ??
    context.tr('coolcareTechnician');
String _date(BuildContext context, DateTime? value) => value == null
    ? context.tr('notScheduled')
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} - ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _money(double value) {
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+$)'),
    (_) => '.',
  );
  return '$formatted ₫';
}
