package dev.bizjak.simplest_document_scanner

import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SimplestDocumentScannerPluginTest {

    @Test
    fun `onMethodCall scanDocuments with no activity should return error`() {
        val plugin = SimplestDocumentScannerPlugin()
        val mockResult = mock<Result>()

        plugin.onMethodCall(MethodCall("scanDocuments", null), mockResult)

        verify(mockResult).error("NO_ACTIVITY", "No activity is attached to the plugin", null)
    }

    @Test
    fun `onMethodCall scanDocuments with valid arguments should call scanner`() {
        val plugin = SimplestDocumentScannerPlugin()
        val mockScanner = mock<MLKitDocumentScanner>()
        val mockActivity = mock<ComponentActivity>()
        val mockLauncher = mock<ActivityResultLauncher<IntentSenderRequest>>()
        val mockResult = mock<Result>()

        plugin.configureForTesting(
            activity = mockActivity,
            launcher = mockLauncher,
            documentScanner = mockScanner,
        )

        val arguments = mapOf(
            "allowGalleryImport" to false,
            "maxPages" to 5,
            "returnJpegs" to true,
            "returnPdf" to true,
            "jpegQuality" to 0.8,
            "android" to mapOf("scannerMode" to 2),
        )
        val methodCall = MethodCall("scanDocuments", arguments)

        plugin.onMethodCall(methodCall, mockResult)

        val requestCaptor = argumentCaptor<DocumentScannerRequest>()
        verify(mockScanner).scanDocuments(
            activity = eq(mockActivity),
            scannerLauncher = eq(mockLauncher),
            result = any(),
            request = requestCaptor.capture(),
        )

        val request = requestCaptor.firstValue
        assertFalse(request.allowGalleryImport)
        assertEquals(5, request.maxPages)
        assertTrue(request.returnJpegs)
        assertTrue(request.returnPdf)
        assertEquals(ScannerModeOption.BASE_WITH_FILTER, request.scannerMode)
    }

    @Test
    fun `onMethodCall scanDocuments with invalid maxPages should return error`() {
        val plugin = SimplestDocumentScannerPlugin()
        val mockResult = mock<Result>()
        val mockActivity = mock<ComponentActivity>()
        val mockLauncher = mock<ActivityResultLauncher<IntentSenderRequest>>()

        plugin.configureForTesting(
            activity = mockActivity,
            launcher = mockLauncher,
        )

        val arguments = mapOf("maxPages" to -1)
        val methodCall = MethodCall("scanDocuments", arguments)

        plugin.onMethodCall(methodCall, mockResult)

        verify(mockResult).error(
            eq("INVALID_ARGUMENT"),
            eq("maxPages must be a positive integer."),
            eq(null),
        )
    }
}
