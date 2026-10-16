class MyBooking {
  const MyBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.scheduledAt,
    required this.address,
    required this.totalAmount,
    required this.technicianName,
    required this.unitCount,
    required this.serviceCount,
  });

  final String id;
  final String code;
  final String status;
  final DateTime? scheduledAt;
  final String address;
  final num? totalAmount;
  final String? technicianName;
  final int unitCount;
  final int serviceCount;

  factory MyBooking.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    final addressData = address is Map ? address : const {};
    final technician = json['technician'];
    final technicianData = technician is Map ? technician : const {};
    final pricing = json['pricing'];
    final pricingData = pricing is Map ? pricing : const {};
    return MyBooking(
      id: json['id']?.toString() ?? '',
      code: json['bookingCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
      address:
          [addressData['addressLine'], addressData['ward'], addressData['city']]
              .where(
                (part) => part != null && part.toString().trim().isNotEmpty,
              )
              .join(', '),
      totalAmount: pricingData['totalAmount'] is num
          ? pricingData['totalAmount'] as num
          : num.tryParse(pricingData['totalAmount']?.toString() ?? ''),
      technicianName: technicianData['name']?.toString(),
      unitCount: (json['unitCount'] as num?)?.toInt() ?? 0,
      serviceCount: (json['serviceCount'] as num?)?.toInt() ?? 0,
    );
  }
}
