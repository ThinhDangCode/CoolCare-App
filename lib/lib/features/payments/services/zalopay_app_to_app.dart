import 'package:flutter/services.dart';

class ZaloPayResult {
  final int? errorCode;
  final String? transactionId;
  final String? zpTransToken;
  final String? appTransId;
  final String? message;

  const ZaloPayResult({
    this.errorCode,
    this.transactionId,
    this.zpTransToken,
    this.appTransId,
    this.message,
  });

  bool get isSuccess => errorCode == 1;
  bool get isCanceled => errorCode == 4;
  bool get isError => !isSuccess && !isCanceled;

  factory ZaloPayResult.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['errorCode'];

    return ZaloPayResult(
      errorCode: rawCode is int
          ? rawCode
          : int.tryParse(rawCode?.toString() ?? ''),
      transactionId: map['transactionId']?.toString(),
      zpTransToken: map['zpTranstoken']?.toString(),
      appTransId: map['appTransId']?.toString(),
      message: map['message']?.toString(),
    );
  }
}

class ZaloPayAppToApp {
  ZaloPayAppToApp._();

  static const MethodChannel _methodChannel =
  MethodChannel('flutter.native/channelPayOrder');

  static const EventChannel _eventChannel =
  EventChannel('flutter.native/eventPayOrder');

  static Stream<ZaloPayResult> get paymentResults {
    return _eventChannel.receiveBroadcastStream().map(
          (event) => ZaloPayResult.fromMap(
        Map<dynamic, dynamic>.from(event as Map),
      ),
    );
  }

  static Future<void> payOrder(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('ZaloPay token is empty');
    }

    await _methodChannel.invokeMethod<void>(
      'payOrder',
      {'zptoken': token},
    );
  }
}