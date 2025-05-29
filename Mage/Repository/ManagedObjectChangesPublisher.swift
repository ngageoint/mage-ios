//
//  ManagedObjectChangesPublisher.swift
//  Marlin
//
//  imported from https://gist.github.com/mjm/750b20e1dfd5b1abc82b8295b54b3c74
//

import Foundation
import Combine
import CoreData

struct Trigger {
    typealias Index = Int
    typealias Signal = AnyPublisher<Void, Never>

    private let sender = PassthroughSubject<Index, Never>()

    func signal(activatedBy index: Index) -> Signal {
        return sender
            .filter { $0 == index }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func activate(for index: Index) {
        sender.send(index)
    }
}

extension Trigger {
    func signal<T>(activatedBy trigger: T) -> Signal where T: Hashable {
        return signal(activatedBy: trigger.hashValue)
    }

    func activate<T>(for trigger: T) where T: Hashable {
        activate(for: trigger.hashValue)
    }
}

extension Publisher {
    func wait<S>(untilOutputFrom signal: S
    ) -> AnyPublisher<Self.Output, Self.Failure> where S: Publisher, S.Failure == Never {
        return prepend(
            Empty(completeImmediately: false)
                .prefix(untilOutputFrom: signal)
        )
        .eraseToAnyPublisher()
    }
}

// This is the naming convention of publishers even though these are not structs
// swiftlint:disable identifier_name
extension Publishers {
    static func Publish<S, P>(
        onOutputFrom signal: S,
        _ publisher: @escaping () -> P
    ) -> AnyPublisher<P.Output, P.Failure> where S: Publisher, P: Publisher, S.Failure == Never {
        return signal
            .map { _ in }
            .map { _ in
                return publisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    static func PublishAndRepeat<S, P>(
        onOutputFrom signal: S,
        _ publisher: @escaping () -> P
    ) -> AnyPublisher<P.Output, P.Failure> where S: Publisher, P: Publisher, S.Failure == Never {
        return signal
            .map { _ in }
            .prepend(())
            .map { _ in
                return publisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
// swiftlint:enable identifier_name

extension NSManagedObjectContext {
    func changesPublisher<Object: NSManagedObject, TransformedObject: Equatable>(
        for fetchRequest: NSFetchRequest<Object>,
        transformer: @escaping (Object) -> TransformedObject
    ) -> ManagedObjectChangesPublisher<Object, TransformedObject> {
        ManagedObjectChangesPublisher(fetchRequest: fetchRequest, context: self, transformer: transformer)
    }
}

struct ManagedObjectChangesPublisher<Object: NSManagedObject, TransformedObject: Equatable>: Publisher {
    typealias Output = CollectionDifference<TransformedObject>
    typealias Failure = Error

    let fetchRequest: NSFetchRequest<Object>
    let context: NSManagedObjectContext
    let transformer: (Object) -> TransformedObject

    init(
        fetchRequest: NSFetchRequest<Object>,
        context: NSManagedObjectContext,
        transformer: @escaping (Object) -> TransformedObject
    ) {
        self.fetchRequest = fetchRequest
        self.context = context
        self.transformer = transformer
    }

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let inner = Inner(
            downstream: subscriber,
            fetchRequest: fetchRequest,
            context: context,
            transformer: transformer
        )
        subscriber.receive(subscription: inner)
    }

    private final class Inner<Downstream: Subscriber>: NSObject, Subscription,
                                                       NSFetchedResultsControllerDelegate
    where Downstream.Input == CollectionDifference<TransformedObject>, Downstream.Failure == Error {
        private let downstream: Downstream
        private var fetchedResultsController: NSFetchedResultsController<Object>?
        private let transformer: (Object) -> TransformedObject
        init(
            downstream: Downstream,
            fetchRequest: NSFetchRequest<Object>,
            context: NSManagedObjectContext,
            transformer: @escaping (Object) -> TransformedObject
        ) {
            self.transformer = transformer
            self.downstream = downstream
            fetchedResultsController
            = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)

            super.init()

            fetchedResultsController!.delegate = self

            do {
                try fetchedResultsController!.performFetch()
                updateDiff()
            } catch {
                downstream.receive(completion: .failure(error))
            }
        }

        private var demand: Subscribers.Demand = .none

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private var firstTime: Bool = true
        private var lastSentState: [TransformedObject] = []
        private var currentDifferences = CollectionDifference<TransformedObject>([])!

        private func updateDiff() {
            currentDifferences
            = Array(fetchedResultsController?.fetchedObjects ?? []).map(transformer).difference(
                from: lastSentState)
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 && (!currentDifferences.isEmpty || firstTime) {
                firstTime = false
                let newDemand = downstream.receive(currentDifferences)
                lastSentState = Array(fetchedResultsController?.fetchedObjects ?? []).map(transformer)
                currentDifferences = lastSentState.difference(from: lastSentState)

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        }

        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            updateDiff()
        }

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}

extension NSManagedObjectContext {
    func listPublisher<Object: NSManagedObject, TransformedObject: Equatable>(
        for fetchRequest: NSFetchRequest<Object>,
        transformer: @escaping (Object) -> TransformedObject
    ) -> ManagedObjectListPublisher<Object, TransformedObject> {
        ManagedObjectListPublisher(fetchRequest: fetchRequest, context: self, transformer: transformer)
    }
}

struct ManagedObjectListPublisher<Object: NSManagedObject, TransformedObject: Equatable>: Publisher {
    typealias Output = Array<TransformedObject>
    typealias Failure = Error

    let fetchRequest: NSFetchRequest<Object>
    let context: NSManagedObjectContext
    let transformer: (Object) -> TransformedObject

    init(
        fetchRequest: NSFetchRequest<Object>,
        context: NSManagedObjectContext,
        transformer: @escaping (Object) -> TransformedObject
    ) {
        self.fetchRequest = fetchRequest
        self.context = context
        self.transformer = transformer
    }

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let inner = Inner(
            downstream: subscriber,
            fetchRequest: fetchRequest,
            context: context,
            transformer: transformer
        )
        subscriber.receive(subscription: inner)
    }

    private final class Inner<Downstream: Subscriber>: NSObject, Subscription,
                                                       NSFetchedResultsControllerDelegate
    where Downstream.Input == Array<TransformedObject>, Downstream.Failure == Error {
        private let downstream: Downstream
        private var fetchedResultsController: NSFetchedResultsController<Object>?
        private let transformer: (Object) -> TransformedObject
        init(
            downstream: Downstream,
            fetchRequest: NSFetchRequest<Object>,
            context: NSManagedObjectContext,
            transformer: @escaping (Object) -> TransformedObject
        ) {
            self.transformer = transformer
            self.downstream = downstream
            fetchedResultsController
            = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)

            super.init()

            fetchedResultsController!.delegate = self

            do {
                try fetchedResultsController!.performFetch()
                updateDiff()
            } catch {
                downstream.receive(completion: .failure(error))
            }
        }

        private var demand: Subscribers.Demand = .none

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private var firstTime: Bool = true
        private var lastSentState: [TransformedObject] = []
        private var currentList = Array<TransformedObject>()

        private func updateDiff() {
            currentList
            = Array(fetchedResultsController?.fetchedObjects ?? []).map(transformer)
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 && (!currentList.isEmpty || firstTime) {
                firstTime = false
                let newDemand = downstream.receive(currentList)
                lastSentState = Array(fetchedResultsController?.fetchedObjects ?? []).map(transformer)
//                currentDifferences = lastSentState.difference(from: lastSentState)

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        }

        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            updateDiff()
        }

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}
