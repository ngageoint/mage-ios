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
import Form
import EventFetch
import Event

@objc public class Mage: NSObject {
    
    @objc public static let singleton = Mage();
    
    private override init() {
    }
    
    @objc public func startServices(initial: Bool, eventId: NSNumber) {
        Task {
            await fetchSettings()
        }
        let startFetchServices = {
            LocationFetchService.singleton.start();
            ObservationFetchService.singleton.start(initial: initial);
        }
        if initial {
            Task {
                await fetchUsers(eventID: EventID(eventId))
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
    
    public func fetchUsers(eventID: EventID) async {
        do {
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
        await fetchMyself()
        do {
            let eventsFetched = try await DependencyContainer.shared.useCaseFactory
                .resolve(.FetchEventsUseCase)
                .execute()
            await fetchFormIcons(events: eventsFetched.events)
        } catch {
            EventFetchPackage.logger.error("Failed to fetch events: \(error)")
        }
        NotificationCenter.default.post(name: .MAGEEventsFetched, object:nil)
    }
    
    public func fetchFormIcons(events: [EventModel]) async {
        for e in events {
            guard let remoteId = e.remoteId else {
                continue;
            }
            do {
                let _ = try await DependencyContainer.shared.useCaseFactory
                    .resolve(.GetEventFormIconsUseCase)
                    .execute(eventID: remoteId)
            } catch {
                FormPackage.logger.error("Failed to fetch form icons: \(error)")
            }
        }
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
