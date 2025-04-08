//
//  CoreDataDataSource.swift
//  Marlin
//
//  Created by Daniel Barela on 12/21/23.
//

import Foundation
import UIKit
import BackgroundTasks
import CoreData
import Combine

class CoreDataDataSource<T: NSManagedObject>: NSObject {
    @Injected(\.persistence)
    var persistence: Persistence
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    typealias Page = Int

    var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var cleanup: (() -> Void)?
    var operation: CountingDataLoadOperation?
    
    var fetchLimit: Int = 100
    
    func getFetchRequest(parameters: [AnyHashable: Any]? = nil) -> NSFetchRequest<T> {
        preconditionFailure("This method must be overridden")
    }

    func registerBackgroundTask(name: String) {
        NSLog("Register the background task \(name)")
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
            MageLogger.misc.debug("Background task ended. \(NSStringFromClass(type(of: self))) Load")
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    func publisher(
        for managedObject: T,
        in context: NSManagedObjectContext
    ) -> AnyPublisher<T, Never> {
        let notification = NSManagedObjectContext.didSaveObjectsNotification
        return NotificationCenter.default.publisher(for: notification) //, object: context)
            .compactMap({ notification in
                if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                   let updatedObject = updated.first(where: { object in
                       object.objectID == managedObject.objectID
                   }) as? T {
                    return updatedObject
                } else {
                    return nil
                }
            })
            .eraseToAnyPublisher()
    }
    
    func uris(
        parameters: [AnyHashable: Any]? = nil,
        at page: Page?,
        currentHeader: String?,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<URIModelPage, Error> {
        return uris(
            parameters: parameters,
            at: page,
            currentHeader: currentHeader
        )
        .map { result -> AnyPublisher<URIModelPage, Error> in
            if let paginator = paginator, let next = result.next {
                return Publishers.Publish(onOutputFrom: paginator) {
                    return self.uris(
                        parameters: parameters,
                        at: next,
                        currentHeader: result.currentHeader,
                        paginatedBy: paginator
                    )
                    .eraseToAnyPublisher()
                }
                .prepend(result)
                .eraseToAnyPublisher()
            } else {
                return Just(result)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func uris(
        parameters: [AnyHashable: Any]? = nil,
        at page: Page?,
        currentHeader: String?
    ) -> AnyPublisher<URIModelPage, Error> {
        let request = getFetchRequest(parameters: parameters)
        request.fetchLimit = fetchLimit
        request.fetchOffset = (page ?? 0) * request.fetchLimit
        MageLogger.misc.debug("XXX request \(request)")
        let previousHeader: String? = currentHeader
        var users: [URIItem] = []
        context?.performAndWait {
            if let fetched = context?.fetch(request: request) {

                users = fetched.flatMap { user in
                    return [URIItem.listItem(user.objectID.uriRepresentation())]
                }
            }
        }

        let page: URIModelPage = URIModelPage(
            list: users,
            next: (page ?? 0) + 1,
            currentHeader: previousHeader
        )

        return Just(page)
            .setFailureType(to: Error.self)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func executeOperationInBackground(task: BGTask? = nil) async -> Int {
        if let task = task {
            registerBackgroundTask(name: task.identifier)
            guard backgroundTask != .invalid else { return 0 }
        }

        // Provide the background task with an expiration handler that cancels the operation.
        task?.expirationHandler = {
            self.operation?.cancel()
        }

        // Start the operation.
        if let operation = operation {
            MageSession.shared.backgroundLoadQueue.addOperation(operation)
        }

        return await withCheckedContinuation { continuation in
            // Inform the system that the background task is complete
            // when the operation completes.
            operation?.completionBlock = {
                task?.setTaskCompleted(success: !(self.operation?.isCancelled ?? false))
                continuation.resume(returning: self.operation?.count ?? 0)
            }
        }
    }
}
