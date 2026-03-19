//
//  ObservationValidationScrollTarget.swift
//  MAGE
//
//  Created by Paul Solt on 3/13/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

/// Used to help with scrolling to target elements onscreen
struct ObservationValidationScrollTarget {
    let offset: CGPoint
    let verticalOffsetBounds: ClosedRange<CGFloat>

    static func topAligned(
        for targetFrame: CGRect,
        contentInset: UIEdgeInsets,
        contentSize: CGSize,
        boundsSize: CGSize,
        topPadding: CGFloat
    ) -> ObservationValidationScrollTarget {
        let minimumOffsetY = -contentInset.top
        let maximumOffsetY = max(minimumOffsetY, contentSize.height - boundsSize.height + contentInset.bottom)
        let verticalOffsetBounds = minimumOffsetY...maximumOffsetY
        let unclampedOffsetY = targetFrame.minY - topPadding
        let targetOffsetY = min(verticalOffsetBounds.upperBound, max(verticalOffsetBounds.lowerBound, unclampedOffsetY))

        return ObservationValidationScrollTarget(
            offset: CGPoint(x: 0, y: targetOffsetY),
            verticalOffsetBounds: verticalOffsetBounds
        )
    }
}
