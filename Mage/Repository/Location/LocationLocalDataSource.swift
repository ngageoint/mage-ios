//
//  LocationLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct LocationLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: LocationLocalDataSource = LocationCoreDataDataSource()
}

extension InjectedValues {
    var locationLocalDataSource: LocationLocalDataSource {
        get { Self[LocationLocalDataSourceProviderKey.self] }
        set { Self[LocationLocalDataSourceProviderKey.self] = newValue }
    }
}

enum URIItem: Hashable, Identifiable {
    var id: String {
        switch self {
        case .listItem(let uri):
            return uri.absoluteString
        case .sectionHeader(let header):
            return header
        }
    }

    case listItem(_ uri: URL)
    case sectionHeader(header: String)
}

protocol LocationLocalDataSource {
    func getLocation(uri: URL) async -> LocationModel?
    func locations(
        userIds: [String]?,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
    func observeLocation(locationUri: URL) -> AnyPublisher<LocationModel, Never>?
    func observeLatest() -> AnyPublisher<Date, Never>?
}

struct URIModelPage {
    var list: [URIItem]
    var next: Int?
    var currentHeader: String?
}

class LocationCoreDataDataSource: CoreDataDataSource, LocationLocalDataSource, ObservableObject {
    private lazy var context: NSManagedObjectContext = {
        NSManagedObjectContext.mr_default()
    }()
    
    func getLocation(uri: URL) async -> LocationModel? {
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) {
                if let location = try? context.existingObject(with: id) as? Location {
                    return LocationModel(location: location)
                }
            }
            return nil
        }
    }
    
    func observeLatest() -> AnyPublisher<Date, Never>? {
        var itemChanges: AnyPublisher<Date, Never> {
            
            let request = Location.fetchRequest()
            let predicates: [NSPredicate] = Locations.getPredicatesForLocations() as? [NSPredicate] ?? []
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.predicate = predicate
            request.includesSubentities = false
            request.propertiesToFetch = ["timestamp"]
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            return context.listPublisher(for: request, transformer: { $0 })
            .catch { _ in Empty() }
            .map({ output in
                output[0].timestamp ?? Date()
            })
            .eraseToAnyPublisher()
        }
        return itemChanges
    }
    
    func observeLocation(locationUri: URL) -> AnyPublisher<LocationModel, Never>? {
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: locationUri) {
                if let location = try? context.existingObject(with: id) as? Location {
                    return publisher(for: location, in: context)
                        .prepend(location)
                        .map({ location in
                            return LocationModel(location: location)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
    
    func locations(
        userIds: [String]? = nil,
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        return locations(
            userIds: userIds,
            at: nil,
            currentHeader: nil,
            paginatedBy: paginator
        )
        .map(\.list)
        .eraseToAnyPublisher()
    }
    
    func locations(
        userIds: [String]? = nil,
        at page: Page?,
        currentHeader: String?,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<URIModelPage, Error> {
        return locations(
            userIds: userIds,
            at: page,
            currentHeader: currentHeader
        )
        .map { result -> AnyPublisher<URIModelPage, Error> in
            if let paginator = paginator, let next = result.next {
                return self.locations(
                    userIds: userIds,
                    at: next,
                    currentHeader: result.currentHeader,
                    paginatedBy: paginator
                )
                .wait(untilOutputFrom: paginator)
                .retry(.max)
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
    
    func locations(
        userIds: [String]? = nil,
        at page: Page?,
        currentHeader: String?
    ) -> AnyPublisher<URIModelPage, Error> {

        let request = Location.fetchRequest()
        let predicates: [NSPredicate] = {
            if let userids = userIds {
                return [
                    NSPredicate(format: "user.remoteId IN %@", userIds!)
                ]
            } else {
                return Locations.getPredicatesForLocations() as? [NSPredicate] ?? []
            }
        }()
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.predicate = predicate

        request.includesSubentities = false
        request.fetchLimit = 100
        request.fetchOffset = (page ?? 0) * request.fetchLimit
        request.propertiesToFetch = ["timestamp"]
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let previousHeader: String? = currentHeader
        var uris: [URIItem] = []
        context.performAndWait {
            if let fetched = context.fetch(request: request) {

                uris = fetched.flatMap { user in
                    return [URIItem.listItem(user.objectID.uriRepresentation())]
                }
            }
        }

        let page: URIModelPage = URIModelPage(
            list: uris,
            next: (page ?? 0) + 1,
            currentHeader: previousHeader
        )

        return Just(page)
            .setFailureType(to: Error.self)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
