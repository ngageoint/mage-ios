//
//  Mage.m
//  mage-ios-sdk
//
//

import Foundation
import Persistence
import Settings
import UserFetch
import ServerDTO

@objc public class Mage: NSObject {
    
    @objc public static let singleton = Mage();
    
    private override init() {
    }
    
    @objc public func startServices(initial: Bool) {
        Task {
            await fetchSettings()
        }
        let startFetchServices = {
            LocationFetchService.singleton.start();
            ObservationFetchService.singleton.start(initial: initial);
        }
        if initial {
            Task {
                await fetchUsers()
                NSLog("initial user fetch complete")
                startFetchServices()
            }
        }
        else {
            startFetchServices()
        }
        LocationService.singleton().start();
        ObservationPushService.singleton.start();
        AttachmentPushService.singleton().start();        
        MageSessionManager.setEventTasks(nil);
    }
    
    @objc public func stopServices() {
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        ObservationPushService.singleton.stop();
        AttachmentPushService.singleton().stop();
    }
    
    public func fetchUsers() async {
        do {
            let eventID: EventID? = Server.currentEventId().map { EventID($0) }
            let eventUserFetchUseCase = try await DependencyContainer.shared.useCaseFactory
                .resolve(.EventUserFetchUseCase)
            try await eventUserFetchUseCase.execute(eventID: eventID)
        } catch {
            UserFetchPackage.logger.error("Failed to fetch event users: \(error)")
        }
    }
    
    public func fetchSettings() async {
        do {
            let _ = try await DependencyContainer.shared.useCaseFactory
                .resolve(.RefreshSettingsUseCase)
                .execute()
        } catch {
            SettingsPackage.logger.error("Failed to fetch settings: \(error)")
        }
    }
    
    public func fetchMyself() async {
        do {
            let _ = try await DependencyContainer.shared.useCaseFactory
                .resolve(.GetMyselfUseCase)
                .execute()
        } catch {
            UserFetchPackage.logger.error("Failed to fetch myself: \(error)")
        }
    }
    @objc public func fetchEvents() async {
        let manager = MageSessionManager.shared();
        
        await fetchMyself()
        
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
    
    private func add(task: URLSessionTask, eventTasks: inout [NSNumber: [NSNumber]], event: Event) {
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
