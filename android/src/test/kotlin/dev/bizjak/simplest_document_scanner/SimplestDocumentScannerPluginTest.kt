package dev.bizjak.simplest_document_scanner

import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
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
        // Arrange
        val plugin = SimplestDocumentScannerPlugin()
        val mockResult = mock<Result>()

        // Act
        plugin.onMethodCall(MethodCall("scanDocuments", null), mockResult)

        // Assert
        verify(mockResult).error("NO_ACTIVITY", "No activity is attached to the plugin", null)
    }

    @Test
    fun `onMethodCall scanDocuments with valid arguments should call scanner`() {
        // Arrange
        val plugin = SimplestDocumentScannerPlugin()
        val mockScanner = mock<MLKitDocumentScanner>()
        val mockActivity = mock<ComponentActivity>()
        plugin.activity = mockActivity
        plugin.mlKitDocumentScanner = mockScanner

        val arguments = mapOf(
            "galleryImportAllowed" to false,
            "scannerMode" to 1,
            "maxNumberOfPages" to 5
        )
        val methodCall = MethodCall("scanDocuments", arguments)
        val mockResult = mock<Result>()

        // Act
        plugin.onMethodCall(methodCall, mockResult)

        // Assert
        verify(mockScanner).scanDocuments(
            eq(mockActivity),
            eq(mockResult),
            eq(false),
            eq(1),
            eq(5)
        )
    }

    @Test
    fun `onMethodCall scanDocuments with invalid maxNumberOfPages should return error`() {
        // Arrange
        val plugin = SimplestDocumentScannerPlugin()
        val mockActivity = mock<ComponentActivity>()
        plugin.activity = mockActivity

        val arguments = mapOf("maxNumberOfPages" to -1)
        val methodCall = MethodCall("scanDocuments", arguments)
        val mockResult = mock<Result>()

        // Act
        plugin.onMethodCall(methodCall, mockResult)

        // Assert
        verify(mockResult).error("INVALID_ARGUMENT", "maxNumberOfPages must be a positive integer", null)
    }
}
