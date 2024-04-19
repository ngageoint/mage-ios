//
//  ValueAnimator.swift
//  MAGE
//
//  Created by Daniel Barela on 4/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ValueAnimator {
    var displayLink: CADisplayLink?
    let startValue: Double
    let endValue: Double
    let duration: CFTimeInterval
    var startTime: CFTimeInterval = 0
    let callback: ((_ value: Double) -> Void)

    init(
        duration: Double,
        startValue: Double,
        endValue: Double,
        callback: @escaping ((_ value: Double) -> Void)
    ) {
        self.duration = duration
        self.startValue = startValue
        self.endValue = endValue
        self.callback = callback
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: RunLoop.Mode.default)
    }

    @objc func tick() {
        guard let link = displayLink else {
            cleanup()
            return
        }

        if startTime == 0 { // first tick
            startTime = link.timestamp
            return
        }

        let maxTime = startTime + duration
        let currentTime = link.timestamp

        guard currentTime < maxTime else {
            finish()
            return
        }

        let progress = (currentTime - startTime) / duration
        let progressInterval = (endValue - startValue) * Double(progress)

        let normalizedProgress = startValue + progressInterval
        callback(normalizedProgress)
    }

    func finish() {
        callback(endValue)
        cleanup()
    }

    func cleanup() {
        displayLink?.remove(from: .main, forMode: RunLoop.Mode.default)
        displayLink?.invalidate()
        displayLink = nil
        startTime = 0
    }
}
