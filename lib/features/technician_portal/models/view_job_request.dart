class ViewJobRequest {
  const ViewJobRequest({
    required this.id,
    required this.status,
    required this.canRespond,
    this.canComplete = false,
    this.canCancelAcceptedJob = false,
    required this.requestedAt,
    required this.booking,
    required this.customer,
    this.expiresAt,
    this.historyAt,
    this.matchScore,
    this.matchReason,
  });

  factory ViewJobRequest.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    final customer = json['customer'];
    if (booking is! Map<String, dynamic> || customer is! Map<String, dynamic>) {
      throw const FormatException('Invalid job request response.');
    }
    return ViewJobRequest(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      canRespond: json['canRespond'] == true,
      canComplete: json['canComplete'] == true,
      canCancelAcceptedJob: json['canCancelAcceptedJob'] == true,
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      historyAt: DateTime.tryParse(json['historyAt']?.toString() ?? ''),
      matchScore: _number(json['matchScore']),
      matchReason: json['matchReason']?.toString(),
      booking: ViewJobRequestBooking.fromJson(booking),
      customer: ViewJobRequestCustomer.fromJson(customer),
    );
  }

  final String id;
  final String status;
  final bool canRespond;
  final bool canComplete;
  final bool canCancelAcceptedJob;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final DateTime? historyAt;
  final double? matchScore;
  final String? matchReason;
  final ViewJobRequestBooking booking;
  final ViewJobRequestCustomer customer;
}

class ViewJobRequestBooking {
  const ViewJobRequestBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.address,
    required this.recipientName,
    required this.recipientPhone,
    required this.totalAmount,
    required this.units,
    this.description,
    this.scheduledAt,
  });

  factory ViewJobRequestBooking.fromJson(Map<String, dynamic> json) {
    final address = json['address'] is Map<String, dynamic>
        ? json['address'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final recipient = json['recipient'] is Map<String, dynamic>
        ? json['recipient'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawUnits = json['units'];
    return ViewJobRequestBooking(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
      address: [
        address['addressLine'],
        address['ward'],
        address['city'],
      ].where((part) => part?.toString().trim().isNotEmpty == true).join(', '),
      recipientName: recipient['name']?.toString() ?? '',
      recipientPhone: recipient['phone']?.toString() ?? '',
      totalAmount: _number(pricing['totalAmount']) ?? 0,
      units: rawUnits is List
          ? rawUnits
                .whereType<Map<String, dynamic>>()
                .map(ViewJobRequestUnit.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String code;
  final String status;
  final String? description;
  final DateTime? scheduledAt;
  final String address;
  final String recipientName;
  final String recipientPhone;
  final double totalAmount;
  final List<ViewJobRequestUnit> units;

  List<String> get serviceNames => units
      .expand((unit) => unit.services)
      .map((service) => service.name)
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);

  String get primaryServiceName =>
      serviceNames.isEmpty ? 'CoolCare Service' : serviceNames.first;
}

class ViewJobRequestUnit {
  const ViewJobRequestUnit({
    required this.id,
    required this.unitNumber,
    required this.services,
    this.description,
    this.brandId,
    this.modelId,
    this.brandName,
    this.modelName,
  });

  factory ViewJobRequestUnit.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    return ViewJobRequestUnit(
      id: json['id']?.toString() ?? '',
      unitNumber: (json['unitNumber'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      brandId: json['brandId']?.toString(),
      modelId: json['modelId']?.toString(),
      brandName: json['brandName']?.toString(),
      modelName: json['modelName']?.toString(),
      services: rawServices is List
          ? rawServices
                .whereType<Map<String, dynamic>>()
                .map(ViewJobRequestService.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final int unitNumber;
  final String? description;
  final String? brandId;
  final String? modelId;
  final String? brandName;
  final String? modelName;
  final List<ViewJobRequestService> services;
}

class ViewJobRequestService {
  const ViewJobRequestService({
    required this.id,
    required this.name,
    required this.unitPrice,
  });

  factory ViewJobRequestService.fromJson(Map<String, dynamic> json) =>
      ViewJobRequestService(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        unitPrice: _number(json['unitPrice']) ?? 0,
      );

  final String id;
  final String name;
  final double unitPrice;
}

class ViewJobRequestCustomer {
  const ViewJobRequestCustomer({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory ViewJobRequestCustomer.fromJson(Map<String, dynamic> json) =>
      ViewJobRequestCustomer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
      );

  final String id;
  final String name;
  final String? avatarUrl;
}

double? _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
