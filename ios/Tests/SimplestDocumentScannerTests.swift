import XCTest
@testable import simplest_document_scanner

final class SimplestDocumentScannerTests: XCTestCase {

  func testDocumentScannerRequestParsesDefaults() throws {
    let request = try DocumentScannerRequest(arguments: nil)

    XCTAssertNil(request.maxPages)
    XCTAssertTrue(request.returnJpegs)
    XCTAssertFalse(request.returnPdf)
    XCTAssertEqual(request.jpegQuality, 0.9, accuracy: 0.0001)
    XCTAssertTrue(request.enforceMaxPageLimit)
  }

  func testDocumentScannerRequestRejectsInvalidMaxPages() {
    XCTAssertThrowsError(
      try DocumentScannerRequest(arguments: ["maxPages": -2])
    ) { error in
      XCTAssertEqual(error as? DocumentScannerRequestError, .invalidMaxPages)
    }
  }

  func testDocumentScannerRequestRejectsInvalidQuality() {
    XCTAssertThrowsError(
      try DocumentScannerRequest(arguments: ["jpegQuality": 1.5])
    ) { error in
      XCTAssertEqual(error as? DocumentScannerRequestError, .invalidJpegQuality)
    }
  }
}

