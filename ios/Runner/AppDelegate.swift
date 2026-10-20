import Flutter
import UIKit
import zpdk

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler, ZPPaymentDelegate {
  private let channelPayOrder = "flutter.native/channelPayOrder"
  private let channelEventPayOrder = "flutter.native/eventPayOrder"
  private let callbackScheme = "coolcare-zalopay"
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ZalopaySDK.sharedInstance()?.initWithAppId(
      554,
      uriScheme: callbackScheme,
      environment: ZPZPIEnvironment_Sandbox
    )
    ZalopaySDK.sharedInstance()?.paymentDelegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CoolCareZaloPay") else {
      NSLog("CoolCareZaloPay: Flutter registrar unavailable")
      return
    }
    let messenger = registrar.messenger()

    let methodChannel = FlutterMethodChannel(name: channelPayOrder, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { call, result in
      guard call.method == "payOrder" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let token = args["zptoken"] as? String,
            !token.isEmpty else {
        result(FlutterError(code: "INVALID_TOKEN", message: "Missing ZaloPay token", details: nil))
        return
      }
      NSLog("CoolCareZaloPay: Starting ZaloPay payment")
      ZalopaySDK.sharedInstance()?.payOrder(token)
      result(nil)
    }

    let eventChannel = FlutterEventChannel(name: channelEventPayOrder, binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    NSLog("CoolCareZaloPay: Flutter event listener attached")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func sendEvent(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      if let sink = self?.eventSink {
        sink(event)
      } else {
        NSLog("CoolCareZaloPay: Flutter event listener unavailable")
      }
    }
  }

  func paymentDidSucceeded(_ transactionId: String!, zpTranstoken: String!, appTransId: String!) {
    NSLog("CoolCareZaloPay: Payment succeeded")
    sendEvent(["errorCode": 1, "transactionId": transactionId ?? "", "zpTranstoken": zpTranstoken ?? "", "appTransId": appTransId ?? ""])
  }

  func paymentDidCanceled(_ zpTranstoken: String!, appTransId: String!) {
    NSLog("CoolCareZaloPay: Payment canceled")
    sendEvent(["errorCode": 4, "zpTranstoken": zpTranstoken ?? "", "appTransId": appTransId ?? ""])
  }

  func paymentDidError(_ errorCode: ZPPaymentErrorCode, zpTranstoken: String!, appTransId: String!) {
    NSLog("CoolCareZaloPay: Payment error: \(errorCode)")
    sendEvent(["errorCode": -1, "message": String(describing: errorCode), "zpTranstoken": zpTranstoken ?? "", "appTransId": appTransId ?? ""])
  }

  func handleZaloPayCallback(_ url: URL) -> Bool {
    guard url.scheme == callbackScheme else { return false }
    NSLog("CoolCareZaloPay: Received callback deep link")
    return ZalopaySDK.sharedInstance()?.application(UIApplication.shared, open: url, options: [:]) ?? false
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if handleZaloPayCallback(url) { return true }
    return super.application(app, open: url, options: options)
  }
}
