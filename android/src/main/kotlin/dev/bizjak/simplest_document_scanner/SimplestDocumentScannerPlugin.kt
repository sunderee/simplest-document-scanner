package dev.bizjak.simplest_document_scanner

import androidx.activity.ComponentActivity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.VisibleForTesting
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
    }

    private lateinit var channel: MethodChannel
    private var activity: ComponentActivity? = null
    private var scannerLauncher: androidx.activity.result.ActivityResultLauncher<IntentSenderRequest>? = null
    private var pendingResult: Result? = null
    private var pendingRequest: DocumentScannerRequest? = null
    private var mlKitDocumentScanner = MLKitDocumentScanner()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_SCAN_DOCUMENTS -> handleScanRequest(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleScanRequest(call: MethodCall, result: Result) {
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

        val request = try {
            call.toDocumentScannerRequest()
        } catch (error: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", error.message, null)
            return
        }

        pendingResult = result
        pendingRequest = request

        val wrappedResult = object : Result {
            override fun success(resultValue: Any?) {
                clearPendingState()
                result.success(resultValue)
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                clearPendingState()
                result.error(errorCode, errorMessage, errorDetails)
            }

            override fun notImplemented() {
                clearPendingState()
                result.notImplemented()
            }
        }

        mlKitDocumentScanner.scanDocuments(
            activity = activity,
            scannerLauncher = launcher,
            result = wrappedResult,
            request = request,
        )
    }

    @VisibleForTesting
    internal fun MethodCall.toDocumentScannerRequest(): DocumentScannerRequest {
        val allowGalleryImport = argument<Boolean>("allowGalleryImport") ?: true
        val maxPages = (argument<Any?>("maxPages") as? Number)?.toInt()
        val returnJpegs = argument<Boolean>("returnJpegs") ?: true
        val returnPdf = argument<Boolean>("returnPdf") ?: false

        if (!returnJpegs && !returnPdf) {
            throw IllegalArgumentException("At least one of returnJpegs or returnPdf must be true.")
        }

        val jpegQuality = when (val rawQuality = argument<Any?>("jpegQuality")) {
            is Number -> rawQuality.toDouble()
            null -> 0.9
            else -> throw IllegalArgumentException("jpegQuality must be numeric.")
        }

        if (maxPages != null && maxPages <= 0) {
            throw IllegalArgumentException("maxPages must be a positive integer.")
        }

        if (jpegQuality < 0 || jpegQuality > 1) {
            throw IllegalArgumentException("jpegQuality must be between 0 and 1.")
        }

        val androidArguments = argument<Map<String, Any?>>("android")
        val scannerModeValue = (androidArguments?.get("scannerMode") as? Number)?.toInt() ?: 1

        return DocumentScannerRequest(
            allowGalleryImport = allowGalleryImport,
            maxPages = maxPages,
            returnJpegs = returnJpegs,
            returnPdf = returnPdf,
            jpegQuality = jpegQuality,
            scannerMode = ScannerModeOption.fromChannelValue(scannerModeValue),
        )
    }

    private fun clearPendingState() {
        pendingResult = null
        pendingRequest = null
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
                val callbackResult = pendingResult
                val request = pendingRequest
                val currentActivity = activity
                clearPendingState()

                if (callbackResult != null) {
                    if (request == null || currentActivity == null) {
                        callbackResult.error(
                            "NO_ACTIVITY",
                            "The Activity reference was lost before delivering scan results.",
                            null,
                        )
                    } else {
                        mlKitDocumentScanner.handleScanResult(
                            activity = currentActivity,
                            activityResult = activityResult,
                            request = request,
                            result = callbackResult,
                        )
                    }
                }
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        scannerLauncher = null
        activity = null
        pendingResult?.error("ACTIVITY_DETACHED", "Activity was detached during scan", null)
        clearPendingState()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        scannerLauncher = null
        activity = null
        pendingResult?.error("ACTIVITY_DETACHED", "Activity was detached during scan", null)
        clearPendingState()
    }

    @VisibleForTesting
    internal fun configureForTesting(
        activity: ComponentActivity?,
        launcher: androidx.activity.result.ActivityResultLauncher<IntentSenderRequest>?,
        documentScanner: MLKitDocumentScanner = MLKitDocumentScanner(),
    ) {
        this.activity = activity
        this.scannerLauncher = launcher
        this.mlKitDocumentScanner = documentScanner
        clearPendingState()
    }
}

internal data class DocumentScannerRequest(
    val allowGalleryImport: Boolean,
    val maxPages: Int?,
    val returnJpegs: Boolean,
    val returnPdf: Boolean,
    val jpegQuality: Double,
    val scannerMode: ScannerModeOption,
)
