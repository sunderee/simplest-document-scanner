package dev.bizjak.simplest_document_scanner

import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_BASE_WITH_FILTER
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL

internal enum class ScannerModeOption(
    val channelValue: Int,
    val mlKitValue: Int,
) {
    FULL(channelValue = 1, mlKitValue = SCANNER_MODE_FULL),
    BASE_WITH_FILTER(channelValue = 2, mlKitValue = SCANNER_MODE_BASE_WITH_FILTER),
    BASE(channelValue = 3, mlKitValue = SCANNER_MODE_BASE);

    companion object {
        fun fromChannelValue(value: Int?): ScannerModeOption {
            return values().firstOrNull { it.channelValue == value } ?: FULL
        }
    }
}

