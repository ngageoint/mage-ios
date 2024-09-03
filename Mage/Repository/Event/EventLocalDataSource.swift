//
//  EventLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct EventLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: EventLocalDataSource = EventCoreDataDataSource()
}

extension InjectedValues {
    var eventLocalDataSource: EventLocalDataSource {
        get { Self[EventLocalDataSourceProviderKey.self] }
        set { Self[EventLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol EventLocalDataSource {
    func getEvent(eventId: NSNumber) -> EventModel?
    func handleEventsResponse(response: [[AnyHashable: Any]]) async
}

class EventCoreDataDataSource: CoreDataDataSource<Event>, EventLocalDataSource, ObservableObject {
    @Injected(\.teamLocalDataSource)
    var teamLocalDataSource: TeamLocalDataSource
    
    func getEvent(eventId: NSNumber) -> EventModel? {
        guard let context = context else { return nil }
        return context.performAndWait {
            if let event = context.fetchFirst(Event.self, key: EventKey.remoteId.key, value: eventId) {
                return EventModel(event: event)
            }
            return nil
        }
    }
    
    func insertOrUpdate(json: [AnyHashable: Any]) -> Event? {
        guard let remoteId = json[EventKey.id.key] as? NSNumber,
              let context = context
        else {
            return nil
        }
        return context.performAndWait {
            let event = context.fetchFirst(Event.self, key: EventKey.remoteId.key, value: remoteId) ?? Event(context: context)
            event.remoteId = json[EventKey.id.key] as? NSNumber
            event.name = json[EventKey.name.key] as? String
            event.maxObservationForms = json[EventKey.maxObservationForms.key] as? NSNumber
            event.minObservationForms = json[EventKey.minObservationForms.key] as? NSNumber
            event.eventDescription = json[EventKey.description.key] as? String
            event.acl = AFJSONObjectByRemovingKeysWithNullValues(json[EventKey.acl.key] ?? [:], .allowFragments) as? [AnyHashable : Any]
            
            let formsJson = AFJSONObjectByRemovingKeysWithNullValues(json[EventKey.forms.key] ?? [[:]], .allowFragments) as? [[AnyHashable : Any]]
            
            Form.deleteAndRecreateForms(eventId: remoteId, formsJson: formsJson ?? [], context: context)
            if let responseTeams = json[EventKey.teams.key] as? [[AnyHashable : Any]] {
                for teamJson in responseTeams {
                    if let team = teamLocalDataSource.updateOrInsert(json: teamJson) {
                        event.addToTeams(team)
                    }
                }
            }
            // TODO: This should be handled by the caller that passed in the json
            if let layers = json[EventKey.layers.key] as? [[AnyHashable:Any]], let remoteId = event.remoteId {
                Layer.populateLayers(json: layers, eventId: remoteId, context: context);
            }
            if let remoteId = event.remoteId {
                Feed.refreshFeeds(eventId: remoteId)
            }
            try? context.save()
            return event
        }
    }
    
    func handleEventsResponse(response: [[AnyHashable: Any]]) async {
        guard let context = context else {
            return
        }
        
        await context.perform {
            var eventsReturned: [NSNumber] = []
            let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: UserDefaults.standard.currentUserId ?? "")
            for eventJson in response {
                if let eventId = eventJson[EventKey.id.key] as? NSNumber {
                    let event = self.insertOrUpdate(json: eventJson)
                    if let recentEventIds = user?.recentEventIds, let remoteId = event?.remoteId {
                        event?.recentSortOrder = NSNumber(value: recentEventIds.firstIndex(of: remoteId) ?? 0)
                    }
                    if let remoteId = event?.remoteId {
                        eventsReturned.append(remoteId)
                    }
                }
            }
            
            // delete the events not returned
            let eventsToDelete = try? context.fetchObjects(Event.self, predicate: NSPredicate(format: "NOT (\(EventKey.remoteId.key) IN %@)", eventsReturned))
            for event in eventsToDelete ?? [] {
                context.delete(event)
            }
            
            try? context.save()
            
            // TODO: this shouldn't matter as we should be observing the repository at some point
            NotificationCenter.default.post(name: .MAGEEventsFetched, object:nil)
        }
    }
}
