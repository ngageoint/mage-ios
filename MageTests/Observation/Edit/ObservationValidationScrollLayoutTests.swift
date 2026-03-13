//
//  ObservationValidationScrollLayoutTests.swift
//  MAGETests
//
//  Created by Codex on 3/12/26.
//

import XCTest

@testable import MAGE

final class ObservationValidationScrollLayoutTests: XCTestCase {
    func testTargetOffsetAlignsFieldNearTopPadding() {
        let targetOffset = ObservationValidationScrollTarget.topAligned(
            for: CGRect(x: 24, y: 518, width: 382, height: 86),
            contentInset: .zero,
            contentSize: CGSize(width: 430, height: 2273.6666666666665),
            boundsSize: CGSize(width: 430, height: 786),
            topPadding: 16
        ).offset

        XCTAssertEqual(targetOffset.x, 0)
        XCTAssertEqual(targetOffset.y, 502, accuracy: 0.001)
    }

    func testTargetOffsetClampsToBottomWhenLastFormCannotReachTopPadding() {
        let targetOffset = ObservationValidationScrollTarget.topAligned(
            for: CGRect(x: 24, y: 1914, width: 382, height: 86),
            contentInset: .zero,
            contentSize: CGSize(width: 430, height: 2271),
            boundsSize: CGSize(width: 430, height: 785),
            topPadding: 16
        ).offset

        XCTAssertEqual(targetOffset.x, 0)
        XCTAssertEqual(targetOffset.y, 1486, accuracy: 0.001)
    }

    func testTargetOffsetClampsToTopForEarlyFields() {
        let targetOffset = ObservationValidationScrollTarget.topAligned(
            for: CGRect(x: 24, y: 10, width: 382, height: 86),
            contentInset: .zero,
            contentSize: CGSize(width: 430, height: 1500),
            boundsSize: CGSize(width: 430, height: 785),
            topPadding: 16
        ).offset

        XCTAssertEqual(targetOffset.x, 0)
        XCTAssertEqual(targetOffset.y, 0, accuracy: 0.001)
    }

    func testTargetOffsetRespectsAdjustedInsetAtTop() {
        let targetOffset = ObservationValidationScrollTarget.topAligned(
            for: CGRect(x: 24, y: 20, width: 382, height: 86),
            contentInset: UIEdgeInsets(top: 20, left: 0, bottom: 34, right: 0),
            contentSize: CGSize(width: 430, height: 1400),
            boundsSize: CGSize(width: 430, height: 785),
            topPadding: 16
        ).offset

        XCTAssertEqual(targetOffset.x, 0)
        XCTAssertEqual(targetOffset.y, 4, accuracy: 0.001)
    }
}
