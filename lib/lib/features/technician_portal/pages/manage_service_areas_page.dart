import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/technician_service_area.dart';
import '../repositories/technician_portal_repository.dart';

class ManageServiceAreasPage extends StatefulWidget {
  const ManageServiceAreasPage({super.key, this.repository});

  final TechnicianPortalRepository? repository;

  @override
  State<ManageServiceAreasPage> createState() => _ManageServiceAreasPageState();
}

class _ManageServiceAreasPageState extends State<ManageServiceAreasPage> {
  late final TechnicianPortalRepository _repository;
  TechnicianAreaOptions? _options;
  Set<String> _savedWards = {};
  Set<String> _selectedWards = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _changed => !_sameSet(_savedWards, _selectedWards);

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        TechnicianPortalRepository(apiClient: ApiClient.fromEnvironment());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        _repository.areaOptions(),
        _repository.areas(),
      ]);
      if (!mounted) return;
      final options = result[0] as TechnicianAreaOptions;
      final current = result[1] as List<TechnicianServiceArea>;
      final validWards = options.wards.toSet();
      final selected = current
          .where(
            (area) =>
                area.city == options.city && validWards.contains(area.ward),
          )
          .map((area) => area.ward)
          .toSet();
      setState(() {
        _options = options;
        _savedWards = selected;
        _selectedWards = {...selected};
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.tr('unableLoadServiceAreas');
          _loading = false;
        });
      }
    }
  }

  void _toggle(String ward) {
    if (_saving) return;
    setState(() {
      if (!_selectedWards.add(ward)) _selectedWards.remove(ward);
    });
  }

  Future<void> _save() async {
    final options = _options;
    if (options == null || _selectedWards.isEmpty || !_changed || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _repository.replaceAreas(
        city: options.city,
        wards: options.wards.where(_selectedWards.contains),
      );
      if (!mounted) return;
      final wards = saved.map((area) => area.ward).toSet();
      setState(() {
        _savedWards = wards;
        _selectedWards = {...wards};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('serviceAreasUpdated'))),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('unableSaveServiceAreas'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_changed,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _confirmDiscard();
    },
    child: Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: CoolCareColors.primary,
          onPressed: _changed
              ? _confirmDiscard
              : () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Text(
          context.tr('serviceAreas'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _AreaError(message: _error!, onRetry: _load)
          : _buildContent(),
    ),
  );

  Widget _buildContent() {
    final options = _options!;
    final available = options.wards
        .where((ward) => !_selectedWards.contains(ward))
        .toList();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _CanThoMapCard(),
                const SizedBox(height: 12),
                _ScopeCard(
                  city: options.city,
                  selectedCount: _selectedWards.length,
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  context.trArgs('selectedAreaCount', {
                    'count': _selectedWards.length,
                  }),
                ),
                const SizedBox(height: 8),
                if (_selectedWards.isEmpty)
                  const _EmptySelection()
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: options.wards
                        .where(_selectedWards.contains)
                        .map(
                          (ward) => InputChip(
                            label: Text(ward),
                            onDeleted: _saving ? null : () => _toggle(ward),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 15,
                            ),
                            labelStyle: const TextStyle(
                              color: CoolCareColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: context.appAccentSurface,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 22),
                _SectionTitle(context.tr('addWard').toUpperCase()),
                const SizedBox(height: 8),
                if (available.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      border: Border.all(color: context.appBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 19,
                          color: CoolCareColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('allAreasSelected'),
                          style: TextStyle(color: context.appMuted),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey('ward-dropdown-${_selectedWards.length}'),
                    initialValue: null,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.appSurface,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: CoolCareColors.primary,
                      ),
                      hintText: context.tr('selectWardToAdd'),
                    ),
                    items: available
                        .map(
                          (ward) => DropdownMenuItem<String>(
                            value: ward,
                            child: Text(
                              ward,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appText,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (ward) {
                            if (ward != null) _toggle(ward);
                          },
                  ),
                const SizedBox(height: 6),
                Text(
                  context.tr('canThoAreasOnly'),
                  style: TextStyle(color: context.appMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Container(
          color: context.appBackground,
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _selectedWards.isEmpty || !_changed || _saving
                  ? null
                  : _save,
              style: FilledButton.styleFrom(
                backgroundColor: CoolCareColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.tr('saveServiceAreas'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('discardChangesTitle')),
        content: Text(context.tr('discardServiceAreaChanges')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('continueEditing')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('discardChanges')),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }
}

class _CanThoMapCard extends StatelessWidget {
  const _CanThoMapCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 140,
    decoration: BoxDecoration(
      color: const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MapPatternPainter()),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CoolCareColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(
                context.tr('canThoArea').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..strokeWidth = 3;
    for (var x = -40.0; x < size.width + 40; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x + 90, size.height), road);
    }
    for (var y = 22.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 12), road);
    }
    final pin = Paint()..color = CoolCareColors.primary;
    for (final point in [
      Offset(size.width * .25, 35),
      Offset(size.width * .72, 40),
      Offset(size.width * .37, 105),
      Offset(size.width * .78, 102),
    ]) {
      canvas.drawCircle(point, 5, pin);
      canvas.drawCircle(
        point,
        9,
        Paint()..color = CoolCareColors.primary.withValues(alpha: .15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.city, required this.selectedCount});
  final String city;
  final int selectedCount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_city_rounded, color: CoolCareColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.tr('coolcareCanThoOnly'),
                style: TextStyle(fontSize: 11, color: context.appMuted),
              ),
            ],
          ),
        ),
        Text(
          context.trArgs('areaCount', {'count': selectedCount}),
          style: const TextStyle(
            color: CoolCareColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: CoolCareColors.mutedText,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.isDarkMode
          ? const Color(0xFF3A2D16)
          : const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      context.tr('selectAtLeastOneArea'),
      style: TextStyle(
        fontSize: 12,
        color: context.isDarkMode
            ? const Color(0xFFFFD580)
            : const Color(0xFF8A5A00),
      ),
    ),
  );
}

class _AreaError extends StatelessWidget {
  const _AreaError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 44,
            color: CoolCareColors.primary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr('tryAgain')),
          ),
        ],
      ),
    ),
  );
}

bool _sameSet(Set<String> first, Set<String> second) =>
    first.length == second.length && first.containsAll(second);
