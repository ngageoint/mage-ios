//
//  Event.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objc public class Event: NSManagedObject {
    
    @objc public static func operationToFetchEvents(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/events";
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MagicalRecord.save { localContext in
                let localUser = User.fetchCurrentUser(context: localContext);
                var eventsReturned: [NSNumber] = []
                
                guard let events = responseObject as? [[AnyHashable : Any]] else {
                    success?(task, nil);
                    return;
                }
                for eventJson in events {
                    if let eventId = eventJson[EventKey.id.key] as? NSNumber, let event = Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: eventId, in: localContext) {
                        event.updateEvent(json: eventJson, context: localContext);
                        if let recentEventIds = localUser?.recentEventIds, let remoteId = event.remoteId {
                            event.recentSortOrder = NSNumber(value: recentEventIds.firstIndex(of: remoteId) ?? 0)
                        }
                        if let remoteId = event.remoteId {
                            eventsReturned.append(remoteId)
                        }
                    } else {
                        if let event = Event.insertEvent(json: eventJson, context: localContext) {
                            if let recentEventIds = localUser?.recentEventIds, let remoteId = event.remoteId {
                                event.recentSortOrder = NSNumber(value: recentEventIds.firstIndex(of: remoteId) ?? 0)
                            }
                            if let remoteId = event.remoteId {
                                eventsReturned.append(remoteId)
                            }
                        }
                    }
                }
                Event.mr_deleteAll(matching: NSPredicate(format: "NOT (\(EventKey.remoteId.key) IN %@)", eventsReturned), in: localContext);
            } completion: { contextDidSave, error in
                NotificationCenter.default.post(name: .MAGEEventsFetched, object:nil)

                if let error = error {
                    if let failure = failure {
                        failure(task, error);
                    }
                } else if let success = success {
                    success(task, nil);
                }
            }

        }, failure: { task, error in
            if let failure = failure {
                failure(task, error);
            }
        });
        return task;
    }
    
    @objc public static func sendRecentEvent() {
        guard let u = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()), let baseURL = MageServer.baseURL() else {
            return;
        }
        let manager = MageSessionManager.shared();
        guard let currentEventId = Server.currentEventId(), let task: URLSessionDataTask = manager?.post_TASK("\(baseURL.absoluteURL)/api/users/\(u.remoteId ?? "")/events/\(currentEventId)/recent", parameters: nil, progress: nil, success: { task, response in
            
        }, failure: { task, error in
            print("Error posting recent event")
        }) else {
            return
        }
        manager?.addTask(task)
    }
    
    @objc public static func getCurrentEvent(context: NSManagedObjectContext) -> Event? {
        if let currentEventId = Server.currentEventId() {
            return Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: currentEventId, in: context);
        }
        return nil;
    }
    
    @objc public static func getEvent(eventId: NSNumber, context: NSManagedObjectContext) -> Event? {
        return Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: eventId, in: context);
    }
    
    @objc public static func caseInsensitiveSortFetchAll(sortTerm: String?, ascending: Bool, predicate: NSPredicate?, groupBy: String?, context: NSManagedObjectContext) -> NSFetchedResultsController<Event>? {
        guard let request = Event.mr_requestAll(in: context) as? NSFetchRequest<Event> else {
            return nil;
        }
        request.predicate = predicate;
        request.includesSubentities = false;
        
        if let sortTerm = sortTerm {
            let sortBy = NSSortDescriptor(key: sortTerm, ascending: ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare));
            request.sortDescriptors = [sortBy];
        }
        return NSFetchedResultsController<Event>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: groupBy, cacheName: nil);
    }
    
    static func insertEvent(json: [AnyHashable : Any], context: NSManagedObjectContext) -> Event? {
        let event = Event.mr_createEntity(in: context)
        event?.updateEvent(json: json, context: context);
        return event;
    }
    
    func updateEvent(json: [AnyHashable : Any], context: NSManagedObjectContext) {
        self.remoteId = json[EventKey.id.key] as? NSNumber
        self.name = json[EventKey.name.key] as? String
        self.maxObservationForms = json[EventKey.maxObservationForms.key] as? NSNumber
        self.minObservationForms = json[EventKey.minObservationForms.key] as? NSNumber
        self.eventDescription = json[EventKey.description.key] as? String
        self.acl = AFJSONObjectByRemovingKeysWithNullValues(json[EventKey.acl.key] ?? [:], .allowFragments) as? [AnyHashable : Any]
        
        let formsJson = AFJSONObjectByRemovingKeysWithNullValues(json[EventKey.forms.key] ?? [[:]], .allowFragments) as? [[AnyHashable : Any]]
        if let remoteId = remoteId {
            Form.deleteAndRecreateForms(eventId: remoteId, formsJson: formsJson ?? [], context: context)
        }        
        if let responseTeams = json[EventKey.teams.key] as? [[AnyHashable : Any]] {
            for teamJson in responseTeams {
                if let team = self.teams?.first(where: { team in
                    return team.remoteId == teamJson[TeamKey.id.key] as? String
                }) {
                    team.update(json: teamJson, context: context);
                } else {
                    if let teamId = teamJson[TeamKey.id.key] as? String, let team = Team.mr_findFirst(byAttribute: TeamKey.remoteId.key, withValue: teamId, in: context) {
                        team.update(json: teamJson, context: context);
                        self.addToTeams(team);
                    } else {
                        if let team = Team.insert(json: teamJson, context: context) {
                            self.addToTeams(team);
                        }
                    }
                }
            }
        }
        if let layers = json[EventKey.layers.key] as? [[AnyHashable:Any]], let remoteId = remoteId {
            Layer.populateLayers(json: layers, eventId: remoteId, context: context);
        }
        if let remoteId = remoteId {
            Feed.refreshFeeds(eventId: remoteId)
        }
    }
    
    @objc public func isUserInEvent(user: User?) -> Bool {
        guard let user = user, let teams = teams else {
            return false;
        }
        for team in teams {
            if let users = team.users {
                if users.contains(user) {
                    return true;
                }
            }
        }
        print("User \(user.name ?? "") is not in the event \(self.name ?? "")");
        return false;
    }
    
    @objc public func form(observation: Observation) -> Form? {
        return observation.primaryEventForm;
    }
    
    @objc public func form(id: NSNumber?) -> Form? {
        guard let id = id, let managedObjectContext = self.managedObjectContext else {
            return nil
        }
        return Form.mr_findFirst(byAttribute: "formId", withValue: id, in: managedObjectContext)
    }
    
    @objc public var forms: [Form]? {
        get {
            guard let managedObjectContext = managedObjectContext, let remoteId = remoteId else {
                return nil
            }
            return Form.mr_findAllSorted(by: "formId", ascending: true, with: NSPredicate(format: "eventId == %@", remoteId), in: managedObjectContext) as? [Form]
        }
    }
    
    @objc public var nonArchivedForms: [Form]? {
        get {
            guard let managedObjectContext = managedObjectContext, let remoteId = remoteId else {
                return nil
            }
            return Form.mr_findAllSorted(by: "formId", ascending: true, with: NSPredicate(format: "eventId == %@ AND \(FormKey.archived.key) == false", remoteId), in: managedObjectContext) as? [Form]
        }
    }
}
