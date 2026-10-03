import 'package:flutter/material.dart';

import '../../../../app/theme/coolcare_theme.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  static const _filters = ['All', 'Cleaning', 'Repair', 'Installation'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('services-page'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOME AC CARE SERVICE',
            style: TextStyle(
              color: CoolCareColors.primaryDark,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'AC Services',
            style: TextStyle(
              color: CoolCareColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Choose the service that fits your needs.',
            style: TextStyle(color: CoolCareColors.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search services',
              hintStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final selected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : CoolCareColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: CoolCareColors.primary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: CoolCareColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'All Services',
                  style: TextStyle(
                    color: CoolCareColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '3 services',
                style: TextStyle(color: CoolCareColors.mutedText, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const _ServiceCard(
            type: 'CLEANING',
            title: 'AC Cleaning',
            description: 'Full AC maintenance, condenser and air filter.',
            priceLabel: 'Starting from',
            price: '150,000₫ / unit',
            icon: Icons.cleaning_services_outlined,
          ),
          const SizedBox(height: 11),
          const _ServiceCard(
            type: 'REPAIR',
            title: 'AC Repair',
            description: 'Check AC not cooling, leaking or making noise.',
            priceLabel: 'Service Cost',
            price: 'Quote after inspection',
            icon: Icons.build_outlined,
          ),
          const SizedBox(height: 11),
          const _ServiceCard(
            type: 'INSTALLATION',
            title: 'AC Installation',
            description: 'Install equipment and test operation after setup.',
            priceLabel: 'Starting from',
            price: '300,000₫ / unit',
            icon: Icons.air_rounded,
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Price excludes materials and additional parts.',
              style: TextStyle(color: CoolCareColors.mutedText, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.type,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.price,
    required this.icon,
  });

  final String type;
  final String title;
  final String description;
  final String priceLabel;
  final String price;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CoolCareColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17333A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CoolCareColors.primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: CoolCareColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: CoolCareColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: CoolCareColors.mutedText,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              color: CoolCareColors.mutedText,
                              fontSize: 8,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              color: CoolCareColors.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 31),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Details  +',
                      style: TextStyle(
                        color: CoolCareColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
