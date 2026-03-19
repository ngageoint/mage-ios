//
//  ObservationImportProgress.swift
//  MAGE
//
//  Created by OpenAI Codex on 3/12/26.
//

import Foundation

extension Notification.Name {
    static let ObservationImportProgress = Notification.Name("ObservationImportProgress")
}

enum ObservationImportProgressState: String {
    case indeterminate
    case progress
    case finished
}

enum ObservationImportProgress {
    static let stateKey = "state"
    static let currentKey = "current"
    static let totalKey = "total"
    static let messageKey = "message"

    static func postIndeterminate(message: String) {
        post(state: .indeterminate, current: nil, total: nil, message: message)
    }

    static func postProgress(current: Int, total: Int, message: String) {
        post(state: .progress, current: current, total: total, message: message)
    }

    static func postFinished(message: String? = nil) {
        post(state: .finished, current: nil, total: nil, message: message)
    }

    private static func post(state: ObservationImportProgressState, current: Int?, total: Int?, message: String?) {
        var userInfo: [String: Any] = [
            stateKey: state.rawValue
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
            NotificationCenter.default.post(name: .ObservationImportProgress, object: nil, userInfo: userInfo)
        }
    }
}
