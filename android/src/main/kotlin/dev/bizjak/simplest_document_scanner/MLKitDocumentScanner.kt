package dev.bizjak.simplest_document_scanner

import android.app.Activity.RESULT_OK
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.core.net.toFile
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE_WITH_FILTER
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException

internal class MLKitDocumentScanner {
    fun scanDocuments(
        activity: ComponentActivity,
        scannerLauncher: ActivityResultLauncher<IntentSenderRequest>,
        result: Result,
        galleryImportAllowed: Boolean,
        scannerMode: Int,
        maxNumberOfPages: Int?,
    ) {
        val parsedScannerMode = when (scannerMode) {
            1 -> SCANNER_MODE_FULL
            2 -> SCANNER_MODE_BASE_WITH_FILTER
            3 -> SCANNER_MODE_BASE
            else -> throw IllegalArgumentException("Invalid scanner mode: $scannerMode")
        }

        val optionsBuilder = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(galleryImportAllowed)
            .setScannerMode(parsedScannerMode)
            .setResultFormats(RESULT_FORMAT_JPEG)

        if (maxNumberOfPages != null) {
            if (maxNumberOfPages > 0) {
                optionsBuilder.setPageLimit(maxNumberOfPages)
            } else {
                throw IllegalArgumentException("maxNumberOfPages must be a positive integer")
            }
        }

        val options = optionsBuilder.build()
        val scanner = GmsDocumentScanning.getClient(options)

        scanner.getStartScanIntent(activity)
            .addOnSuccessListener {
                scannerLauncher.launch(IntentSenderRequest.Builder(it).build())
            }
            .addOnFailureListener {
                result.error("SCANNER_ERROR", "Failed to start document scanner", it.toString())
            }
    }

    fun handleScanResult(
        activityResult: ActivityResult,
        result: Result,
    ) {
        if (activityResult.resultCode == RESULT_OK) {
            val intent = activityResult.data
            if (intent != null) {
                GmsDocumentScanningResult.fromActivityResultIntent(intent)
                    ?.pages
                    ?.let { pages ->
                        try {
                            pages
                                .map { it.imageUri.toFile().readBytes() }
                                .also { result.success(it) }
                        } catch (e: IOException) {
                            result.error(
                                "FILE_READ_ERROR",
                                "Failed to read scanned image file",
                                e.toString()
                            )
                        }
                    }
                    ?: result.error("NO_DATA", "No pages returned from scanner", null)
            } else {
                result.error("NO_DATA", "No data returned from scanner", null)
            }
        } else {
            result.error(
                "SCAN_FAILED",
                "Document scanning failed with result code: ${activityResult.resultCode}",
                null
            )
        }
    }
}
