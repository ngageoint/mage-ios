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
    func observeLatestFiltered() -> AnyPublisher<Date, Never>?
}

struct URIModelPage {
    var list: [URIItem]
    var next: Int?
    var currentHeader: String?
}

class LocationCoreDataDataSource: CoreDataDataSource<Location>, LocationLocalDataSource, ObservableObject {
    private enum FilterKeys: String {
        case userIds
    }
    
    func getLocation(uri: URL) async -> LocationModel? {
        guard let context = context else { return nil }
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) {
                if let location = try? context.existingObject(with: id) as? Location {
                    return LocationModel(location: location)
                }
            }
            return nil
        }
    }
    
    func observeLatestFiltered() -> AnyPublisher<Date, Never>? {
        guard let context = context else { return nil }
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
                .compactMap { output in
                    output.first?.timestamp
                }
                .eraseToAnyPublisher()
        }
        return itemChanges
    }
    
    func observeLocation(locationUri: URL) -> AnyPublisher<LocationModel, Never>? {
        guard let context = context else { return nil }
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
    
    override func getFetchRequest(parameters: [AnyHashable: Any]? = nil) -> NSFetchRequest<Location> {
        let request = Location.fetchRequest()
        let predicates: [NSPredicate] = {
            if let userIds = parameters?[FilterKeys.userIds] as? [String] {
                return [
                    NSPredicate(format: "%K IN %@", #keyPath(Location.user.remoteId), userIds)
                ]
            } else {
                return Locations.getPredicatesForLocations() as? [NSPredicate] ?? []
            }
        }()
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.predicate = predicate

        request.includesSubentities = false
        request.propertiesToFetch = ["timestamp"]
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    func locations(
        userIds: [String]? = nil,
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        if let userIds = userIds {
            return uris(
                parameters: [FilterKeys.userIds: userIds],
                at: nil,
                currentHeader: nil,
                paginatedBy: paginator
            )
            .map(\.list)
            .eraseToAnyPublisher()
        } else {
            return uris(
                at: nil,
                currentHeader: nil,
                paginatedBy: paginator
            )
            .map(\.list)
            .eraseToAnyPublisher()
        }
    }
}
