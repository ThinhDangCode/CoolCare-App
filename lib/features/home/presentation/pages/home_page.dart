import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../app/theme/coolcare_theme.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/service_text.dart';
import '../../../../app/preferences/preference_actions.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/pages/account_page.dart';
import '../../../address/pages/addresses_page.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/pages/login_page.dart';
import '../../../blogs/pages/blog_pages.dart';
import '../../../blogs/models/blog_article.dart';
import '../../../blogs/repositories/blog_repository.dart';
import '../../../booking/pages/my_bookings_page.dart';
import '../../../chat/chat_inbox_page.dart';
import '../../../chat/chat_unread.dart';
import '../../../notifications/pages/customer_notifications_page.dart';
import '../../../notifications/repositories/customer_notifications_repository.dart';
import '../../../services/controllers/service_controller.dart';
import '../../../services/models/service_model.dart';
import '../../../services/pages/service_detail_page.dart';
import '../../../services/pages/services_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  late final CustomerNotificationsRepository _notificationsRepository;
  Timer? _notificationRefreshTimer;
  Timer? _sessionRefreshTimer;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _notificationsRepository = CustomerNotificationsRepository();
    _wasAuthenticated = widget.controller.status == AuthStatus.authenticated;
    widget.controller.addListener(_handleAuthenticationChange);
    ChatUnread.instance.addListener(_onChatChanged);
    if (_wasAuthenticated) {
      _refreshUnreadNotificationCount();
      ChatUnread.instance.start();
    }
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _refreshUnreadNotificationCount(),
    );
    _sessionRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => widget.controller.refreshSession(),
    );
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleAuthenticationChange);
      widget.controller.addListener(_handleAuthenticationChange);
      _wasAuthenticated = widget.controller.status == AuthStatus.authenticated;
      if (_wasAuthenticated) {
        _refreshUnreadNotificationCount();
      } else {
        setState(() => _unreadNotificationCount = 0);
      }
    }
  }

  @override
  void dispose() {
    ChatUnread.instance.removeListener(_onChatChanged);
    widget.controller.removeListener(_handleAuthenticationChange);
    _notificationRefreshTimer?.cancel();
    _sessionRefreshTimer?.cancel();
    super.dispose();
  }

  void _handleAuthenticationChange() {
    final authenticated = widget.controller.status == AuthStatus.authenticated;
    if (authenticated == _wasAuthenticated) return;
    _wasAuthenticated = authenticated;
    if (authenticated) {
      _refreshUnreadNotificationCount();
      ChatUnread.instance.start();
    } else {
      ChatUnread.instance.stop();
      if (mounted) {
        setState(() {
          _selectedIndex = 0;
          _unreadNotificationCount = 0;
        });
        final notice = widget.controller.sessionNotice;
        if (notice != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.tr(notice))));
          });
        }
      }
    }
  }

  void _onChatChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openChat() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatInboxPage()));
  }

  Future<void> _refreshUnreadNotificationCount() async {
    if (widget.controller.status != AuthStatus.authenticated) return;
    final userId = widget.controller.user?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      final result = await _notificationsRepository.list(
        page: 1,
        unreadOnly: true,
      );
      if (!mounted ||
          widget.controller.status != AuthStatus.authenticated ||
          widget.controller.user?.id != userId) {
        return;
      }
      if (_unreadNotificationCount != result.unreadCount) {
        setState(() => _unreadNotificationCount = result.unreadCount);
      }
    } catch (_) {
      // Keep the last known count when a brief network failure occurs.
    }
  }

  Future<void> _openLogin(BuildContext context) async {
    final destination = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LoginPage(controller: widget.controller),
      ),
    );

    if (destination == 'services' && mounted) {
      _selectTab(1);
    }
  }

  void _openProfile() {
    final user = widget.controller.user;

    if (user == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PersonalProfilePage(user: user, controller: widget.controller),
      ),
    );
  }

  void _openAddresses() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddressesPage()));
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerNotificationsPage(),
      ),
    );
    await _refreshUnreadNotificationCount();
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
    if (index == 3 && widget.controller.status == AuthStatus.authenticated) {
      widget.controller.refreshSession();
    }
  }

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _HomeBody(onExploreServices: () => _selectTab(1));

      case 1:
        return const ServicesPage();

      case 2:
        if (widget.controller.status == AuthStatus.authenticated) {
          return const MyBookingsPage();
        }

        return _RestrictedPage(onLogin: () => _openLogin(context));

      case 3:
        if (widget.controller.user == null) {
          return _RestrictedPage(onLogin: () => _openLogin(context));
        }

        return AccountPage(
          user: widget.controller.user!,
          controller: widget.controller,
          onViewProfile: _openProfile,
          onViewAddresses: _openAddresses,
          onLogout: () async {
            await widget.controller.logout();

            if (mounted) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
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
                  onNotifications: _openNotifications,
                  unreadNotificationCount: _unreadNotificationCount,
                  onChat: _openChat,
                  unreadChatCount: ChatUnread.instance.count,
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
// ============================================================
// HEADER
// ============================================================

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.controller,
    required this.onLogin,
    required this.onNotifications,
    required this.unreadNotificationCount,
    required this.onChat,
    required this.unreadChatCount,
  });

  final AuthController controller;
  final VoidCallback onLogin;
  final VoidCallback onNotifications;
  final int unreadNotificationCount;
  final VoidCallback onChat;
  final int unreadChatCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cool',
                  style: TextStyle(color: context.appText),
                ),
                TextSpan(
                  text: 'Care',
                  style: TextStyle(color: CoolCareColors.primary),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const PreferenceActions(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.status == AuthStatus.authenticated) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onNotifications,
                      tooltip: unreadNotificationCount > 0
                          ? 'Notifications, $unreadNotificationCount unread'
                          : 'Notifications',
                      visualDensity: VisualDensity.compact,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: CoolCareColors.primaryDark,
                            size: 20,
                          ),
                          if (unreadNotificationCount > 0)
                            Positioned(
                              top: -7,
                              right: -9,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 17,
                                  minHeight: 17,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$unreadNotificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onChat,
                      tooltip: unreadChatCount > 0
                          ? 'Messages, $unreadChatCount unread'
                          : 'Messages',
                      visualDensity: VisualDensity.compact,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: CoolCareColors.primaryDark,
                            size: 20,
                          ),
                          if (unreadChatCount > 0)
                            Positioned(
                              top: -3,
                              right: -4,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return TextButton.icon(
                onPressed: onLogin,
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: CoolCareColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                ),
                label: Text(
                  context.tr('login'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.north_east_rounded, size: 12),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME BODY
// ============================================================

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.onExploreServices});

  final VoidCallback onExploreServices;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final ServiceController _serviceController;
  late final BlogRepository _blogRepository;
  late Future<List<BlogArticle>> _articles;

  @override
  void initState() {
    super.initState();

    _serviceController = ServiceController(
      apiClient: ApiClient.fromEnvironment(),
    );
    _blogRepository = BlogRepository();
    _articles = _blogRepository.getPublishedBlogs();

    _serviceController.addListener(_refresh);
    _serviceController.loadInitialData();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshHome() async {
    final articles = _blogRepository.getPublishedBlogs();
    setState(() => _articles = articles);
    await _serviceController.loadInitialData();
    try {
      await articles;
    } catch (_) {
      // The article card shows its own retry state.
    }
  }

  void _openService(ServiceModel service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(serviceId: service.id),
      ),
    );
  }

  @override
  void dispose() {
    _serviceController.removeListener(_refresh);
    _serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CoolCareColors.primary,
      onRefresh: _refreshHome,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(onExploreServices: widget.onExploreServices),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('howCanWeHelp')),
            const SizedBox(height: 12),
            _buildServices(),
            const SizedBox(height: 22),
            _SectionTitle(context.tr('bookingMadeSimple')),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BookingStep(
                    number: '01',
                    label: context.tr('chooseServiceStep'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _BookingStep(
                    number: '02',
                    label: context.tr('scheduleStep'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _BookingStep(
                    number: '03',
                    label: context.tr('chooseTechnicianStep'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _SectionTitle(context.tr('latestArticles'))),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BlogListPage()),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('seeMore'),
                    style: const TextStyle(
                      color: CoolCareColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CareArticle(articles: _articles, onRetry: _refreshHome),
          ],
        ),
      ),
    );
  }

  Widget _buildServices() {
    if (_serviceController.isLoading &&
        _serviceController.allServices.isEmpty) {
      return const SizedBox(
        height: 112,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CoolCareColors.primary,
          ),
        ),
      );
    }

    if (_serviceController.errorMessage != null &&
        _serviceController.allServices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CoolCareColors.surfaceTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              context.tr('unableLoadServices'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _serviceController.retry,
              child: Text(context.tr('tryAgain')),
            ),
          ],
        ),
      );
    }

    final services = _serviceController.allServices.take(4).toList();

    if (services.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          context.tr('noServices'),
          style: TextStyle(color: context.appMuted, fontSize: 11),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: services.map((service) {
            return SizedBox(
              width: itemWidth,
              child: _ServiceShortcut(
                icon: _serviceIcon(service.name),
                label: localizedServiceName(context, service.name),
                onTap: () => _openService(service),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _serviceIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('vệ sinh')) {
      return Icons.cleaning_services_outlined;
    }

    if (value.contains('kiểm tra') || value.contains('chẩn đoán')) {
      return Icons.search_rounded;
    }

    if (value.contains('bảo dưỡng')) {
      return Icons.settings_suggest_outlined;
    }

    if (value.contains('sửa chữa') || value.contains('sửa')) {
      return Icons.build_outlined;
    }

    return Icons.home_repair_service_outlined;
  }
}

// ============================================================
// HERO
// ============================================================

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onExploreServices});

  final VoidCallback onExploreServices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? CoolCareColors.primary.withValues(alpha: .12)
            : CoolCareColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('homeCareService'),
                  style: TextStyle(
                    color: CoolCareColors.primaryDark,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('heroTitle'),
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 18,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('heroSubtitle'),
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 35,
                  child: FilledButton.icon(
                    onPressed: onExploreServices,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    label: Text(
                      context.tr('exploreServices'),
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
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Icon(
              Icons.air_rounded,
              size: 52,
              color: CoolCareColors.primary.withValues(alpha: .18),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appText,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================
// REAL SERVICE SHORTCUT
// ============================================================

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CoolCareColors.surfaceTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: CoolCareColors.primary, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 9.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING STEP
// ============================================================

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
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          style: TextStyle(color: context.appMuted, fontSize: 9, height: 1.25),
        ),
      ],
    );
  }
}

// ============================================================
// LATEST ARTICLE
// ============================================================

class _CareArticle extends StatelessWidget {
  const _CareArticle({required this.articles, required this.onRetry});

  final Future<List<BlogArticle>> articles;
  final VoidCallback onRetry;

  String _summary(String content) {
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty ||
          line.startsWith('#') ||
          line.startsWith('-') ||
          RegExp(r'^\d+[.)]\s').hasMatch(line)) {
        continue;
      }
      return line.replaceAll(RegExp(r'\*\*|__|`'), '');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BlogArticle>>(
      future: articles,
      builder: (context, snapshot) {
        final published = snapshot.data ?? const <BlogArticle>[];
        final article = published.isEmpty ? null : published.first;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final title = loading
            ? context.tr('loadingArticles')
            : snapshot.hasError
            ? context.tr('unableLoadArticles')
            : article?.title ?? context.tr('noArticles');
        final action = snapshot.hasError
            ? context.tr('tryAgain')
            : article == null
            ? context.tr('seeMore')
            : context.tr('readArticle');

        return InkWell(
      onTap: loading
          ? null
          : snapshot.hasError
          ? onRetry
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => article == null
                    ? const BlogListPage()
                    : BlogDetailPage(articleId: article.id),
              ),
            ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border.all(color: context.appBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: CoolCareColors.surfaceTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: article?.thumbnailUrl?.isNotEmpty == true
                  ? Image.network(
                      article!.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.article_outlined,
                        color: CoolCareColors.primary,
                        size: 27,
                      ),
                    )
                  : const Icon(
                      Icons.article_outlined,
                      color: CoolCareColors.primary,
                      size: 27,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COOLCARE BLOG',
                    style: TextStyle(
                      color: CoolCareColors.primary,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (article != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      _summary(article.content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    action,
                    style: const TextStyle(
                      color: CoolCareColors.primary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

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
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: CoolCareColors.primary,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: context.tr('home'),
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view_rounded,
            label: context.tr('services'),
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _NavItem(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            label: context.tr('myBookings'),
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: context.tr('account'),
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NAV ITEM
// ============================================================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: .17)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESTRICTED
// ============================================================

class _RestrictedPage extends StatelessWidget {
  const _RestrictedPage({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
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
            Text(
              context.tr('signInToContinue'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('signInRequiredHint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              height: 42,
              child: FilledButton(
                onPressed: onLogin,
                child: Text(context.tr('login')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
