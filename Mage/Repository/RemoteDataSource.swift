//
//  RemoteDataSource.swift
//  Marlin
//
//  Created by Daniel Barela on 2/2/24.
//

import Foundation
import UIKit
import BackgroundTasks
import DataSourceDefinition

class RemoteDataSource<T> {
    var dataSource: any DataSourceDefinition
    var cleanup: (() -> Void)?
    var operation: DataFetchOperation<T>?

    init(dataSource: any DataSourceDefinition, cleanup: (() -> Void)? = nil) {
        self.dataSource = dataSource
        self.cleanup = cleanup
    }

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    lazy var backgroundFetchQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "\(dataSource.name) fetch queue"
        return queue
    }()

    func registerBackgroundTask(name: String) {
        MageLogger.misc.debug("Register the background task \(name)")
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            MageLogger.misc.debug("iOS has signaled time has expired \(name)")
            self?.cleanup?()
            MageLogger.misc.debug("canceling \(name)")
            self?.operation?.cancel()
            MageLogger.misc.debug("calling endBackgroundTask \(name)")
            self?.endBackgroundTaskIfActive()
        }
    }

    func endBackgroundTaskIfActive() {
        let isBackgroundTaskActive = backgroundTask != .invalid
        if isBackgroundTaskActive {
            MageLogger.misc.debug("Background task ended. \(String(describing: self.dataSource.name)) Fetch")
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    @discardableResult
    func fetch(task: BGTask? = nil, operation: DataFetchOperation<T>) async -> [T] {
        self.operation = operation
        if let task = task {
            registerBackgroundTask(name: task.identifier)
            guard backgroundTask != .invalid else { return [] }
        }

        // Provide the background task with an expiration handler that cancels the operation.
        task?.expirationHandler = {
            self.operation?.cancel()
        }

        MageLogger.misc.debug("Start the operation to fetch new data \(operation)")
        // Start the operation.
        self.backgroundFetchQueue.addOperation(operation)

        return await withCheckedContinuation { continuation in
            // Inform the system that the background task is complete
            // when the operation completes.
            operation.completionBlock = {
                task?.setTaskCompleted(success: !(self.operation?.isCancelled ?? false))
                MageLogger.misc.debug("\(self.dataSource.name) Remote Data Source count \(self.operation?.data.count ?? 0)")
                continuation.resume(returning: self.operation?.data ?? [])
            }
        }
    }
}
