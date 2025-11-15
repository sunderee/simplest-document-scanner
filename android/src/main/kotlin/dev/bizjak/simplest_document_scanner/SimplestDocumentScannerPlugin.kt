package dev.bizjak.simplest_document_scanner

import androidx.activity.ComponentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SimplestDocumentScannerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val METHOD_CHANNEL_NAME = "simplest_document_scanner"
        private const val METHOD_SCAN_DOCUMENTS = "scanDocuments"
        private const val ARGUMENT_GALLERY_IMPORT_ALLOWED = "galleryImportAllowed"
        private const val ARGUMENT_SCANNER_MODE = "scannerMode"
        private const val ARGUMENT_MAX_NUMBER_OF_PAGES = "maxNumberOfPages"
    }

    private lateinit var channel: MethodChannel
    private var activity: ComponentActivity? = null
    private val mlKitDocumentScanner = MLKitDocumentScanner()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == METHOD_SCAN_DOCUMENTS) {
            val activity = this.activity
            if (activity == null) {
                result.error("NO_ACTIVITY", "No activity is attached to the plugin", null)
                return
            }

            try {
                mlKitDocumentScanner.scanDocuments(
                    activity,
                    result,
                    call.argument<Boolean>(ARGUMENT_GALLERY_IMPORT_ALLOWED) ?: true,
                    call.argument<Int>(ARGUMENT_SCANNER_MODE) ?: 1,
                    call.argument<Int>(ARGUMENT_MAX_NUMBER_OF_PAGES),
                )
            } catch (e: IllegalArgumentException) {
                result.error("INVALID_ARGUMENT", e.message, null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val newActivity = binding.activity
        if (newActivity is ComponentActivity) {
            activity = newActivity
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        val newActivity = binding.activity
        if (newActivity is ComponentActivity) {
            activity = newActivity
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
