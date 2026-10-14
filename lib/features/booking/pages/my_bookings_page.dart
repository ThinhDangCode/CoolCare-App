import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../reviews/pages/review_pages.dart';
import '../models/my_booking.dart';
import '../repositories/my_bookings_repository.dart';
import 'booking_detail_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final _repository = MyBookingsRepository();
  late Future<List<MyBooking>> _bookings;
  bool _showReviews = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _bookings = _repository.getMyBookings();
  }

  void _reload() {
    final next = _repository.getMyBookings();
    if (!mounted) return;
    setState(() { _bookings = next; });
  }

  Future<void> _refresh() async {
    final next = _repository.getMyBookings();
    if (!mounted) return;
    setState(() { _bookings = next; });
    try { await next; } catch (_) { /* FutureBuilder shows the error. */ }
  }

  Future<void> _open(MyBooking booking) async {
    await Navigator.of(context).push(MaterialPageRoute<bool>(
      builder: (_) => BookingDetailPage(bookingId: booking.id),
    ));
    if (mounted) _reload();
  }

  bool _matches(MyBooking booking) {
    if (_filter == 'all') return true;
    if (_filter == 'done') return booking.status == 'COMPLETED';
    if (_filter == 'cancelled') return booking.status == 'CANCELLED';
    return booking.status != 'COMPLETED' && booking.status != 'CANCELLED';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(children: [
          Expanded(child: Text(context.tr('bookingUi57'),
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: context.appText))),
          TextButton(
            onPressed: () => setState(() { _showReviews = !_showReviews; }),
            child: Text(_showReviews ? context.tr('bookingUi58') : context.tr('bookingUi59')),
          ),
        ]),
      ),
      if (!_showReviews)
        SizedBox(height: 42, child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          children: [
            _chip('all', context.tr('bookingFilterAll')),
            _chip('active', context.tr('bookingFilterActive')),
            _chip('done', context.tr('bookingFilterDone')),
            _chip('cancelled', context.tr('bookingFilterCancelled')),
          ],
        )),
      Expanded(child: _showReviews
        ? const CustomerActivityPage()
        : RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<MyBooking>>(
              future: _bookings,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    const SizedBox(height: 90),
                    Center(child: Text(context.tr('bookingUiLoadError'))),
                    Center(child: TextButton(onPressed: _reload, child: Text(context.tr('bookingUi60')))),
                  ]);
                }
                final items = (snapshot.data ?? <MyBooking>[]).where(_matches).toList();
                if (items.isEmpty) {
                  return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    const SizedBox(height: 95),
                    const Icon(Icons.event_note_outlined, size: 42, color: Color(0xFF8AA0A6)),
                    const SizedBox(height: 12),
                    Center(child: Text(context.tr('bookingUi61'))),
                  ]);
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  itemCount: items.length,
                  itemBuilder: (_, index) => _BookingCard(booking: items[index], onTap: () => _open(items[index])),
                );
              },
            ),
          )),
    ]);
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF61757B))),
        selected: selected,
        showCheckmark: false,
        selectedColor: const Color(0xFF078B96),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: selected ? const Color(0xFF078B96) : const Color(0xFFDDE6E8)),
        onSelected: (_) => setState(() { _filter = value; }),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});
  final MyBooking booking;
  final VoidCallback onTap;
  static const teal = Color(0xFF078B96);

  String _date(DateTime? input) {
    if (input == null) return '—';
    final d = input.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }

  String _money(num? value) {
    if (value == null) return '—';
    final formatted = value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '$formatted đ';
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final warning = status == 'PENDING' || status == 'TECHNICIAN_SELECTED';
    final cancelled = status == 'CANCELLED';
    final color = cancelled ? const Color(0xFFB42318) : warning ? const Color(0xFF946500) : teal;
    final background = cancelled ? const Color(0xFFFEECEB) : warning ? const Color(0xFFFFF4D8) : const Color(0xFFE8F7F5);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE1E8EA))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(booking.code, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
                child: Text(context.tr('bookingStatus_$status'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 12),
            _line(Icons.calendar_today_outlined, _date(booking.scheduledAt)),
            const SizedBox(height: 7),
            _line(Icons.ac_unit, '${booking.unitCount} ${context.tr('bookingUiUnits')} · ${booking.serviceCount} ${context.tr('bookingUiServices')}'),
            if (booking.technicianName?.isNotEmpty == true) ...[
              const SizedBox(height: 7),
              _line(Icons.engineering_outlined, booking.technicianName!),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text(_money(booking.totalAmount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: teal))),
              Text(context.tr('bookingDetailView'), style: const TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 17, color: teal),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(children: [
    Icon(icon, size: 15, color: teal),
    const SizedBox(width: 9),
    Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Color(0xFF61757B)))),
  ]);
}
