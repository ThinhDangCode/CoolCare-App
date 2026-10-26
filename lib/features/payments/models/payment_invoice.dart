/// Invoice document returned by `GET /payments/:id/invoice`.
class PaymentInvoice {
  const PaymentInvoice({
    required this.paymentId,
    required this.invoiceNumber,
    required this.issuedAt,
    required this.bookingCode,
    required this.serviceDate,
    required this.technicianName,
    required this.providerName,
    required this.providerAddress,
    required this.providerHotline,
    required this.providerTaxCode,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerEmail,
    required this.statusLabel,
    required this.methodLabel,
    required this.paidAt,
    required this.items,
    required this.partsAmount,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.notes,
  });

  final String paymentId;
  final String invoiceNumber;
  final DateTime? issuedAt;
  final String bookingCode;
  final DateTime? serviceDate;
  final String? technicianName;
  final String providerName;
  final String? providerAddress;
  final String? providerHotline;
  final String? providerTaxCode;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerEmail;
  final String statusLabel;
  final String methodLabel;
  final DateTime? paidAt;
  final List<PaymentInvoiceItem> items;
  final num partsAmount;
  final num subtotal;
  final num discountAmount;
  final num totalAmount;
  final num paidAmount;
  final num remainingAmount;
  final String notes;

  bool get providerConfigured =>
      (providerAddress ?? '').isNotEmpty && (providerHotline ?? '').isNotEmpty;

  factory PaymentInvoice.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> section(String key) {
      final value = json[key];
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    }

    final booking = section('booking');
    final provider = section('provider');
    final customer = section('customer');
    final payment = section('payment');
    final rawItems = json['items'];

    return PaymentInvoice(
      paymentId: _text(json['paymentId']),
      invoiceNumber: _text(json['invoiceNumber']),
      issuedAt: _date(json['issuedAt']),
      bookingCode: _text(booking['code']),
      serviceDate: _date(booking['serviceDate']),
      technicianName: _nullableText(booking['technicianName']),
      providerName: _nullableText(provider['name']) ?? 'CoolCare',
      providerAddress: _nullableText(provider['address']),
      providerHotline: _nullableText(provider['hotline']),
      providerTaxCode: _nullableText(provider['taxCode']),
      customerName: _text(customer['name']),
      customerPhone: _text(customer['phoneMasked']),
      customerAddress: _text(customer['address']),
      customerEmail: _text(customer['emailMasked']),
      statusLabel: _text(payment['statusLabel']),
      methodLabel: _text(payment['methodLabel']),
      paidAt: _date(payment['paidAt']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => PaymentInvoiceItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const [],
      partsAmount: _number(json['partsAmount']),
      subtotal: _number(json['subtotal']),
      discountAmount: _number(json['discountAmount']),
      totalAmount: _number(json['totalAmount']),
      paidAmount: _number(json['paidAmount']),
      remainingAmount: _number(json['remainingAmount']),
      notes: _text(json['notes']),
    );
  }
}

class PaymentInvoiceItem {
  const PaymentInvoiceItem({
    required this.type,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String type;
  final String description;
  final num quantity;
  final num unitPrice;
  final num totalPrice;

  factory PaymentInvoiceItem.fromJson(Map<String, dynamic> json) {
    final quantity = _number(json['quantity']);
    return PaymentInvoiceItem(
      type: _text(json['type']),
      description: _text(json['description']),
      quantity: quantity == 0 ? 1 : quantity,
      unitPrice: _number(json['unitPrice']),
      totalPrice: _number(json['totalPrice']),
    );
  }
}

String _text(dynamic value) => value == null ? '' : '$value';

String? _nullableText(dynamic value) {
  final text = _text(value).trim();
  return text.isEmpty ? null : text;
}

num _number(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
