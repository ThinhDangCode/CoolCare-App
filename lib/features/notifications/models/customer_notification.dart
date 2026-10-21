class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.referenceType,
    required this.referenceId,
    required this.bookingCode,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String? referenceType;
  final String? referenceId;
  final String? bookingCode;
  final bool isRead;
  final DateTime? createdAt;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      bookingCode: json['bookingCode']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  CustomerNotification copyWith({bool? isRead}) => CustomerNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    referenceType: referenceType,
    referenceId: referenceId,
    bookingCode: bookingCode,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
