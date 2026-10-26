import '../../../app/localization/app_strings.dart';
import 'my_bookings_page.dart';
import 'package:flutter/material.dart';

/// A technician returned by the booking recommendation API.
class RecommendedTechnician {
  const RecommendedTechnician({
    required this.id,
    required this.name,
    this.rating,
    this.reviewCount = 0,
    this.experienceYears,
    this.about,
    this.skills = const [],
    this.serviceAreas = const [],
    this.matchReason,
  });

  final String id;
  final String name;
  final double? rating;
  final int reviewCount;
  final int? experienceYears;
  final String? about;
  final List<String> skills;
  final List<String> serviceAreas;
  final String? matchReason;
}

typedef LoadBookingRecommendations =
    Future<List<RecommendedTechnician>> Function(String bookingId);

typedef SendTechnicianRequest =
    Future<void> Function(String bookingId, String technicianId);

class TechnicianUnavailableException implements Exception {
  const TechnicianUnavailableException([
    this.message = 'This technician is no longer available.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class RecommendedTechniciansPage extends StatefulWidget {
  const RecommendedTechniciansPage({
    super.key,
    required this.bookingId,
    required this.loadRecommendations,
    required this.sendRequest,
    this.bookingSummary,
    this.onRequestSent,
    this.onBackToBooking,
  });

  final String bookingId;
  final LoadBookingRecommendations loadRecommendations;
  final SendTechnicianRequest sendRequest;
  final String? bookingSummary;
  final ValueChanged<RecommendedTechnician>? onRequestSent;
  final VoidCallback? onBackToBooking;

  @override
  State<RecommendedTechniciansPage> createState() =>
      _RecommendedTechniciansPageState();
}

class _RecommendedTechniciansPageState
    extends State<RecommendedTechniciansPage> {
  static const _teal = Color(0xFF078795);
  static const _ink = Color(0xFF193841);

  bool _loading = true;
  bool _submitting = false;

  String? _error;
  String? _warning;

  List<RecommendedTechnician> _technicians = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _warning = null;
    });

    try {
      final result = await widget.loadRecommendations(widget.bookingId);

      if (!mounted) return;

      setState(() => _technicians = result);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = context.tr('bookingUi81');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showProfile(RecommendedTechnician technician) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('bookingUi64'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _identity(technician),

              if (technician.about?.isNotEmpty == true) ...[
                const SizedBox(height: 18),
                Text(
                  context.tr('bookingUi65'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(technician.about!),
              ],

              if (technician.skills.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  context.tr('bookingUi66'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 6,
                  children: technician.skills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
              ],

              if (technician.serviceAreas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr('bookingUi67'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(technician.serviceAreas.join(', ')),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _confirmSelection(technician);
                        },
                  child: Text(context.tr('bookingUi68')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSelection(RecommendedTechnician technician) async {
    if (_submitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('bookingUi69')),
        content: Text(
          '${technician.name}: ${context.tr('bookingUiRequestExplanation')}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: Text(context.tr('bookingUi70')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(context.tr('bookingUi71')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _warning = null;
    });

    try {
      await widget.sendRequest(widget.bookingId, technician.id);

      if (!mounted) return;

      if (widget.onRequestSent != null) {
        widget.onRequestSent!(technician);
      } else {
        Navigator.pop(context, technician);
      }
    } on TechnicianUnavailableException catch (error) {
      if (!mounted) return;

      setState(() {
        _warning = error.message;
      });

      await _reloadKeepingWarning();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('bookingUi82'))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _reloadKeepingWarning() async {
    final warning = _warning;

    await _reload();

    if (mounted) {
      setState(() => _warning = warning);
    }
  }

  Widget _identity(RecommendedTechnician technician) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE9F4F6),
          child: Icon(Icons.person, color: _teal),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                technician.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (technician.rating != null)
                Text(
                  '⭐ ${technician.rating!.toStringAsFixed(1)} · ${technician.reviewCount} ${context.tr('bookingUiReviewCount')}',
                ),

              if (technician.experienceYears != null)
                Text(
                  '${technician.experienceYears} ${context.tr('bookingUiExperience')}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _technicianCard(RecommendedTechnician technician) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _identity(technician),

            if (technician.skills.isNotEmpty) ...[
              const SizedBox(height: 10),

              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: technician.skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],

            if (technician.matchReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),

              Text(
                '✓ ${technician.matchReason}',
                style: const TextStyle(color: _teal, fontSize: 12),
              ),
            ],

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _showProfile(technician),
                    child: Text(context.tr('bookingUi72')),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => _confirmSelection(technician),
                    child: Text(context.tr('bookingUi68')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusView({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onAction,
    VoidCallback? secondaryAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: _teal),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            FilledButton(onPressed: onAction, child: Text(action)),

            if (secondaryAction != null)
              TextButton(
                onPressed: secondaryAction,
                child: Text(context.tr('bookingUi73')),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('bookingUi63'))),

      body: Stack(
        children: [
          if (_loading)
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  context.tr('bookingUi74'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(context.tr('bookingUi75')),
                const SizedBox(height: 20),
                for (var index = 0; index < 3; index++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFFE6F1F3),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 12,
                                      width: 125,
                                      color: const Color(0xFFE6ECEE),
                                    ),
                                    const SizedBox(height: 9),
                                    Container(
                                      height: 9,
                                      width: 85,
                                      color: const Color(0xFFE6ECEE),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(height: 10, color: const Color(0xFFE6ECEE)),
                          const SizedBox(height: 10),
                          Container(
                            height: 10,
                            width: 160,
                            color: const Color(0xFFE6ECEE),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6ECEE),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          else if (_error != null)
            _statusView(
              icon: Icons.error_outline,
              title: context.tr('bookingUi76'),
              message: _error!,
              action: context.tr('bookingUi52'),
              onAction: _reload,
            )
          else if (_technicians.isEmpty)
            _statusView(
              icon: Icons.search_off,
              title: context.tr('bookingUi77'),
              message: Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Chưa tìm thấy kỹ thuật viên phù hợp. Lịch đặt đã được lưu, bạn có thể chọn lại sau.'
                  : 'No suitable technician found. Your booking is saved; you can choose later.',
              action: context.tr('bookingUi79'),
              onAction: _reload,
              secondaryAction: widget.onBackToBooking ?? () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const MyBookingsPage()),
                );
              },
            )
          else
            RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    context.tr('bookingUi74'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(context.tr('bookingUi80')),

                  if (widget.bookingSummary?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),

                    Card(
                      color: const Color(0xFFEAF7F8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(widget.bookingSummary!),
                      ),
                    ),
                  ],

                  if (_warning != null) ...[
                    const SizedBox(height: 12),

                    Card(
                      color: const Color(0xFFFFF4DE),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_warning!),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  Text(
                    '${context.tr('bookingUiRecommended')}: ${_technicians.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  for (final technician in _technicians)
                    _technicianCard(technician),
                ],
              ),
            ),

          if (_submitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
