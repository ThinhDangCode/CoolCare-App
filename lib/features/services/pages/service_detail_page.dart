import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../booking/pages/create_booking_page.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';

class ServiceDetailPage extends StatefulWidget {
  const ServiceDetailPage({required this.serviceId, super.key});

  final String serviceId;

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late final ServiceController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ServiceController(apiClient: ApiClient.fromEnvironment());

    _controller.addListener(_refresh);
    _controller.loadServiceDetail(widget.serviceId);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded, size: 20, color: context.appText),
      ),
      titleSpacing: 0,
      title: Text(
        context.tr('serviceDetails'),
        style: TextStyle(
          color: context.appText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isDetailLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF109DA0)),
            const SizedBox(height: 14),
            Text(
              context.tr('loadingService'),
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (_controller.detailErrorMessage != null) {
      return _buildErrorState();
    }

    final service = _controller.selectedService;

    if (service == null) {
      return Center(
        child: Text(
          context.tr('serviceNotFound'),
          style: TextStyle(color: context.appMuted, fontSize: 12),
        ),
      );
    }

    return _buildServiceDetail(service);
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: context.appAccentSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFF109DA0),
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              context.tr('unableLoadService'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _controller.detailErrorMessage ?? context.tr('genericError'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                _controller.loadServiceDetail(widget.serviceId);
              },
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(context.tr('tryAgain')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF109DA0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE DETAIL
  // ============================================================

  Widget _buildServiceDetail(ServiceModel service) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverview(service),
                const _SectionDivider(),

                _buildAbout(service),
                const _SectionDivider(),

                _buildServiceInformation(service),
                const _SectionDivider(),

                _buildBeforeBooking(),
                const _SectionDivider(),

                _buildCustomerReviews(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        _buildBottomBookingBar(service),
      ],
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview(ServiceModel service) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: TextStyle(
              color: context.appText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),

          if (service.description != null &&
              service.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              service.description!,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 15),

          Text(
            context.tr('startingFrom'),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '${_formatPrice(service.basePrice)} / ${context.tr('servicePriceUnit')}',
            style: const TextStyle(
              color: Color(0xFF109DA0),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            context.tr('finalCostNote'),
            style: TextStyle(color: context.appMuted, fontSize: 9, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAbout(ServiceModel service) {
    final description = service.description?.trim();

    return _Section(
      title: context.tr('aboutService'),
      child: Text(
        description != null && description.isNotEmpty
            ? description
            : context.tr('serviceInfoUpdating'),
        style: TextStyle(color: context.appMuted, fontSize: 10, height: 1.5),
      ),
    );
  }

  // ============================================================
  // SERVICE INFORMATION
  // ============================================================

  Widget _buildServiceInformation(ServiceModel service) {
    final items = <Widget>[];

    if (service.estimatedDuration != null) {
      items.add(
        _InfoRow(
          icon: Icons.schedule_rounded,
          title: context.tr('estimatedDuration'),
          value: '${service.estimatedDuration} ${context.tr('minutes')}',
        ),
      );
    }

    if (service.maintenanceIntervalDays != null) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(height: 12));
      }

      items.add(
        _InfoRow(
          icon: Icons.event_repeat_rounded,
          title: context.tr('maintenanceInterval'),
          value: '${service.maintenanceIntervalDays} ${context.tr('days')}',
        ),
      );
    }

    if (items.isEmpty) {
      return _Section(
        title: context.tr('aboutService'),
        child: Text(
          context.tr('additionalInfoUpdating'),
          style: TextStyle(color: context.appMuted, fontSize: 10, height: 1.5),
        ),
      );
    }

    return _Section(
      title: context.tr('aboutService'),
      child: Column(children: items),
    );
  }

  // ============================================================
  // BEFORE BOOKING
  // ============================================================

  Widget _buildBeforeBooking() {
    return _Section(
      title: context.tr('beforeBooking'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appAccentSurface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: Color(0xFF109DA0),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                context.tr('beforeBookingNote'),
                style: TextStyle(
                  color: context.appSubtleText,
                  fontSize: 9,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOMER REVIEWS
  // ============================================================

  Widget _buildCustomerReviews() {
    final reviews = _controller.reviews;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('customerReviews'),
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (reviews.length > 2)
                TextButton(
                  onPressed: () {
                    _showAllReviews();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('viewAll'),
                    style: const TextStyle(
                      color: Color(0xFF109DA0),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (reviews.isEmpty)
            _buildEmptyReviews()
          else
            ...reviews
                .take(2)
                .map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildReviewCard(review),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: context.appSoftSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, color: context.appMuted, size: 25),
          const SizedBox(height: 7),
          Text(
            context.tr('noReviews'),
            style: TextStyle(
              color: context.appText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.tr('reviewsAppearHere'),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _parseRating(review['rating']);

    final comment = review['comment']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appAccentSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF109DA0),
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('customer'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                _buildStars(rating),

                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 7),

                  Text(
                    comment,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 9,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    final safeRating = rating.clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 1),
          child: Icon(
            index < safeRating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 14,
            color: const Color(0xFFFFB547),
          ),
        );
      }),
    );
  }

  int _parseRating(dynamic value) {
    if (value is num) {
      return value.toInt().clamp(0, 5);
    }

    return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 5);
  }

  // ============================================================
  // VIEW ALL REVIEWS
  // ============================================================

  void _showAllReviews() {
    final reviews = _controller.reviews;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('customerReviews'),
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: context.appBorder),

                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(reviews[index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOTTOM BOOKING BAR
  // ============================================================

  Widget _buildBottomBookingBar(ServiceModel service) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('from'),
                      style: TextStyle(color: context.appMuted, fontSize: 8),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${_formatPrice(service.basePrice)} / ${context.tr('servicePriceUnit')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: () => _openBooking(service),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF109DA0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    context.tr('bookService'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  void _openBooking(ServiceModel service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateBookingPage(initialServiceId: service.id),
      ),
    );
  }

  // ============================================================
  // PRICE
  // ============================================================

  String _formatPrice(dynamic value) {
    final number = value is num ? value : num.tryParse(value.toString()) ?? 0;

    final digits = number.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return '${buffer.toString()} ₫';
  }
}

// ============================================================
// SECTION
// ============================================================

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.appText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: context.appAccentSurface,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: const Color(0xFF109DA0), size: 16),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: context.appMuted, fontSize: 9),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DIVIDER
// ============================================================

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.appBorder);
  }
}
