//
//  FetchEventsUseCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class FetchEventsUseCase {
    @Injected(\.eventRepository)
    var eventRepository: EventRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    func execute() {
        Task {
            let userModel = await userRepository.fetchMyself()
            await eventRepository.fetchEvents()
            
            self.fetchFormAndStaticLayers(events: eventRepository.getEvents());
        }
    }
    
    // TODO: this will move to it's own repository
    func fetchFormAndStaticLayers(events: [EventModel]) {
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
                Task {
                    await ObservationImageRepositoryImpl.shared.clearCache()
                }
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
    
    func add(task: URLSessionTask, eventTasks: inout [NSNumber: [NSNumber]], event: EventModel) {
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
