package dev.bizjak.simplest_document_scanner

import android.app.Activity.RESULT_CANCELED
import android.app.Activity.RESULT_OK
import android.content.ContentResolver
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import com.google.mlkit.common.MlKitException
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_PDF
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException

internal class MLKitDocumentScanner {
    fun scanDocuments(
        activity: ComponentActivity,
        scannerLauncher: ActivityResultLauncher<IntentSenderRequest>,
        result: Result,
        request: DocumentScannerRequest,
    ) {
        val optionsBuilder = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(request.allowGalleryImport)
            .setScannerMode(request.scannerMode.mlKitValue)

        when {
            request.returnJpegs && request.returnPdf -> optionsBuilder.setResultFormats(
                RESULT_FORMAT_JPEG,
                RESULT_FORMAT_PDF,
            )
            request.returnPdf -> optionsBuilder.setResultFormats(RESULT_FORMAT_PDF)
            else -> optionsBuilder.setResultFormats(RESULT_FORMAT_JPEG)
        }

        request.maxPages?.let { optionsBuilder.setPageLimit(it) }

        val scanner = GmsDocumentScanning.getClient(optionsBuilder.build())

        scanner.getStartScanIntent(activity)
            .addOnSuccessListener {
                scannerLauncher.launch(IntentSenderRequest.Builder(it).build())
            }
            .addOnFailureListener { throwable ->
                if (throwable is MlKitException && throwable.errorCode == MlKitException.UNSUPPORTED) {
                    result.error(
                        "DOCUMENT_SCANNER_UNSUPPORTED",
                        "This device does not support the ML Kit document scanner.",
                        throwable.localizedMessage,
                    )
                } else {
                    result.error(
                        "SCANNER_ERROR",
                        "Failed to start document scanner.",
                        throwable.localizedMessage,
                    )
                }
            }
    }

    fun handleScanResult(
        activity: ComponentActivity,
        activityResult: ActivityResult,
        request: DocumentScannerRequest,
        result: Result,
    ) {
        when (activityResult.resultCode) {
            RESULT_OK -> handleSuccess(activity, activityResult, request, result)
            RESULT_CANCELED -> result.success(null)
            else -> result.error(
                "SCAN_FAILED",
                "Document scanning failed with result code: ${activityResult.resultCode}",
                null,
            )
        }
    }

    private fun handleSuccess(
        activity: ComponentActivity,
        activityResult: ActivityResult,
        request: DocumentScannerRequest,
        result: Result,
    ) {
        val intent = activityResult.data
        if (intent == null) {
            result.error("NO_DATA", "No data returned from scanner", null)
            return
        }

        val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(intent)
            ?: run {
                result.error("NO_DATA", "No data returned from scanner", null)
                return
            }

        val payload = mutableMapOf<String, Any>(
            "pages" to emptyList<Map<String, Any>>(),
        )

        if (request.returnJpegs) {
            val pages = scanResult.pages
            if (pages.isNullOrEmpty()) {
                result.error("NO_DATA", "No pages returned from scanner", null)
                return
            }

            try {
                val pagePayloads = pages.mapIndexed { index, page ->
                    mapOf(
                        "index" to index,
                        "bytes" to readBytes(activity.contentResolver, page.imageUri),
                    )
                }
                payload["pages"] = pagePayloads
            } catch (error: IOException) {
                result.error(
                    "FILE_READ_ERROR",
                    "Failed to read scanned image file.",
                    error.localizedMessage,
                )
                return
            }
        }

        if (request.returnPdf) {
            val pdf = scanResult.pdf
            if (pdf == null) {
                result.error("NO_DATA", "No PDF returned from scanner", null)
                return
            }

            try {
                payload["pdf"] = readBytes(activity.contentResolver, pdf.uri)
            } catch (error: IOException) {
                result.error(
                    "FILE_READ_ERROR",
                    "Failed to read scanned PDF file.",
                    error.localizedMessage,
                )
                return
            }
        }

        result.success(payload)
    }

    private fun readBytes(contentResolver: ContentResolver, uri: Uri): ByteArray {
        return contentResolver.openInputStream(uri)?.use { input ->
            input.readBytes()
        } ?: throw IOException("Unable to open document at $uri")
    }
}
