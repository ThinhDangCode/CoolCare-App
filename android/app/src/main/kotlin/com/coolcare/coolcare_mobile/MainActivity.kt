
package com.coolcare.coolcare_mobile

import android.content.Intent
import android.os.Bundle
import android.util.Log

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import vn.zalopay.sdk.Environment
import vn.zalopay.sdk.ZaloPayError
import vn.zalopay.sdk.ZaloPaySDK
import vn.zalopay.sdk.listeners.PayOrderListener

class MainActivity : FlutterActivity() {

    private val tag = "CoolCareZaloPay"

    private val methodChannelName =
        "flutter.native/channelPayOrder"

    private val eventChannelName =
        "flutter.native/eventPayOrder"

    private val deeplink = "coolcare-zalopay://app"

    private var eventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ZaloPaySDK.init(
            ZALOPAY_APP_ID,
            Environment.SANDBOX
        )

        Log.d(tag, "ZaloPay SDK initialized")

        handleZaloPayIntent(intent)
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName
        ).setStreamHandler(
            object : EventChannel.StreamHandler {

                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    eventSink = events
                    Log.d(tag, "Flutter event listener attached")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(tag, "Flutter event listener detached")
                }
            }
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->

            if (call.method != "payOrder") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val token = call.argument<String>("zptoken")

            if (token.isNullOrBlank()) {
                result.error(
                    "INVALID_TOKEN",
                    "Missing ZaloPay transaction token",
                    null
                )
                return@setMethodCallHandler
            }

            try {
                Log.d(tag, "Starting ZaloPay payment")

                ZaloPaySDK.getInstance().payOrder(
                    this@MainActivity,
                    token,
                    deeplink,
                    object : PayOrderListener {

                        override fun onPaymentSucceeded(
                            transactionId: String,
                            transToken: String,
                            appTransID: String?
                        ) {
                            Log.d(
                                tag,
                                "ZaloPay payment succeeded"
                            )

                            sendEvent(
                                mapOf(
                                    "errorCode" to 1,
                                    "transactionId" to transactionId,
                                    "zpTranstoken" to transToken,
                                    "appTransId" to appTransID
                                )
                            )
                        }

                        override fun onPaymentCanceled(
                            zpTransToken: String?,
                            appTransID: String?
                        ) {
                            Log.d(
                                tag,
                                "ZaloPay payment canceled"
                            )

                            sendEvent(
                                mapOf(
                                    "errorCode" to 4,
                                    "zpTranstoken" to zpTransToken,
                                    "appTransId" to appTransID
                                )
                            )
                        }

                        override fun onPaymentError(
                            error: ZaloPayError?,
                            zpTransToken: String?,
                            appTransID: String?
                        ) {
                            Log.e(
                                tag,
                                "ZaloPay payment error: $error"
                            )

                            sendEvent(
                                mapOf(
                                    "errorCode" to -1,
                                    "message" to error.toString(),
                                    "zpTranstoken" to zpTransToken,
                                    "appTransId" to appTransID
                                )
                            )
                        }
                    }
                )

                result.success(null)

            } catch (e: Exception) {
                Log.e(
                    tag,
                    "Failed to open ZaloPay",
                    e
                )

                result.error(
                    "ZALOPAY_SDK_ERROR",
                    e.message,
                    null
                )
            }
        }
    }

    private fun sendEvent(event: Map<String, Any?>) {
        Log.d(
            tag,
            "Sending payment result to Flutter: " +
                    event["errorCode"]
        )

        runOnUiThread {
            val sink = eventSink

            if (sink != null) {
                sink.success(event)
            } else {
                Log.w(
                    tag,
                    "Flutter event listener unavailable"
                )
            }
        }
    }

    private fun handleZaloPayIntent(
        incoming: Intent?
    ) {
        val uri = incoming?.data ?: return

        if (uri.scheme != "coolcare-zalopay") {
            return
        }

        Log.d(
            tag,
            "Received ZaloPay deep link"
        )

        Log.d(
            tag,
            "Callback host: ${uri.host}"
        )

        ZaloPaySDK.getInstance().onResult(incoming)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        Log.d(tag, "MainActivity onNewIntent")

        handleZaloPayIntent(intent)
    }

    companion object {
        private const val ZALOPAY_APP_ID = 554
    }
}
