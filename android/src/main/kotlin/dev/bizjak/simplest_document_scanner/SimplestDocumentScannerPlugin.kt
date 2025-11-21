package dev.bizjak.simplest_document_scanner

import androidx.activity.ComponentActivity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
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
    private var scannerLauncher: androidx.activity.result.ActivityResultLauncher<IntentSenderRequest>? = null
    private var pendingResult: Result? = null
    private val mlKitDocumentScanner = MLKitDocumentScanner()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == METHOD_SCAN_DOCUMENTS) {
            val activity = this.activity
            val launcher = this.scannerLauncher
            
            if (activity == null || launcher == null) {
                result.error("NO_ACTIVITY", "No activity is attached to the plugin", null)
                return
            }

            if (pendingResult != null) {
                result.error("SCAN_IN_PROGRESS", "Another scan is already in progress", null)
                return
            }

            pendingResult = result

            try {
                val wrappedResult = object : Result {
                    override fun success(resultValue: Any?) {
                        pendingResult = null
                        result.success(resultValue)
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        pendingResult = null
                        result.error(errorCode, errorMessage, errorDetails)
                    }

                    override fun notImplemented() {
                        pendingResult = null
                        result.notImplemented()
                    }
                }

                mlKitDocumentScanner.scanDocuments(
                    activity,
                    launcher,
                    wrappedResult,
                    call.argument<Boolean>(ARGUMENT_GALLERY_IMPORT_ALLOWED) ?: true,
                    call.argument<Int>(ARGUMENT_SCANNER_MODE) ?: 1,
                    call.argument<Int>(ARGUMENT_MAX_NUMBER_OF_PAGES),
                )
            } catch (e: IllegalArgumentException) {
                pendingResult = null
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
            scannerLauncher = newActivity.registerForActivityResult(
                ActivityResultContracts.StartIntentSenderForResult()
            ) { activityResult ->
                val result = pendingResult
                pendingResult = null
                if (result != null) {
                    mlKitDocumentScanner.handleScanResult(activityResult, result)
                }
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        scannerLauncher = null
        activity = null
        pendingResult?.error("ACTIVITY_DETACHED", "Activity was detached during scan", null)
        pendingResult = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        val newActivity = binding.activity
        if (newActivity is ComponentActivity) {
            activity = newActivity
            scannerLauncher = newActivity.registerForActivityResult(
                ActivityResultContracts.StartIntentSenderForResult()
            ) { activityResult ->
                val result = pendingResult
                pendingResult = null
                if (result != null) {
                    mlKitDocumentScanner.handleScanResult(activityResult, result)
                }
            }
        }
    }

    override fun onDetachedFromActivity() {
        scannerLauncher = null
        activity = null
        pendingResult?.error("ACTIVITY_DETACHED", "Activity was detached during scan", null)
        pendingResult = null
    }
}
