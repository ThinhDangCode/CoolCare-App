import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../controllers/address_controller.dart';
import '../models/address_model.dart';
import '../widgets/address_card.dart';
import 'address_form_page.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const Color _primary = Color(0xFF078B96);
  static const Color _text = Color(0xFF17333A);
  static const Color _muted = Color(0xFF718087);
  static const Color _border = Color(0xFFE1E8EA);
  static const Color _danger = Color(0xFFEA1D25);

  late final AddressController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AddressController(apiClient: ApiClient.fromEnvironment());

    _controller.addListener(_refresh);
    _controller.loadAddresses();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _openAddAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(controller: _controller),
      ),
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _openEditAddress(AddressModel address) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddressFormPage(controller: _controller, address: address),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TITLE
                const Text(
                  'Delete this address?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // DEFAULT WARNING
                if (address.isDefault) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B),
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'This is your default address',
                            style: TextStyle(
                              color: Color(0xFF9A6700),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ADDRESS PREVIEW
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FAFA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: _primary,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          address.fullAddress,
                          style: const TextStyle(
                            color: Color(0xFF455B61),
                            fontSize: 9,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // DESCRIPTION
                Text(
                  address.isDefault
                      ? 'This address will be removed from your list. Another address will automatically become your default address.'
                      : 'This address will be removed from your saved list. The existing bookings remain unchanged.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),

                // KEEP
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.onSurface,
                      backgroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.surface,
                      side: BorderSide(
                        color: Theme.of(dialogContext).dividerColor,
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Keep',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // DELETE
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Delete Address',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final wasDefault = address.isDefault;

    final success = await _controller.deleteAddress(address.id);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        wasDefault
            ? 'Address deleted. Your default address has been updated.'
            : 'Address deleted successfully.',
      );
    } else {
      _showMessage(
        _controller.errorMessage ??
            'Unable to delete address. Please try again.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SET DEFAULT
  // ============================================================

  Future<void> _setDefault(AddressModel address) async {
    final success = await _controller.setDefaultAddress(address.id);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('Default address updated.');
    } else {
      _showMessage(
        _controller.errorMessage ?? 'Unable to update default address.',
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: isError ? _danger : _text,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('myAddresses'),
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              context.tr('manageAddresses'),
              style: TextStyle(
                color: context.appMuted,
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

      body: _buildBody(),

      bottomNavigationBar: _controller.addresses.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: context.appSurface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openAddAddress,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      context.tr('addNewAddress'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isLoading) {
      return _buildLoading();
    }

    if (_controller.errorMessage != null) {
      return _buildError();
    }

    if (_controller.addresses.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _controller.loadAddresses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Text(
            context.tr('yourAddresses'),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),

          const SizedBox(height: 10),

          ..._controller.addresses.map(
            (address) => AddressCard(
              address: address,
              onEdit: () {
                _openEditAddress(address);
              },
              onDelete: () {
                _deleteAddress(address);
              },
              onSetDefault: () {
                _setDefault(address);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: 95,
          height: 10,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.appSoftSurface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        ...List.generate(
          3,
          (index) => Container(
            height: 115,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.appSoftSurface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: context.appAccentSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: _primary,
                size: 28,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              context.tr('noAddresses'),
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              context.tr('noAddressesHint'),
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
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _openAddAddress,
                icon: const Icon(Icons.add, size: 17),
                label: Text(
                  context.tr('addNewAddress'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: _danger, size: 28),
            ),

            const SizedBox(height: 14),

            Text(
              context.tr('unableLoadAddresses'),
              style: TextStyle(
                color: context.appText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              _controller.errorMessage ??
                  'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: _controller.retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  context.tr('tryAgain'),
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
    );
  }
}
