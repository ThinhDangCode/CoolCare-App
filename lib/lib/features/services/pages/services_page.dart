import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';
import 'service_detail_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServiceController _controller;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = ServiceController(apiClient: ApiClient.fromEnvironment());

    _controller.addListener(_refresh);
    _controller.loadInitialData();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged(String value) {
    _controller.searchServices(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.searchServices('');
  }

  void _selectService(String? serviceId) {
    _controller.filterByService(serviceId);
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
  }

  void _openDetails(String serviceId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(serviceId: serviceId),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildServiceFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('acServices'),
            style: TextStyle(
              color: context.appText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.tr('chooseService'),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 12, color: context.appText),
          decoration: InputDecoration(
            hintText: context.tr('searchServices'),
            hintStyle: TextStyle(color: context.appMuted, fontSize: 11),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
              color: Color(0xFF6F8282),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : null,
            filled: true,
            fillColor: context.appSurface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFF109DA0),
                width: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE FILTERS
  // All + 4 service thật
  // ============================================================

  Widget _buildServiceFilters() {
    if (_controller.isLoading && _controller.allServices.isEmpty) {
      return const SizedBox(height: 42);
    }

    return SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _ServiceChip(
            label: context.tr('all'),
            selected: _controller.selectedServiceId == null,
            onTap: () {
              _selectService(null);
            },
          ),

          ..._controller.allServices.map((service) {
            return _ServiceChip(
              label: _chipName(service.name),
              selected: _controller.selectedServiceId == service.id,
              onTap: () {
                _selectService(service.id);
              },
            );
          }),
        ],
      ),
    );
  }

  String _chipName(String name) {
    final value = name.toLowerCase();

    if (value.contains('vệ sinh')) {
      return 'Vệ sinh';
    }

    if (value.contains('kiểm tra') || value.contains('chẩn đoán')) {
      return 'Kiểm tra';
    }

    if (value.contains('bảo dưỡng')) {
      return 'Bảo dưỡng';
    }

    if (value.contains('sửa chữa')) {
      return 'Sửa chữa';
    }

    return name;
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isLoading) {
      return _buildLoadingState();
    }

    if (_controller.errorMessage != null) {
      return _buildErrorState();
    }

    if (_controller.services.isEmpty) {
      return _buildEmptyState();
    }

    return _buildServiceList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF109DA0)),
          const SizedBox(height: 12),
          Text(
            context.tr('loadingServices'),
            style: TextStyle(color: context.appMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: Color(0xFF7B8C8C),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('unableLoadServices'),
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _controller.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF758686), fontSize: 11),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _controller.retry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(context.tr('tryAgain')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter =
        _controller.searchKeyword.isNotEmpty ||
        _controller.selectedServiceId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Color(0xFF7B8C8C),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilter
                  ? context.tr('noMatchingServices')
                  : context.tr('noServices'),
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasFilter
                  ? context.tr('changeSearch')
                  : context.tr('noActiveServices'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF758686), fontSize: 11),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearFilters,
                child: Text(context.tr('clearFilters')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE LIST
  // ============================================================

  Widget _buildServiceList() {
    return RefreshIndicator(
      onRefresh: _controller.retry,
      color: const Color(0xFF109DA0),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _controller.services.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox(height: 9) : const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildListHeader();
          }

          final service = _controller.services[index - 1];

          return _ServiceCard(
            service: service,
            onDetails: () => _openDetails(service.id),
            onBook: () => _openDetails(service.id),
          );
        },
      ),
    );
  }

  Widget _buildListHeader() {
    String title = context.tr('all');

    if (_controller.selectedServiceId != null) {
      for (final service in _controller.allServices) {
        if (service.id == _controller.selectedServiceId) {
          title = service.name;
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_controller.services.length} '
          '${_controller.services.length == 1 ? 'service' : 'services'}',
          style: TextStyle(
            color: context.appMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SERVICE CHIP
// ============================================================

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        label: Text(label, maxLines: 1),
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.appText,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: const Color(0xFF109DA0),
        backgroundColor: context.appSurface,
        side: BorderSide(
          color: selected ? const Color(0xFF109DA0) : context.appBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ============================================================
// SERVICE CARD
// ============================================================

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onDetails,
    required this.onBook,
  });

  final ServiceModel service;
  final VoidCallback onDetails;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(context),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceType(service.name).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF109DA0),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  service.name,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                if (service.description != null &&
                    service.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 9),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 210;

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PriceBlock(service: service),
                          const SizedBox(height: 8),
                          _CardActions(onBook: onBook, onDetails: onDetails),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _PriceBlock(service: service)),
                        const SizedBox(width: 8),
                        _CardActions(onBook: onBook, onDetails: onDetails),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _serviceType(String name) {
    final value = name.toLowerCase();

    if (value.contains('vệ sinh')) {
      return 'Vệ sinh';
    }

    if (value.contains('kiểm tra') || value.contains('chẩn đoán')) {
      return 'Kiểm tra';
    }

    if (value.contains('bảo dưỡng')) {
      return 'Bảo dưỡng';
    }

    if (value.contains('sửa chữa')) {
      return 'Sửa chữa';
    }

    return 'Dịch vụ';
  }

  Widget _buildIcon(BuildContext context) {
    final name = service.name.toLowerCase();

    IconData icon = Icons.ac_unit_rounded;

    if (name.contains('sửa')) {
      icon = Icons.build_rounded;
    } else if (name.contains('kiểm tra') || name.contains('chẩn đoán')) {
      icon = Icons.search_rounded;
    } else if (name.contains('bảo dưỡng')) {
      icon = Icons.settings_suggest_rounded;
    } else if (name.contains('vệ sinh')) {
      icon = Icons.cleaning_services_rounded;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF173951)
            : const Color(0xFFEAF8F7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: const Color(0xFF109DA0), size: 20),
    );
  }
}

// ============================================================
// PRICE
// ============================================================

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('startingFrom'),
          style: TextStyle(color: context.appMuted, fontSize: 7),
        ),
        const SizedBox(height: 2),
        Text(
          _formatPrice(service.basePrice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

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
// ACTIONS
// ============================================================

class _CardActions extends StatelessWidget {
  const _CardActions({required this.onBook, required this.onDetails});

  final VoidCallback onBook;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF109DA0),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.tr('bookService'),
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
            ),
          ),
        ),

        const SizedBox(width: 7),

        InkWell(
          onTap: onDetails,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              '${context.tr('serviceDetails')} →',
              style: const TextStyle(
                color: Color(0xFF109DA0),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
