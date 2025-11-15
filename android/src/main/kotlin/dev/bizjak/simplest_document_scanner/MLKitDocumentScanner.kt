package dev.bizjak.simplest_document_scanner

import android.app.Activity.RESULT_OK
import androidx.activity.ComponentActivity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.net.toFile
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE_WITH_FILTER
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.MethodChannel

internal object MLKitDocumentScanner {
    fun scanDocuments(
        context: ComponentActivity,
        methodChannelResult: MethodChannel.Result,
        galleryImportAllowed: Boolean = true,
        scannerMode: Int = SCANNER_MODE_FULL,
    ) {
        val parsedScannerMode = when (scannerMode) {
            0 -> SCANNER_MODE_FULL
            1 -> SCANNER_MODE_BASE_WITH_FILTER
            2 -> SCANNER_MODE_BASE
            else -> throw IllegalArgumentException("Invalid scanner mode")
        }

        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(galleryImportAllowed)
            .setScannerMode(parsedScannerMode)
            .setResultFormats(RESULT_FORMAT_JPEG)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)
        val scannerLauncher =
            context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
                if (result.resultCode == RESULT_OK) {
                    val result = GmsDocumentScanningResult.fromActivityResultIntent(result.data)

                    result?.pages?.let { pages ->
                        val pagesBytes = mutableListOf<ByteArray>()
                        for (page in pages) {
                            pagesBytes.add(page.imageUri.toFile().readBytes())
                        }

                        methodChannelResult.success(pagesBytes)
                    }
                }
            }
        scanner.getStartScanIntent(context)
            .addOnSuccessListener { intentSender ->
                scannerLauncher.launch(
                    IntentSenderRequest.Builder(
                        intentSender
                    ).build()
                )
            }
            .addOnFailureListener { exception ->
                methodChannelResult.error(
                    "UNABLE_TO_START_SCAN",
                    exception.message,
                    null
                )
            }
    }
}