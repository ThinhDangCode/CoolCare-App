class AcServiceHistory {
  const AcServiceHistory({
    required this.unit,
    required this.items,
    required this.pagination,
  });

  factory AcServiceHistory.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'];
    final items = json['items'];
    final pagination = json['pagination'];
    if (unit is! Map<String, dynamic> ||
        items is! List ||
        pagination is! Map<String, dynamic>) {
      throw const FormatException('Invalid AC service history response.');
    }
    return AcServiceHistory(
      unit: AcServiceHistoryUnit.fromJson(unit),
      items: items
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid history item.');
            }
            return AcServiceHistoryItem.fromJson(item);
          })
          .toList(growable: false),
      pagination: AcServiceHistoryPagination.fromJson(pagination),
    );
  }

  final AcServiceHistoryUnit unit;
  final List<AcServiceHistoryItem> items;
  final AcServiceHistoryPagination pagination;
}

class AcServiceHistoryUnit {
  const AcServiceHistoryUnit({
    required this.id,
    required this.unitNumber,
    this.brandName,
    this.modelName,
    this.description,
  });
  factory AcServiceHistoryUnit.fromJson(Map<String, dynamic> json) =>
      AcServiceHistoryUnit(
        id: json['id']?.toString() ?? '',
        unitNumber: _integer(json['unitNumber']),
        brandName: json['brandName']?.toString(),
        modelName: json['modelName']?.toString(),
        description: json['description']?.toString(),
      );
  final String id;
  final int unitNumber;
  final String? brandName;
  final String? modelName;
  final String? description;
}

class AcServiceHistoryItem {
  const AcServiceHistoryItem({
    required this.bookingCode,
    required this.totalAmount,
    required this.services,
    required this.additionalWork,
    this.completedAt,
    this.diagnosis,
    this.serviceNotes,
    this.bookingDescription,
    this.technicianName,
  });
  factory AcServiceHistoryItem.fromJson(Map<String, dynamic> json) =>
      AcServiceHistoryItem(
        bookingCode: json['bookingCode']?.toString() ?? '',
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
        totalAmount: _number(json['totalAmount']),
        diagnosis: json['diagnosis']?.toString(),
        serviceNotes: json['serviceNotes']?.toString(),
        bookingDescription: json['bookingDescription']?.toString(),
        technicianName: json['technicianName']?.toString(),
        services: _maps(
          json['services'],
        ).map(AcHistoryService.fromJson).toList(growable: false),
        additionalWork: _maps(
          json['additionalWork'],
        ).map(AcAdditionalWork.fromJson).toList(growable: false),
      );
  final String bookingCode;
  final DateTime? completedAt;
  final double totalAmount;
  final String? diagnosis;
  final String? serviceNotes;
  final String? bookingDescription;
  final String? technicianName;
  final List<AcHistoryService> services;
  final List<AcAdditionalWork> additionalWork;
  String get title => services.isNotEmpty
      ? services.map((item) => item.name).join(', ')
      : additionalWork.isNotEmpty
      ? additionalWork.map((item) => item.description).join(', ')
      : 'AC service';
  String get summary => [diagnosis, serviceNotes, bookingDescription]
      .where((value) => value?.trim().isNotEmpty == true)
      .cast<String>()
      .join(' · ');
}

class AcHistoryService {
  const AcHistoryService({required this.name, required this.unitPrice});
  factory AcHistoryService.fromJson(Map<String, dynamic> json) =>
      AcHistoryService(
        name: json['name']?.toString() ?? '',
        unitPrice: _number(json['unitPrice']),
      );
  final String name;
  final double unitPrice;
}

class AcAdditionalWork {
  const AcAdditionalWork({required this.description, required this.totalPrice});
  factory AcAdditionalWork.fromJson(Map<String, dynamic> json) =>
      AcAdditionalWork(
        description: json['description']?.toString() ?? '',
        totalPrice: _number(json['totalPrice']),
      );
  final String description;
  final double totalPrice;
}

class AcServiceHistoryPagination {
  const AcServiceHistoryPagination({
    required this.page,
    required this.totalPages,
    required this.total,
  });
  factory AcServiceHistoryPagination.fromJson(Map<String, dynamic> json) =>
      AcServiceHistoryPagination(
        page: _integer(json['page']),
        totalPages: _integer(json['totalPages']),
        total: _integer(json['total']),
      );
  final int page;
  final int totalPages;
  final int total;
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];
double _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
int _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
