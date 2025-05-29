//
//  DataFetchOperation.swift
//  Marlin
//
//  Created by Daniel Barela on 2/1/24.
//

import Foundation

enum DataFetchOperationState: String {
    case isReady
    case isExecuting
    case isFinished
}

class DataFetchOperation<DataModel>: Operation {

    var data: [DataModel] = []

    var state: DataFetchOperationState = .isReady {
        willSet(newValue) {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    override var isExecuting: Bool { state == .isExecuting }
    override var isFinished: Bool {
        if isCancelled && state != .isExecuting { return true }
        return state == .isFinished
    }
    override var isAsynchronous: Bool { true }

    override func start() {
        guard !isCancelled else { return }
        state = .isExecuting
        Task {
            let data = await fetchData()
            await self.finishFetch(data: data)
        }
    }

    @MainActor func finishFetch(data: [DataModel]) {
        self.data = data
        self.state = .isFinished
    }

    func fetchData() async -> [DataModel] {
        fatalError("Must be overridden")
    }
}
