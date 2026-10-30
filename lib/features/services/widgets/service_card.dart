import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/service_text.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../models/service_model.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onDetails,
    required this.onBookNow,
    super.key,
  });

  final ServiceModel service;
  final VoidCallback onDetails;
  final VoidCallback onBookNow;

  String _formatPrice(double price) {
    final value = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(value[i]);
    }

    return '${buffer.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF173951)
                        : const Color(0xFFEAF7F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.ac_unit_rounded,
                    color: Color(0xFF0F8B6D),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedServiceName(context, service.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (service.estimatedDuration != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${service.estimatedDuration} ${context.tr('minutes')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (service.description != null &&
                service.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                localizedServiceDescription(context, service.description!),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(height: 1.5, color: context.appMuted),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              context.tr('startingFrom'),
              style: TextStyle(fontSize: 12, color: context.appMuted),
            ),
            const SizedBox(height: 3),
            Text(
              _formatPrice(service.basePrice),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F8B6D),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetails,
                    child: Text(context.tr('serviceDetails')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onBookNow,
                    child: Text(context.tr('bookService')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
