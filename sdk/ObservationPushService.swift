//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

import Foundation
import CoreData

public class ObservationPushService: NSObject {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.observationImportantRepository)
    var observationImportantRepository: ObservationImportantRepository
    
    @Injected(\.observationFavoriteRepository)
    var observationFavoriteRepository: ObservationFavoriteRepository
    
    public static let ObservationErrorStatusCode = "errorStatusCode"
    public static let ObservationErrorDescription = "errorDescription"
    public static let ObservationErrorMessage = "errorMessage"
    
    public static let singleton = ObservationPushService()
    public var started = false;
    
    let interval: TimeInterval = Double(UserDefaults.standard.observationPushFrequency)
    var delegates: [ObservationPushDelegate] = []
    var observationPushTimer: Timer?;
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?;
    var favoritesFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?;
    var importantFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?;
    var pushingObservations: [NSManagedObjectID : Observation] = [:]
    
    
    private override init() {
    }
    
    public func start() {
        NSLog("start pushing observations");
        self.started = true;
        let context = NSManagedObjectContext.mr_default();
        context.perform {
            self.fetchedResultsController = Observation.mr_fetchAllSorted(by: ObservationKey.timestamp.key,
                                                                          ascending: false,
                                                                          with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                                                                          groupBy: nil,
                                                                          delegate: self,
                                                                          in: context);
        }
        onTimerFire();
        scheduleTimer();
    }
    
    func stop() {
        NSLog("stop pushing observations")
        DispatchQueue.main.async { [weak self] in
            if let timer = self?.observationPushTimer, timer.isValid {
                timer.invalidate();
                self?.observationPushTimer = nil;
            }
        }
        
        self.fetchedResultsController = nil;
        self.importantFetchedResultsController = nil;
        self.favoritesFetchedResultsController = nil;
        self.started = false;
    }
    
    func scheduleTimer() {
        DispatchQueue.main.async { [weak self] in
            if let timer = self?.observationPushTimer, timer.isValid {
                timer.invalidate();
                self?.observationPushTimer = nil;
            }
            guard let pushService = self else {
                return;
            }
            pushService.observationPushTimer = Timer.scheduledTimer(timeInterval: pushService.interval, target: pushService, selector: #selector(pushService.onTimerFire), userInfo: nil, repeats: true);
        }
    }
    
    @objc func onTimerFire() {
        if !UserUtility.singleton.isTokenExpired && DataConnectionUtilities.shouldPushObservations() {
            pushObservations(observations: fetchedResultsController?.fetchedObjects as? [Observation])
            observationFavoriteRepository.sync()
            observationImportantRepository.sync()
        }
    }

    func addDelegate(delegate: ObservationPushDelegate) {
        if !self.delegates.contains(where: { delegateInArray in
            delegate == delegateInArray
        }) {
            delegates.append(delegate);
        }
    }
    
    func removeDelegate(delegate: ObservationPushDelegate) {
        self.delegates.removeAll(where: { delegateInArray in
            delegate == delegateInArray
        });
    }
    
    public func pushObservation(observationUri: URL) async {
        if let observation = await observationRepository.getObservation(observationUri: observationUri) {
            pushObservations(observations: [observation])
        }
    }
    
    public func pushObservations(observations: [Observation]?) {
        guard let observations = observations else {
            return
        }

        if !DataConnectionUtilities.shouldPushObservations() {
            return;
        }
        NSLog("currently still pushing \(self.pushingObservations.count) observations")
        
        // only push observations that haven't already been told to be pushed
        var observationsToPush: [NSManagedObjectID : Observation] = [:]
        for observation in observations {
            do {
                try observation.managedObjectContext?.obtainPermanentIDs(for: [observation])
            } catch {
                
            }
            
            if self.pushingObservations[observation.objectID] == nil {
                self.pushingObservations[observation.objectID] = observation
                observationsToPush[observation.objectID] = observation;
                observation.syncing = true;
            }
        }
        
        NSLog("About to push an additional \(observationsToPush.count) observations")
        
        let manager = MageSessionManager.shared();
        for observation in observationsToPush.values {
            let observationID = observation.objectID;
            let observationPushTask = Observation.operationToPushObservation(observation: observation) { task, response in
                NSLog("Successfully submitted observation")
                
                guard let response = response as? [AnyHashable : Any] else {
                    return;
                }
                
                // save the properties of the observation before they get overwritten so we can match the attachments later
                let propertiesToSave = observation.properties;
                MagicalRecord.save { context in
                    guard let localObservation = observation.mr_(in: context) else {
                        return;
                    }
                    localObservation.populate(json: response)
                    localObservation.dirty = false
                    localObservation.error = nil
                    
                    if MageServer.isServerVersion5 {
                        if let attachments = localObservation.attachments {
                            for attachment in attachments {
                                attachment.observationRemoteId = localObservation.remoteId
                            }
                        }
                    } else {
                        // when the observation comes back from a new server the attachments will have moved from the field to the attachments array
                        if let attachmentsInResponse = response[ObservationKey.attachments.key] as? [[AnyHashable : Any]] {
                            var remoteIdsFromJson :Set<String> = []
                            
                            for attachmentResponse in attachmentsInResponse {
                                guard let fieldName = attachmentResponse[AttachmentKey.fieldName.key] as? String,
                                      let name = attachmentResponse[AttachmentKey.name.key] as? String,
                                      let forms = propertiesToSave?[ObservationKey.forms.key] as? [[AnyHashable: Any]] else {
                                    continue;
                                }
                                if let remoteId = attachmentResponse[AttachmentKey.id.key] as? String {
                                    remoteIdsFromJson.insert(remoteId)
                                }
                                
                                // only look for attachments without a url that match a field we tried to save
                                if attachmentResponse[ObservationKey.url.key] == nil {
                                    // search through each form for attachments that needed saving
                                    for form in forms {
                                        guard let formValue = form[fieldName] else {
                                            continue;
                                        }
                                        // name will be unique because when the attachment is pulled in, we rename it to MAGE_yyyyMMdd_HHmmss.extension
                                        if let unfilteredFieldAttachments = formValue as? [[AnyHashable: Any]] {
                                            if let fieldAttachment = unfilteredFieldAttachments.first(where: { attachmentJson in
                                                return attachmentJson[AttachmentKey.name.key] as? String == name
                                            }) {
                                                let attachment = Attachment.attachment(json: attachmentResponse, context: context)
                                                attachment?.observation = localObservation;
                                                attachment?.observationRemoteId = localObservation.remoteId;
                                                attachment?.dirty = true;
                                                attachment?.localPath = fieldAttachment[AttachmentKey.localPath.key] as? String
                                            }
                                        }
                                    }
                                }
                            }
                            // If a local attachment if absent on the server, delete it (and the locally cached file)
                            let attachmentsDeletedOnServer = observation.attachments?.filter {
                                !remoteIdsFromJson.contains($0.remoteId ?? "")
                            }
                            attachmentsDeletedOnServer?.forEach {
                                observation.removeFromAttachments($0)
                                $0.mr_deleteEntity(in: context)
                            }
                        }
                    }
                } completion: { contextDidSave, error in
                    self.pushingObservations.removeValue(forKey: observationID);
                    for delegate in self.delegates {
                        delegate.didPush(observation: observation, success: contextDidSave, error: error)
                    }
                }
            } failure: { task, error in
                NSLog("Error submitting observation");
                // TODO: check for 400
                if error == nil {
                    NSLog("Error submitting observation, no error returned");
                    
                    self.pushingObservations.removeValue(forKey: observationID);
                    for delegate in self.delegates {
                        delegate.didPush(observation: observation, success: false, error: error)
                    }
                    return;
                }
                
                MagicalRecord.save { context in
                    guard let error = error as NSError?, let localObservation = observation.mr_(in: context) else {
                        return;
                    }
                    
                    var localError = localObservation.error ?? [:]
                    localError[ObservationPushService.ObservationErrorDescription] = error.localizedDescription;
                    if let response: HTTPURLResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
                        localError[ObservationPushService.ObservationErrorStatusCode] = response.statusCode;
                        if let data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data {
                            localError[ObservationPushService.ObservationErrorMessage] = String(data: data, encoding: .utf8)
                        }
                    }
                    localObservation.error = localError;
                    // TODO: verify this if we set the error, the push service sees it as an update so it tries to resend immediately
                    // we need to put in some kind of throttle
                } completion: { contextDidSave, recordSaveError in
                    self.pushingObservations.removeValue(forKey: observationID);
                    for delegate in self.delegates {
                        delegate.didPush(observation: observation, success: false, error: error)
                    }
                }
            }
            
            if let observationPushTask = observationPushTask {
                manager?.addTask(observationPushTask);
            }

        }
    }
    
    func isPushingObservations() -> Bool {
        return !pushingObservations.isEmpty
    }
}

extension ObservationPushService : NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if let observation = anObject as? Observation {
            switch type {
            case .insert:
                NSLog("observations inserted, push em")
                pushObservations(observations: [observation])
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("observations updated, push em")
                if observation.remoteId != nil {
                    pushObservations(observations: [observation])
                }
            @unknown default:
                break
            }
        }
    }
}
