import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';

class NotificationDetailDialog extends StatelessWidget {
  const NotificationDetailDialog({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.bookingCode,
    super.key,
  });

  final String title;
  final String message;
  final String timestamp;
  final String? bookingCode;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final code = bookingCode?.trim();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 620),
        child: Material(
          color: context.appElevatedSurface,
          elevation: 18,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 5, color: CoolCareColors.primary),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOTIFICATION DETAILS',
                                  style: TextStyle(
                                    color: context.appMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontSize: 18,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: context.appSoftSurface,
                              foregroundColor: context.appMuted,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 19),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appSoftSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: context.appSubtleText,
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (code?.isNotEmpty == true) ...[
                        const SizedBox(height: 18),
                        Text(
                          'RELATED BOOKING',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: context.appAccentSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                color: CoolCareColors.primaryDark,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  code!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CoolCareColors.primaryDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: context.appMuted,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              timestamp,
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: CoolCareColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
}
