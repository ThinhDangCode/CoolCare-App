
/// A device the customer has had serviced, grouped by brand + model.
class AcUnitGroup {
  const AcUnitGroup({
    required this.brandId,
    required this.modelId,
    required this.brandName,
    required this.modelName,
    required this.capacityBtu,
    required this.serviceCount,
    required this.completedCount,
    required this.lastServiceAt,
  });

  final String? brandId;
  final String? modelId;
  final String? brandName;
  final String? modelName;
  final num? capacityBtu;
  final int serviceCount;
  final int completedCount;
  final DateTime? lastServiceAt;

  String get title {
    final parts = [brandName, modelName]
        .whereType<String>()
        .where((e) => e.isNotEmpty);
    return parts.join(' ');
  }

  factory AcUnitGroup.fromJson(Map<String, dynamic> json) =>
      AcUnitGroup(
        brandId: _nullable(json['brandId']),
        modelId: _nullable(json['modelId']),
        brandName: _nullable(json['brandName']),
        modelName: _nullable(json['modelName']),
        capacityBtu: json['capacityBtu'] == null
            ? null
            : _number(json['capacityBtu']),
        serviceCount: _number(json['serviceCount']).toInt(),
        completedCount: _number(json['completedCount']).toInt(),
        lastServiceAt: _date(json['lastServiceAt']),
      );
}

class AcHistoryPage {
  const AcHistoryPage({
    required this.unit,
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final AcUnitGroup unit;
  final List<AcHistoryEntry> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  factory AcHistoryPage.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'];
    final items = json['items'];
    final pagination = json['pagination'];

    if (unit is! Map ||
        items is! List ||
        pagination is! Map) {
      throw const FormatException(
        'Invalid AC service history response.',
      );
    }

    return AcHistoryPage(
      unit: AcUnitGroup.fromJson({
        ...Map<String, dynamic>.from(unit),
        'serviceCount': pagination['total'],
        'completedCount': 0,
      }),
      items: items
          .whereType<Map>()
          .map(
            (e) => AcHistoryEntry.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(growable: false),
      page: _number(pagination['page']).toInt(),
      totalPages: _number(pagination['totalPages']).toInt(),
      total: _number(pagination['total']).toInt(),
    );
  }
}

class AcHistoryEntry {
  const AcHistoryEntry({
    required this.bookingId,
    required this.bookingCode,
    required this.status,
    required this.date,
    required this.totalAmount,
    required this.unitNumber,
    required this.description,
    required this.diagnosis,
    required this.serviceNotes,
    required this.technicianName,
    required this.services,
    required this.additionalWork,
    this.phone,
  });

  final String bookingId;
  final String bookingCode;
  final String status;
  final DateTime? date;
  final num totalAmount;
  final int unitNumber;
  final String? description;
  final String? diagnosis;
  final String? serviceNotes;
  final String? technicianName;

  /// Technician's phone number, if provided by the API.
  final String? phone;

  final List<AcHistoryLine> services;
  final List<AcHistoryLine> additionalWork;

  String get title {
    final names = services
        .map((e) => e.name)
        .where((e) => e.isNotEmpty)
        .toList();

    if (names.isNotEmpty) return names.join(', ');

    final extra = additionalWork
        .map((e) => e.name)
        .where((e) => e.isNotEmpty)
        .toList();

    return extra.join(', ');
  }

  factory AcHistoryEntry.fromJson(
      Map<String, dynamic> json,
      ) {
    List<AcHistoryLine> lines(
        dynamic value,
        String nameKey,
        String priceKey,
        ) =>
        value is List
            ? value
            .whereType<Map>()
            .map(
              (e) => AcHistoryLine(
            name: '${e[nameKey] ?? ''}',
            price: _number(e[priceKey]),
          ),
        )
            .toList(growable: false)
            : const [];

    // Support common API field names for the technician's phone.
    // The backend must return one of these fields in each history item.
    final technician = json['technician'];

    final technicianData = technician is Map
        ? Map<String, dynamic>.from(technician)
        : <String, dynamic>{};

    final phone = _nullable(
      json['phone'] ??
          json['technicianPhone'] ??
          technicianData['phone'] ??
          technicianData['phoneNumber'],
    );

    return AcHistoryEntry(
      bookingId: '${json['bookingId'] ?? ''}',
      bookingCode: '${json['bookingCode'] ?? ''}',
      status: '${json['status'] ?? ''}',
      date: _date(json['completedAt']) ??
          _date(json['scheduledAt']),
      totalAmount: _number(json['totalAmount']),
      unitNumber: _number(json['unitNumber']).toInt(),
      description: _nullable(json['description']),
      diagnosis: _nullable(json['diagnosis']),
      serviceNotes: _nullable(json['serviceNotes']),
      technicianName: _nullable(json['technicianName']),
      phone: phone,
      services: lines(
        json['services'],
        'name',
        'unitPrice',
      ),
      additionalWork: lines(
        json['additionalWork'],
        'description',
        'totalPrice',
      ),
    );
  }
}

class AcHistoryLine {
  const AcHistoryLine({
    required this.name,
    required this.price,
  });

  final String name;
  final num price;
}

String? _nullable(dynamic value) {
  final text = value == null ? '' : '$value'.trim();
  return text.isEmpty ? null : text;
}

num _number(dynamic value) =>
    value is num ? value : num.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
