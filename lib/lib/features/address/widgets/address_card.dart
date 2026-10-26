import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../models/address_model.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    super.key,
  });

  final AddressModel address;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  static const Color _primary = Color(0xFF078B96);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.appAccentSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: _primary,
                  size: 17,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.recipientName,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.appAccentSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr('defaultLabel'),
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      address.phone,
                      style: TextStyle(color: context.appMuted, fontSize: 11),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      address.fullAddress,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Divider(height: 1, color: context.appBorder),

          const SizedBox(height: 10),

          Row(
            children: [
              _AddressAction(
                icon: Icons.edit_outlined,
                label: context.tr('edit'),
                onTap: onEdit,
              ),

              const SizedBox(width: 20),

              _AddressAction(
                icon: Icons.delete_outline,
                label: context.tr('delete'),
                color: const Color(0xFFB42318),
                onTap: onDelete,
              ),

              const Spacer(),

              if (!address.isDefault)
                TextButton(
                  onPressed: onSetDefault,
                  child: Text(
                    context.tr('setAsDefault'),
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressAction extends StatelessWidget {
  const _AddressAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF078B96),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
