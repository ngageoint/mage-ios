//
//  Mage.m
//  mage-ios-sdk
//
//

import Foundation

@objc public class Mage: NSObject {
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @objc public static let singleton = Mage();
    
    private override init() {
    }
    
    @objc public func startServices(initial: Bool) {
        var tasks: [URLSessionDataTask] = []
        
        if let context = context {
            LocationService.singleton().start(context);
        }
        if let rolesPullTask = Role.operationToFetchRoles(success: nil, failure: nil) {
            tasks.append(rolesPullTask);
        }
        
        let usersPullTask = User.operationToFetchUsers { task, response in
            NSLog("Done with the initial user fetch, start location and observation services")
            LocationFetchService.singleton.start();
            ObservationFetchService.singleton.start(initial: initial);
        } failure: { task, error in
            NSLog("Failed to pull users \(error)")
            // start the fetch services anyway.  Attempting to pull the users before starting these
            // will cut down on the individual user requests which will be kicked off if a location
            // or observation shows up with an unknown user
            LocationFetchService.singleton.start();
            ObservationFetchService.singleton.start(initial: initial);
        }
        if let usersPullTask = usersPullTask {
            tasks.append(usersPullTask)
        }
        
        fetchSettings()
        
        ObservationPushService.singleton.start();
        if let context = context {
            AttachmentPushService.singleton().start(context)
        }
        
        let sessionTask = SessionTask(tasks: tasks, andMaxConcurrentTasks: 1);
        MageSessionManager.shared().add(sessionTask);
        
        MageSessionManager.setEventTasks(nil);
    }
    
    @objc public func stopServices() {
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        ObservationPushService.singleton.stop();
        AttachmentPushService.singleton().stop();
    }
    
    private func fetchSettings() {
        let manager = MageSessionManager.shared();
        
        let task = Settings.operationToPullMapSettings { task, response in
            NSLog("Fetched settings");
        } failure: { task, error in
            NSLog("Failure to fetch settings");
        }
        
        if let task = task {
            manager?.addTask(task)
        }
    }
    
    @objc public func fetchEvents() {
        let manager = MageSessionManager.shared();
        
        let myselfTask = User.operationToFetchMyself { task, response in
            let eventTask = Event.operationToFetchEvents { task, response in
                if let events = Event.mr_findAll() as? [Event] {
                    self.fetchFormAndStaticLayers(events: events);
                }
            } failure: { task, error in
                NSLog("Failure to pull events");
                NotificationCenter.default.post(name: .MAGEEventsFetched, object: nil);
                if let events = Event.mr_findAll() as? [Event] {
                    self.fetchFormAndStaticLayers(events: events);
                }
            }
            manager?.addTask(eventTask);
        } failure: { task, error in
            NotificationCenter.default.post(name: .MAGEEventsFetched, object: nil);
            if let events = Event.mr_findAll() as? [Event] {
                self.fetchFormAndStaticLayers(events: events);
            }
        }
        
        if let myselfTask = myselfTask {
            manager?.addTask(myselfTask)
        }
    }
    
    @objc public func fetchFormAndStaticLayers(events: [Event]) {
        let manager = MageSessionManager.shared();
        let task = SessionTask(maxConcurrentTasks: Int32(MAGE_MaxConcurrentEvents));
        
        let currentEventId = Server.currentEventId();
        var eventTasks: [NSNumber: [NSNumber]] = [:];
        for e in events {
            guard let remoteId = e.remoteId else {
                continue;
            }
            let formTask = Form.operationToPullFormIcons(eventId: remoteId) {
                NSLog("Pulled form for event")
                ObservationImage.imageCache.removeAllObjects()
                NotificationCenter.default.post(name: .MAGEFormFetched, object: e)
            } failure: { error in
                NSLog("Failed to pull form for event")
                NotificationCenter.default.post(name: .MAGEFormFetched, object: e)
            }
            
            guard let formTask = formTask else {
                continue
            }
            if let currentEventId = currentEventId, currentEventId == remoteId {
                formTask.priority = URLSessionTask.highPriority
                manager?.addTask(formTask);
            } else {
                task?.add(formTask);
                self.add(task: formTask, eventTasks: &eventTasks, event: e);
            }
        }
        
        MageSessionManager.setEventTasks(eventTasks);
        task?.priority = URLSessionTask.lowPriority;
        manager?.add(task);
    }
    
    func add(task: URLSessionTask, eventTasks: inout [NSNumber: [NSNumber]], event: Event) {
        guard let remoteId = event.remoteId else {
            return;
        }
        let taskIdentifier = task.taskIdentifier;
        var tasks = eventTasks[remoteId]
        
        if tasks == nil {
            tasks = [];
            eventTasks[remoteId] = tasks;
        }
        
        tasks?.append(NSNumber(value:taskIdentifier))
    }
}
