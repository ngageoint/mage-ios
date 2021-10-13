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
        let url = "\(MageServer.baseURL().absoluteURL)/api/events";
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MagicalRecord.save { localContext in
                let localUser = User.fetchCurrentUser(in: localContext);
                var eventsReturned: [NSNumber] = []
                
                guard let events = responseObject as? [[AnyHashable : Any]] else {
                    return;
                }
                for eventJson in events {
                    if let eventId = eventJson["id"] as? NSNumber, let event = Event.mr_findFirst(byAttribute: "remoteId", withValue: eventId, in: localContext) {
                        event.updateEvent(json: eventJson, context: localContext);
                        if let recentEventIds = localUser.recentEventIds as? [NSNumber], let remoteId = event.remoteId {
                            event.recentSortOrder = NSNumber(value: recentEventIds.firstIndex(of: remoteId) ?? 0)
                        }
                        if let remoteId = event.remoteId {
                            eventsReturned.append(remoteId)
                        }
                    } else {
                        if let event = Event.insertEvent(json: eventJson, context: localContext) {
                            if let recentEventIds = localUser.recentEventIds as? [NSNumber], let remoteId = event.remoteId {
                                event.recentSortOrder = NSNumber(value: recentEventIds.firstIndex(of: remoteId) ?? 0)
                            }
                            if let remoteId = event.remoteId {
                                eventsReturned.append(remoteId)
                            }
                        }
                    }
                }
                Event.mr_deleteAll(matching: NSPredicate(format: "NOT (remoteId IN %@)", eventsReturned), in: localContext);
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
        let u = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default());
        let manager = MageSessionManager.shared();
        guard let task: URLSessionDataTask = manager?.post_TASK("\(MageServer.baseURL().absoluteURL)/api/users/\(u.remoteId ?? "")/events/\(Server.currentEventId())/recent", parameters: nil, progress: nil, success: { task, response in
            
        }, failure: { task, error in
            print("Error posting recent event")
        }) else {
            return
        }
        manager?.addTask(task)
    }
    
    @objc public static func getCurrentEvent(context: NSManagedObjectContext) -> Event? {
        return Event.mr_findFirst(byAttribute: "remoteId", withValue: Server.currentEventId(), in: context);
    }
    
    @objc public static func getEvent(eventId: NSNumber, context: NSManagedObjectContext) -> Event? {
        return Event.mr_findFirst(byAttribute: "remoteId", withValue: eventId, in: context);
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
        guard let event = Event.mr_createEntity(in: context) else {
            return nil;
        }
        event.updateEvent(json: json, context: context);
        return event;
    }
    
    func updateEvent(json: [AnyHashable : Any], context: NSManagedObjectContext) {
        self.remoteId = json["id"] as? NSNumber
        self.name = json["name"] as? String
        self.maxObservationForms = json["maxObservationForms"] as? NSNumber
        self.minObservationForms = json["minObservationForms"] as? NSNumber
        self.eventDescription = json["description"] as? String
        self.acl = AFJSONObjectByRemovingKeysWithNullValues(json["acl"] ?? [:], .allowFragments) as? [AnyHashable : Any]
        self.forms = AFJSONObjectByRemovingKeysWithNullValues(json["forms"] ?? [[:]], .allowFragments) as? [[AnyHashable : Any]]
        
        if let responseTeams = json["teams"] as? [[AnyHashable : Any]] {
            for teamJson in responseTeams {
                if let team = self.teams?.first(where: { team in
                    if let team = team as? Team {
                        return team.remoteId == teamJson["id"] as? String
                    }
                    return false;
                }) as? Team {
                    team.update(forJson: teamJson, in: context);
                } else {
                    if let teamId = teamJson["id"] as? String, let team = Team.mr_findFirst(byAttribute: "remoteId", withValue: teamId, in: context) {
                        team.update(forJson: teamJson, in: context);
                        self.addToTeams(team);
                    } else {
                        let team = Team.insert(forJson: teamJson, in: context);
                        self.addToTeams(team);
                    }
                }
            }
        }
        if let layers = json["layers"] as? [Any], let remoteId = remoteId {
            Layer.populateLayers(fromJson: layers, inEventId: remoteId, in: context);
        }
        if let remoteId = remoteId {
            Feed.refreshFeeds(eventId: remoteId)
        }
    }
    
    @objc public func isUserInEvent(user: User) -> Bool {
        guard let teams = teams else {
            return false;
        }
        for case let team as Team in teams {
            if let users = team.users {
                if users.contains(user) {
                    return true;
                }
            }
        }
        print("User \(user.name ?? "") is not in the event \(self.name ?? "")");
        return false;
    }
    
    @objc public func form(observation: Observation) -> [AnyHashable : Any] {
        return observation.getPrimaryEventForm();
    }
    
    @objc public func form(id: NSNumber) -> [AnyHashable : Any]? {
        guard let forms = forms else {
            return nil
        }
        for form in forms {
            if form["id"] as? NSNumber == id {
                return form;
            }
        }
        return nil;
    }
    
    @objc public var nonArchivedForms: [[AnyHashable : Any]]? {
        get {
            return self.forms?.filter({ form in
                return (form["archived"] as? NSNumber) == 0
            })
        }
    }
}
