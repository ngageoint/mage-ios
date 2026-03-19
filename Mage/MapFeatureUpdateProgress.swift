//
//  MapFeatureUpdateProgress.swift
//  MAGE
//
//  Created by OpenAI Codex on 3/12/26.
//

import Foundation

extension Notification.Name {
    static let MapFeatureUpdateProgress = Notification.Name("MapFeatureUpdateProgress")
}

enum MapFeatureUpdateProgressState: String {
    case indeterminate
    case progress
    case finished
}

enum MapFeatureUpdateOperation: String {
    case addAnnotations
    case removeAnnotations
    case addOverlays
    case removeOverlays
}

enum MapFeatureUpdateProgress {
    static let stateKey = "state"
    static let operationKey = "operation"
    static let dataSourceKey = "dataSourceKey"
    static let currentKey = "current"
    static let totalKey = "total"
    static let messageKey = "message"

    static func postIndeterminate(
        operation: MapFeatureUpdateOperation,
        dataSourceKey: String,
        message: String? = nil
    ) {
        post(state: .indeterminate, operation: operation, dataSourceKey: dataSourceKey, current: nil, total: nil, message: message)
    }

    static func postProgress(
        operation: MapFeatureUpdateOperation,
        dataSourceKey: String,
        current: Int,
        total: Int,
        message: String? = nil
    ) {
        post(state: .progress, operation: operation, dataSourceKey: dataSourceKey, current: current, total: total, message: message)
    }

    static func postFinished(
        operation: MapFeatureUpdateOperation,
        dataSourceKey: String,
        message: String? = nil
    ) {
        post(state: .finished, operation: operation, dataSourceKey: dataSourceKey, current: nil, total: nil, message: message)
    }

    private static func post(
        state: MapFeatureUpdateProgressState,
        operation: MapFeatureUpdateOperation,
        dataSourceKey: String,
        current: Int?,
        total: Int?,
        message: String?
    ) {
        var userInfo: [String: Any] = [
            stateKey: state.rawValue,
            operationKey: operation.rawValue,
            dataSourceKey: dataSourceKey
        ]
        if let current {
            userInfo[currentKey] = current
        }
        if let total {
            userInfo[totalKey] = total
        }
        if let message {
            userInfo[messageKey] = message
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .MapFeatureUpdateProgress, object: nil, userInfo: userInfo)
        }
    }
}
