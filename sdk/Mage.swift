//
//  Mage.m
//  mage-ios-sdk
//
//

import Foundation

@objc public class Mage: NSObject {
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @Injected(\.observationPushService)
    var observationPushService: ObservationPushService
    
    @Injected(\.attachmentPushService)
    var attachmentPushService: AttachmentPushService
    
    @Injected(\.settingsRepository)
    var settingsRepository: SettingsRepository

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
        
        Task {
            await fetchSettings()
            await observationPushService.start();
        }
        if let context = context {
            attachmentPushService.start(context)
        }
        
        let sessionTask = SessionTask(tasks: tasks, andMaxConcurrentTasks: 1);
        MageSessionManager.shared().add(sessionTask);
        
        MageSessionManager.setEventTasks(nil);
    }
    
    @objc public func stopServices() {
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        Task {
            await observationPushService.stop();
        }
        attachmentPushService.stop();
    }
    
    private func fetchSettings() async {
        await settingsRepository.fetchMapSettings()
    }
}
