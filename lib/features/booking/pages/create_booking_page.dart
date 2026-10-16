import '../../../app/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../controllers/booking_controller.dart';
import '../services/technician_matching_api_service.dart';
import 'recommended_technicians_page.dart';

class CreateBookingPage extends StatefulWidget {
  const CreateBookingPage({
    super.key,
    this.onBookingCreated,
    this.initialServiceId,
    this.rebookData,
  });

  final ValueChanged<Map<String, dynamic>>? onBookingCreated;
  final String? initialServiceId;
  final Map<String, dynamic>? rebookData;

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  static const Color primary = Color(0xFF078B96);

  late final BookingController controller;

  int currentStep = 0;

  @override
  void initState() {
    super.initState();

    controller = BookingController(apiClient: ApiClient.fromEnvironment());

    controller.addListener(_refresh);
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    await controller.loadInitialData();
    if (!mounted) return;

    final rebookData = widget.rebookData;
    if (rebookData != null) {
      await controller.prefillFromBooking(rebookData);
      return;
    }

    final serviceId = widget.initialServiceId;
    if (serviceId == null || serviceId.isEmpty) return;

    final isAvailable = controller.services.any(
      (service) => service['id']?.toString() == serviceId,
    );
    if (isAvailable && !controller.units.first.serviceIds.contains(serviceId)) {
      controller.toggleService(0, serviceId);
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _continue() {
    if (currentStep == 0) {
      for (final unit in controller.units) {
        if (unit.serviceIds.isEmpty) {
          _showMessage(context.tr('bookingUi53'));
          return;
        }
      }
    }

    if (currentStep == 1) {
      final error = controller.validateBooking();

      if (error != null) {
        _showMessage(_localizedBookingMessage(error));
        return;
      }
    }

    if (currentStep < 2) {
      setState(() => currentStep++);
    }
  }

  void _back() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submitBooking() async {
    final success = await controller.createBooking();

    if (!mounted) return;

    if (!success) {
      _showMessage(
        controller.formErrorMessage == null
            ? context.tr('bookingUi54')
            : _localizedBookingMessage(controller.formErrorMessage!),
      );
      return;
    }

    final booking = controller.createdBooking;

    if (booking == null) {
      _showMessage(context.tr('bookingUi55'));
      return;
    }

    final bookingId = booking['id']?.toString();

    if (bookingId == null || bookingId.isEmpty) {
      _showMessage(context.tr('bookingUi56'));
      return;
    }

    final matchingService = TechnicianMatchingApiService();

    final selectedTechnician = await Navigator.of(context)
        .push<RecommendedTechnician>(
          MaterialPageRoute<RecommendedTechnician>(
            builder: (_) => RecommendedTechniciansPage(
              bookingId: bookingId,
              loadRecommendations: matchingService.getRecommendedTechnicians,
              sendRequest: matchingService.selectTechnician,
            ),
          ),
        );

    if (!mounted) return;
    if (selectedTechnician == null) {
      // The customer returned without sending a technician request.
      // Keep the booking page open; do not report completion.
      return;
    }

    // A successful selection completes the booking flow.
    // HomePage is the first route of the customer app.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _localizedBookingMessage(String message) {
    final separator = message.indexOf(':');
    if (separator < 0) return context.tr(message);
    final key = message.substring(0, separator);
    final index = message.substring(separator + 1);
    return context.trArgs(key, {'index': index});
  }

  // ------------------------------------------------------------
  // COMMON WIDGETS
  // ------------------------------------------------------------

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: context.appText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.appMuted,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String label, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: context.appText,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 5),
            Text(
              context.tr('bookingUi0'),
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: context.appMuted),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary),
      ),
    );
  }

  Widget _progressIndicator() {
    final labels = [
      context.tr('bookingUi1'),
      context.tr('bookingUi2'),
      context.tr('bookingUi3'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final completed = index < currentStep;
          final selected = index == currentStep;
          final active = completed || selected;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? primary : context.appBorder,
                  ),
                  alignment: Alignment.center,
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: selected ? Colors.white : context.appMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? primary : context.appMuted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (index < labels.length - 1) const SizedBox(width: 5),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUnitsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context.tr('bookingUi4'),
          subtitle: context.tr('bookingUi5'),
        ),
        const SizedBox(height: 16),

        for (var index = 0; index < controller.units.length; index++) ...[
          _buildAcUnit(index),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.addUnit,
            icon: const Icon(Icons.add, size: 17),
            label: Text(context.tr('bookingUi6')),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
            ),
          ),
        ),

        const SizedBox(height: 14),
        _infoBox(context.tr('bookingUi7')),
      ],
    );
  }

  Widget _buildAcUnit(int index) {
    final unit = controller.units[index];

    final availableModels = unit.acBrandId == null
        ? <Map<String, dynamic>>[]
        : controller.modelsByBrand[unit.acBrandId!] ?? <Map<String, dynamic>>[];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ac_unit, size: 20, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('bookingUiAcUnit')} ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
              ),
              if (controller.units.length > 1)
                IconButton(
                  onPressed: () => _confirmRemoveUnit(index),
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),

          const SizedBox(height: 14),
          _fieldLabel(context.tr('bookingUi8'), optional: true),

          DropdownButtonFormField<String>(
            key: ValueKey('brand-$index-${unit.acBrandId}'),
            initialValue: unit.acBrandId,
            decoration: _inputDecoration(context.tr('bookingUi9')),
            items: controller.brands.map((brand) {
              return DropdownMenuItem<String>(
                value: brand['id'].toString(),
                child: Text(brand['name']?.toString() ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              controller.selectBrand(index, value);
            },
          ),

          const SizedBox(height: 14),
          _fieldLabel(context.tr('bookingUi10'), optional: true),

          DropdownButtonFormField<String>(
            key: ValueKey('model-$index-${unit.acBrandId}'),
            initialValue: unit.acModelId,
            decoration: _inputDecoration(context.tr('bookingUi11')),
            items: availableModels.map((model) {
              return DropdownMenuItem<String>(
                value: model['id'].toString(),
                child: Text(model['model_name']?.toString() ?? ''),
              );
            }).toList(),
            onChanged: unit.acBrandId == null
                ? null
                : (value) => controller.selectModel(index, value),
          ),

          if (controller.isLoadingModels)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),

          const Divider(height: 30),

          _fieldLabel(context.tr('bookingUi12')),

          if (unit.serviceIds.isEmpty)
            Text(
              context.tr('bookingUi13'),
              style: TextStyle(color: context.appMuted, fontSize: 12),
            ),

          for (final serviceId in unit.serviceIds)
            _selectedServiceTile(serviceId),

          TextButton.icon(
            onPressed: () => _openServiceSelector(index),
            icon: const Icon(Icons.add, size: 15),
            label: Text(context.tr('bookingUi14')),
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: EdgeInsets.zero,
            ),
          ),

          const Divider(height: 24),

          _fieldLabel(context.tr('bookingUi15'), optional: true),

          TextFormField(
            initialValue: unit.description,
            maxLines: 3,
            maxLength: 2000,
            decoration: _inputDecoration(context.tr('bookingUi16')),
            onChanged: (value) {
              controller.setUnitDescription(index, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _selectedServiceTile(String serviceId) {
    final matches = controller.services.where(
      (service) => service['id']?.toString() == serviceId,
    );

    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    final service = matches.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit, size: 17, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service['name']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _formatPrice(service['base_price']),
            style: const TextStyle(fontSize: 11, color: primary),
          ),
        ],
      ),
    );
  }

  Future<void> _openServiceSelector(int unitIndex) async {
    final selected = Set<String>.from(controller.units[unitIndex].serviceIds);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('bookingUiServiceForUnit')} ${unitIndex + 1}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: controller.services.map((service) {
                          final id = service['id'].toString();

                          return CheckboxListTile(
                            value: selected.contains(id),
                            activeColor: primary,
                            title: Text(service['name']?.toString() ?? ''),
                            subtitle: Text(
                              '${context.tr('bookingUiFrom')} ${_formatPrice(service['base_price'])}',
                            ),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext, true);
                        },
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        child: Text(context.tr('bookingUi17')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final current = List<String>.from(controller.units[unitIndex].serviceIds);

    for (final id in current) {
      if (!selected.contains(id)) {
        controller.toggleService(unitIndex, id);
      }
    }

    for (final id in selected) {
      if (!current.contains(id)) {
        controller.toggleService(unitIndex, id);
      }
    }
  }

  Future<void> _confirmRemoveUnit(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('bookingUi18')),
          content: Text(context.tr('bookingUi19')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('bookingUi20')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(context.tr('bookingUi21')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      controller.removeUnit(index);
    }
  }

  // ------------------------------------------------------------
  // STEP 2 - ADDRESS AND SCHEDULE
  // ------------------------------------------------------------

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context.tr('bookingUi22'),
          subtitle: context.tr('bookingUi23'),
        ),
        const SizedBox(height: 20),

        _fieldLabel(context.tr('bookingUi24')),
        _card(
          child: InkWell(
            onTap: _openAddressSelector,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAddressText(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  context.tr('bookingUi25'),
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        _fieldLabel(context.tr('bookingUi26')),

        _fieldLabel(context.tr('bookingUi27')),
        TextFormField(
          key: ValueKey('name-${controller.customerAddressId}'),
          initialValue: controller.recipientName,
          decoration: _inputDecoration(context.tr('bookingUi28')),
          onChanged: controller.setRecipientName,
        ),

        const SizedBox(height: 14),
        _fieldLabel(context.tr('bookingUi29')),
        TextFormField(
          key: ValueKey('phone-${controller.customerAddressId}'),
          initialValue: controller.recipientPhone,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(context.tr('bookingUi30')),
          onChanged: controller.setRecipientPhone,
        ),

        const SizedBox(height: 6),
        Text(
          context.tr('bookingUi31'),
          style: TextStyle(color: context.appMuted, fontSize: 11),
        ),

        const SizedBox(height: 24),
        _fieldLabel(context.tr('bookingUi32')),

        _card(
          child: InkWell(
            onTap: _selectDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: primary),
                const SizedBox(width: 10),
                Text(
                  controller.scheduledAt == null
                      ? context.tr('bookingUi33')
                      : _formatDate(controller.scheduledAt!),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        _fieldLabel(context.tr('bookingUi34')),

        _card(
          child: InkWell(
            onTap: _selectTime,
            child: Row(
              children: [
                const Icon(Icons.access_time, color: primary),
                const SizedBox(width: 10),
                Text(
                  controller.scheduledAt == null
                      ? context.tr('bookingUi35')
                      : _formatTime(controller.scheduledAt!),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        _infoBox(context.tr('bookingUi36')),
      ],
    );
  }

  String _selectedAddressText() {
    for (final address in controller.addresses) {
      if (address['id']?.toString() == controller.customerAddressId) {
        return [
          address['address_line'],
          address['ward'],
          address['city'],
        ].where((part) => part != null && '$part'.isNotEmpty).join(', ');
      }
    }

    return context.tr('bookingUi37');
  }

  Future<void> _openAddressSelector() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('bookingUi38'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (controller.addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.tr('bookingUi39')),
                  ),
                RadioGroup<String>(
                  groupValue: controller.customerAddressId,
                  onChanged: (value) {
                    if (value == null) return;

                    final address = controller.addresses.firstWhere(
                      (item) => item['id'].toString() == value,
                    );
                    Navigator.pop(sheetContext, address);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: controller.addresses.map((address) {
                      return RadioListTile<String>(
                        value: address['id'].toString(),
                        title: Text(
                          address['recipient_name']?.toString() ?? '',
                        ),
                        subtitle: Text(
                          [
                            address['address_line'],
                            address['ward'],
                            address['city'],
                          ].where((value) => value != null).join(', '),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      controller.selectAddress(selected);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: controller.scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected == null) return;

    final previous = controller.scheduledAt;

    controller.selectSchedule(
      DateTime(
        selected.year,
        selected.month,
        selected.day,
        previous?.hour ?? 9,
        previous?.minute ?? 0,
      ),
    );
  }

  Future<void> _selectTime() async {
    final previous = controller.scheduledAt;
    final now = DateTime.now();

    int selectedHour = previous?.hour ?? 9;
    int selectedMinute = previous?.minute ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                context.tr('bookingUi34'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.6,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: selectedHour,
                        ),
                        onSelectedItemChanged: (index) {
                          setDialogState(() {
                            selectedHour = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, index) {
                            final selected = index == selectedHour;

                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? context.appAccentSurface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: selected ? 25 : 16,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? (context.isDarkMode
                                            ? const Color(0xFF8FE1E5)
                                            : primary)
                                      : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.6,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: selectedMinute,
                        ),
                        onSelectedItemChanged: (index) {
                          setDialogState(() {
                            selectedMinute = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            final selected = index == selectedMinute;

                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? context.appAccentSurface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: selected ? 25 : 16,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? (context.isDarkMode
                                            ? const Color(0xFF8FE1E5)
                                            : primary)
                                      : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF078B96),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final date = previous ?? now;

    controller.selectSchedule(
      DateTime(date.year, date.month, date.day, selectedHour, selectedMinute),
    );
  }

  // ------------------------------------------------------------
  // STEP 3 - REVIEW
  // ------------------------------------------------------------

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context.tr('bookingUi40'),
          subtitle: context.tr('bookingUi41'),
        ),
        const SizedBox(height: 18),

        _reviewHeader(context.tr('bookingUi42')),

        for (var index = 0; index < controller.units.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr('bookingUiUnit')} ${index + 1}',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final id in controller.units[index].serviceIds)
                    _selectedServiceTile(id),
                  if (controller.units[index].description.isNotEmpty)
                    Text(
                      controller.units[index].description,
                      style: TextStyle(color: context.appMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        _reviewHeader(context.tr('bookingUi24')),
        _card(child: Text(_selectedAddressText())),

        const SizedBox(height: 18),

        _reviewHeader(context.tr('bookingUi43')),
        _card(
          child: Text(
            controller.scheduledAt == null
                ? context.tr('bookingUi44')
                : '${_formatDate(controller.scheduledAt!)} '
                      '- ${_formatTime(controller.scheduledAt!)}',
          ),
        ),

        const SizedBox(height: 18),

        _sectionTitle(context.tr('bookingUi45')),
        const SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              for (var index = 0; index < controller.units.length; index++)
                for (final id in controller.units[index].serviceIds)
                  _priceRow(index, id),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('bookingUi46'),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _formatPrice(_estimatedTotal()),
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _infoBox(context.tr('bookingUi47')),
      ],
    );
  }

  Widget _reviewHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: context.appText),
      ),
    );
  }

  Widget _priceRow(int unitIndex, String serviceId) {
    final matches = controller.services.where(
      (service) => service['id']?.toString() == serviceId,
    );

    if (matches.isEmpty) return const SizedBox.shrink();

    final service = matches.first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${service['name']} ${context.tr('bookingUiUnit')} ${unitIndex + 1}",
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            _formatPrice(service['base_price']),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  double _estimatedTotal() {
    var total = 0.0;

    for (final unit in controller.units) {
      for (final id in unit.serviceIds) {
        for (final service in controller.services) {
          if (service['id']?.toString() == id) {
            total += double.tryParse('${service['base_price'] ?? 0}') ?? 0;
            break;
          }
        }
      }
    }

    return total;
  }

  String _formatPrice(dynamic value) {
    final number = double.tryParse('$value') ?? 0;
    final rounded = number.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(rounded[i]);
    }

    return '${buffer.toString()}đ';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _infoBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: primary, fontSize: 11, height: 1.5),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.units.length} ${context.tr('bookingUiUnits')} - '
                    '${controller.units.fold<int>(0, (total, unit) => total + unit.serviceIds.length)} services',
                    style: TextStyle(fontSize: 10, color: context.appMuted),
                  ),
                  Text(
                    '${context.tr('bookingUiFrom')} ${_formatPrice(_estimatedTotal())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: controller.isSaving
                  ? null
                  : currentStep == 2
                  ? _submitBooking
                  : _continue,
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: controller.isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      currentStep == 2
                          ? context.tr('bookingUi49')
                          : context.tr('bookingUi50'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(context.tr('bookingUi51')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null &&
                controller.brands.isEmpty &&
                controller.services.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 44, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(controller.errorMessage!),
                  TextButton(
                    onPressed: controller.loadInitialData,
                    child: Text(context.tr('bookingUi52')),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _progressIndicator(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (currentStep == 0) _buildUnitsStep(),
                      if (currentStep == 1) _buildAddressStep(),
                      if (currentStep == 2) _buildReviewStep(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: controller.isLoading ? null : _bottomBar(),
    );
  }
}
