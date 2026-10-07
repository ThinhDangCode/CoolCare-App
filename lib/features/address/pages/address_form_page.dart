import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../controllers/address_controller.dart';
import '../models/address_model.dart';
import '../models/location_model.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    required this.controller,
    this.address,
    super.key,
  });

  final AddressController controller;
  final AddressModel? address;

  bool get isEditing => address != null;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  static const Color _primary = Color(0xFF078B96);
  static const Color _text = Color(0xFF17333A);
  static const Color _muted = Color(0xFF718087);
  static const Color _border = Color(0xFFE1E8EA);
  static const Color _error = Color(0xFFD92D20);

  final _formKey = GlobalKey<FormState>();
  final Geocoding _geocoding = Geocoding();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailController;

  ProvinceModel? _selectedProvince;
  WardModel? _selectedWard;

  double? _latitude;
  double? _longitude;

  bool _isDefault = false;
  bool _initializing = true;
  bool _hasChanges = false;
  bool _isGettingLocation = false;

  String? _formError;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    _nameController = TextEditingController(
      text: address?.recipientName ?? '',
    );

    _phoneController = TextEditingController(
      text: address?.phone ?? '',
    );

    _detailController = TextEditingController(
      text: address?.addressLine ?? '',
    );

    _latitude = address?.latitude;
    _longitude = address?.longitude;
    _isDefault = address?.isDefault ?? false;

    widget.controller.addListener(_refresh);

    _nameController.addListener(_changed);
    _phoneController.addListener(_changed);
    _detailController.addListener(_changed);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    await widget.controller.loadProvinces();

    if (!mounted) return;

    final address = widget.address;

    if (address != null) {
      final province = _findProvince(address.city);

      if (province != null) {
        _selectedProvince = province;

        await widget.controller.loadWards(province.code);

        if (!mounted) return;

        _selectedWard = _findWard(address.ward);
      }
    }

    if (!mounted) return;

    setState(() {
      _initializing = false;
      _hasChanges = false;
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _changed() {
    if (_initializing) return;

    if (!_hasChanges && mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGettingLocation = true;
      _formError = null;
    });

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showLocationError(
          'Please enable location services and try again.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationError(
          'Location permission is required to use your current location.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Location permission is permanently denied. Please enable it in your device settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks =
      await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isEmpty) {
        _showLocationError(
          'Unable to determine your address. Please enter it manually.',
        );
        return;
      }

      final placemark = placemarks.first;

      await _applyPlacemark(placemark);

      if (!mounted) return;

      setState(() {
        _hasChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location updated successfully.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      _showLocationError(
        'Unable to get your current location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _applyPlacemark(Placemark placemark) async {
    final provinceCandidates = [
      placemark.administrativeArea,
      placemark.locality,
    ];

    ProvinceModel? province;

    for (final candidate in provinceCandidates) {
      province = _findProvince(candidate);

      if (province != null) {
        break;
      }
    }

    if (province != null) {
      setState(() {
        _selectedProvince = province;
        _selectedWard = null;
      });

      await widget.controller.loadWards(province.code);

      if (!mounted) return;

      final wardCandidates = [
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
      ];

      WardModel? ward;

      for (final candidate in wardCandidates) {
        ward = _findWard(candidate);

        if (ward != null) {
          break;
        }
      }

      setState(() {
        _selectedWard = ward;
      });
    }

    final detailedAddress =
    _buildDetailedAddress(placemark);

    if (detailedAddress.isNotEmpty) {
      _detailController.text = detailedAddress;
    }
  }

  String _buildDetailedAddress(Placemark placemark) {
    final parts = <String>[];

    void add(String? value) {
      final text = value?.trim() ?? '';

      if (text.isEmpty) return;

      final normalized = _normalizeLocationName(text);

      final provinceName = _selectedProvince == null
          ? ''
          : _normalizeLocationName(
        _selectedProvince!.name,
      );

      final wardName = _selectedWard == null
          ? ''
          : _normalizeLocationName(
        _selectedWard!.name,
      );

      if (normalized == provinceName ||
          normalized == wardName) {
        return;
      }

      if (!parts.any(
            (item) =>
        _normalizeLocationName(item) == normalized,
      )) {
        parts.add(text);
      }
    }

    add(placemark.subThoroughfare);
    add(placemark.thoroughfare);

    if (parts.isEmpty) {
      add(placemark.street);
    }

    if (parts.isEmpty) {
      add(placemark.name);
    }

    return parts.join(', ');
  }

  void _showLocationError(String message) {
    if (!mounted) return;

    setState(() {
      _formError = message;
    });
  }

  // ============================================================
  // LOCATION MATCHING
  // ============================================================

  ProvinceModel? _findProvince(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final target = _normalizeLocationName(value);

    if (target.isEmpty) return null;

    for (final province in widget.controller.provinces) {
      final current =
      _normalizeLocationName(province.name);

      if (current == target) {
        return province;
      }
    }

    for (final province in widget.controller.provinces) {
      final current =
      _normalizeLocationName(province.name);

      if (current.isNotEmpty &&
          (current.contains(target) ||
              target.contains(current))) {
        return province;
      }
    }

    return null;
  }

  WardModel? _findWard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final target = _normalizeLocationName(value);

    if (target.isEmpty) return null;

    for (final ward in widget.controller.wards) {
      final current = _normalizeLocationName(ward.name);

      if (current == target) {
        return ward;
      }
    }

    for (final ward in widget.controller.wards) {
      final current = _normalizeLocationName(ward.name);

      if (current.isNotEmpty &&
          (current.contains(target) ||
              target.contains(current))) {
        return ward;
      }
    }

    return null;
  }

  String _normalizeLocationName(String value) {
    var text = value.trim().toLowerCase();

    text = _removeVietnameseDiacritics(text);

    text = text
        .replaceAll('province', ' ')
        .replaceAll('municipality', ' ')
        .replaceAll('city', ' ')
        .replaceAll('ward', ' ')
        .replaceAll('commune', ' ')
        .replaceAll('township', ' ');

    const prefixes = [
      'thanh pho ',
      'tinh ',
      'phuong ',
      'xa ',
      'thi tran ',
    ];

    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length);
        break;
      }
    }

    text = text.replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );

    text = text.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return text.trim();
  }

  String _removeVietnameseDiacritics(String value) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵ'
        'èéẹẻẽêềếệểễ'
        'ìíịỉĩ'
        'òóọỏõôồốộổỗơờớợởỡ'
        'ùúụủũưừứựửữ'
        'ỳýỵỷỹ'
        'đ';

    const replacement =
        'aaaaaaaaaaaaaaaaa'
        'eeeeeeeeeee'
        'iiiii'
        'ooooooooooooooooo'
        'uuuuuuuuuuu'
        'yyyyy'
        'd';

    var result = value;

    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(
        source[i],
        replacement[i],
      );
    }

    return result;
  }

  // ============================================================
  // PROVINCE / WARD
  // ============================================================

  Future<void> _changeProvince(
      ProvinceModel? province,
      ) async {
    if (province == null) return;

    setState(() {
      _selectedProvince = province;
      _selectedWard = null;
      _hasChanges = true;
      _formError = null;

      // Địa chỉ đã bị thay đổi thủ công.
      // Tọa độ GPS cũ không còn đảm bảo chính xác.
      _latitude = null;
      _longitude = null;
    });

    await widget.controller.loadWards(province.code);

    if (!mounted) return;

    setState(() {});
  }

  void _changeWard(WardModel? ward) {
    setState(() {
      _selectedWard = ward;
      _hasChanges = true;
      _formError = null;

      _latitude = null;
      _longitude = null;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _formError = null;
    });

    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    if (_selectedProvince == null) {
      setState(() {
        _formError =
        'Please select your province/city.';
      });
      return;
    }

    if (_selectedWard == null) {
      setState(() {
        _formError =
        'Please select your ward/commune.';
      });
      return;
    }

    bool success;

    if (widget.isEditing) {
      success = await widget.controller.updateAddress(
        addressId: widget.address!.id,
        recipientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _selectedProvince!.name,
        ward: _selectedWard!.name,
        addressLine: _detailController.text.trim(),
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
      );
    } else {
      success = await widget.controller.createAddress(
        recipientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _selectedProvince!.name,
        ward: _selectedWard!.name,
        addressLine: _detailController.text.trim(),
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
      );
    }

    if (!mounted) return;

    if (success) {
      _hasChanges = false;
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _formError =
          widget.controller.formErrorMessage ??
              'Unable to save address. Please try again.';
    });
  }

  // ============================================================
  // BACK / UNSAVED
  // ============================================================

  Future<void> _back() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF79009),
                    size: 23,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Discard unsaved changes?',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You have unsaved changes. Are you sure you want to leave?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text,
                          side: const BorderSide(
                            color: _border,
                          ),
                        ),
                        child: const Text(
                          'Keep Editing',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Full name is required';
    }

    if (text.length > 100) {
      return 'Maximum 100 characters';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^0[0-9]{9}$').hasMatch(text)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? _validateDetail(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Detailed address is required';
    }

    if (text.length > 255) {
      return 'Maximum 255 characters';
    }

    return null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);

    _nameController.removeListener(_changed);
    _phoneController.removeListener(_changed);
    _detailController.removeListener(_changed);

    _nameController.dispose();
    _phoneController.dispose();
    _detailController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(
              Icons.arrow_back,
              color: _text,
              size: 20,
            ),
          ),
          titleSpacing: 0,
          title: Text(
            widget.isEditing
                ? 'Edit Address'
                : 'Add New Address',
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _initializing
            ? const Center(
          child: CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2,
          ),
        )
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              28,
            ),
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,
            children: [
              if (_formError != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 18),
              ],

              _sectionTitle(
                'CONTACT INFORMATION',
              ),
              const SizedBox(height: 12),

              _label('Full Name *'),
              TextFormField(
                controller: _nameController,
                validator: _validateName,
                textInputAction:
                TextInputAction.next,
                style: const TextStyle(
                  color: _text,
                  fontSize: 11,
                ),
                decoration: _inputDecoration(
                  'Enter full name',
                ),
              ),

              const SizedBox(height: 14),

              _label('Phone Number *'),
              TextFormField(
                controller: _phoneController,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                textInputAction:
                TextInputAction.next,
                style: const TextStyle(
                  color: _text,
                  fontSize: 11,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                  LengthLimitingTextInputFormatter(
                    10,
                  ),
                ],
                decoration: _inputDecoration(
                  'Enter phone number',
                ),
              ),

              const SizedBox(height: 25),

              _sectionTitle('ADDRESS'),
              const SizedBox(height: 12),

              _buildCurrentLocationButton(),

              const SizedBox(height: 18),

              _label('Province / City *'),
              DropdownButtonFormField<
                  ProvinceModel>(
                value: _selectedProvince,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _muted,
                  size: 18,
                ),
                decoration: _inputDecoration(
                  'Select province/city',
                ),
                items: widget.controller.provinces
                    .map(
                      (province) =>
                      DropdownMenuItem<
                          ProvinceModel>(
                        value: province,
                        child: Text(
                          province.name,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 11,
                          ),
                        ),
                      ),
                )
                    .toList(),
                onChanged: _changeProvince,
                validator: (_) {
                  if (_selectedProvince == null) {
                    return 'Province/city is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _label('Ward / Commune *'),
              DropdownButtonFormField<WardModel>(
                value: _selectedWard,
                isExpanded: true,
                icon:
                widget.controller.isLoadingWards
                    ? const SizedBox(
                  width: 15,
                  height: 15,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: _primary,
                  ),
                )
                    : const Icon(
                  Icons
                      .keyboard_arrow_down,
                  color: _muted,
                  size: 18,
                ),
                decoration: _inputDecoration(
                  _selectedProvince == null
                      ? 'Select province/city first'
                      : widget.controller
                      .isLoadingWards
                      ? 'Loading wards...'
                      : 'Select ward/commune',
                ),
                items: widget.controller.wards
                    .map(
                      (ward) =>
                      DropdownMenuItem<
                          WardModel>(
                        value: ward,
                        child: Text(
                          ward.name,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 11,
                          ),
                        ),
                      ),
                )
                    .toList(),
                onChanged:
                _selectedProvince == null ||
                    widget.controller
                        .isLoadingWards
                    ? null
                    : _changeWard,
                validator: (_) {
                  if (_selectedWard == null) {
                    return 'Ward/commune is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _label('Detailed Address *'),
              TextFormField(
                controller: _detailController,
                validator: _validateDetail,
                maxLines: 2,
                maxLength: 255,
                style: const TextStyle(
                  color: _text,
                  fontSize: 11,
                ),
                decoration: _inputDecoration(
                  'House number, street, building...',
                ).copyWith(
                  counterText: '',
                ),
              ),

              const SizedBox(height: 18),

              _buildDefaultAddressSwitch(),

              const SizedBox(height: 24),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Widget _buildCurrentLocationButton() {
    return InkWell(
      onTap:
      _isGettingLocation ? null : _useCurrentLocation,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: double.infinity,
        height: 38,
        padding:
        const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F7),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            if (_isGettingLocation)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.7,
                  color: _primary,
                ),
              )
            else
              const Icon(
                Icons.my_location,
                color: _primary,
                size: 15,
              ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _isGettingLocation
                    ? 'Getting your location...'
                    : 'Use Current Location',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFF5B7B1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: _error,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formError!,
              style: const TextStyle(
                color: _error,
                fontSize: 9.5,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _formError = null;
              });
            },
            child: const Icon(
              Icons.close,
              color: _error,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEFAULT
  // ============================================================

  Widget _buildDefaultAddressSwitch() {
    final currentDefault =
        widget.isEditing && widget.address!.isDefault;

    return Material(
      color: const Color(0xFFF4FAFA),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFDCEBEC),
          ),
        ),
        child: SwitchListTile(
          dense: true,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 11,
          ),
          activeTrackColor: _primary,
          title: const Text(
            'Set as default address',
            style: TextStyle(
              color: _text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            currentDefault
                ? 'This is your current default address.'
                : 'Use this address as the default for new bookings.',
            style: const TextStyle(
              color: _muted,
              fontSize: 8.5,
            ),
          ),
          value: _isDefault,
          onChanged: currentDefault
              ? null
              : (value) {
            setState(() {
              _isDefault = value;
              _hasChanges = true;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed:
        widget.controller.isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          const Color(0xFFB8CCCF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: widget.controller.isSaving
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          widget.isEditing
              ? 'Save Changes'
              : 'Save Address',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _text,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF98A6A9),
        fontSize: 10.5,
      ),
      errorStyle: const TextStyle(
        color: _error,
        fontSize: 8.5,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _error,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}