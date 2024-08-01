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
    var pushingFavorites: [NSManagedObjectID : ObservationFavorite] = [:]
    var pushingImportant: [String : ObservationImportant] = [:]
    
    private override init() {
    }
    
    public func start() {
        NSLog("start pushing observations");
        self.started = true;
        let context = NSManagedObjectContext.mr_default();
        
        self.fetchedResultsController = Observation.mr_fetchAllSorted(by: ObservationKey.timestamp.key,
                                                                      ascending: false,
                                                                      with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                                                                      groupBy: nil,
                                                                      delegate: self,
                                                                      in: context);
        
        self.favoritesFetchedResultsController = ObservationFavorite.mr_fetchAllSorted(by: "observation.\(ObservationKey.timestamp.key)",
                                                                      ascending: false,
                                                                      with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                                                                      groupBy: nil,
                                                                      delegate: self,
                                                                      in: context);
        
        self.importantFetchedResultsController = ObservationImportant.mr_fetchAllSorted(by: "observation.\(ObservationKey.timestamp.key)",
                                                                               ascending: false,
                                                                               with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                                                                               groupBy: nil,
                                                                               delegate: self,
                                                                               in: context);
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
            pushFavorites(favorites: self.favoritesFetchedResultsController?.fetchedObjects as? [ObservationFavorite])
            pushImportant(importants: self.importantFetchedResultsController?.fetchedObjects as? [ObservationImportant])
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
                            // only look for attachments without a url that match a field we tried to save
                            for attachmentResponse in attachmentsInResponse where (attachmentResponse[ObservationKey.url.key] == nil) {
                                guard let fieldName = attachmentResponse[AttachmentKey.fieldName.key] as? String,
                                      let name = attachmentResponse[AttachmentKey.name.key] as? String,
                                      let forms = propertiesToSave?[ObservationKey.forms.key] as? [[AnyHashable: Any]] else {
                                    continue;
                                }
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
    
    func pushFavorites(favorites: [ObservationFavorite]?) {
        guard let favorites = favorites else {
            return
        }

        if !DataConnectionUtilities.shouldPushObservations() {
            return
        }
        
        // only push favorites that haven't already been told to be pushed
        var favoritesToPush: [NSManagedObjectID : ObservationFavorite] = [:]
        for favorite in favorites {
            if pushingFavorites[favorite.objectID] == nil {
                pushingFavorites[favorite.objectID] = favorite
                favoritesToPush[favorite.objectID] = favorite
            }
        }
        
        NSLog("about to push an additional \(favoritesToPush.count) favorites")
        let manager = MageSessionManager.shared()
        for favorite in favoritesToPush.values {
            let favoritePushTask = Observation.operationToPushFavorite(favorite: favorite) { task, response in
                NSLog("Successfuly submitted favorite")
                MagicalRecord.save { context in
                    let localFavorite = favorite.mr_(in: context)
                    localFavorite?.dirty = false;
                } completion: { contextDidSave, error in
                    self.pushingFavorites.removeValue(forKey: favorite.objectID)
                }
            } failure: { task, error in
                NSLog("Error submitting favorite")
                self.pushingFavorites.removeValue(forKey: favorite.objectID)
            }
            if let favoritePushTask = favoritePushTask {
                manager?.addTask(favoritePushTask);
            }
        }
    }
    
    func pushImportant(importants: [ObservationImportant]?) {
        guard let importants = importants else {
            return
        }

        // only push important changes that haven't already been told to be pushed
        var importantsToPush: [String : ObservationImportant] = [:]
        for important in importants {
            if let observationRemoteId = important.observation?.remoteId, pushingImportant[observationRemoteId] == nil {
                NSLog("adding important to push \(observationRemoteId)")
                pushingImportant[observationRemoteId] = important
                importantsToPush[observationRemoteId] = important
            }
        }
        
        NSLog("about to push an additional \(importantsToPush.count) importants")
        let manager = MageSessionManager.shared();
        for (observationId, important) in importantsToPush {
            let importantPushTask = Observation.operationToPushImportant(important: important) { task, response in
                // verify that the current state in our data is the same as returned from the server
                MagicalRecord.save { context in
                    if let response = response as? [AnyHashable : Any], let localImportant = important.mr_(in: context) {
                        let serverImportant = response[ObservationKey.important.key] != nil
                        if localImportant.important == serverImportant {
                            localImportant.dirty = false
                        } else {
                            // force a push again
                            localImportant.timestamp = Date()
                        }
                        if let observation = localImportant.observation {
                            localImportant.managedObjectContext?.refresh(observation, mergeChanges: false);
                        }
                    }
                } completion: { contextDidSave, error in
                    self.pushingImportant.removeValue(forKey: observationId)
                }
            } failure: { task, error in
                NSLog("Error submitting important")
                self.pushingImportant.removeValue(forKey: observationId)
            }
            if let importantPushTask = importantPushTask {
                manager?.addTask(importantPushTask);
            }
        }
    }
    
    func isPushingFavorites() -> Bool {
        return !pushingFavorites.isEmpty
    }
    
    func isPushingObservations() -> Bool {
        return !pushingObservations.isEmpty
    }
    
    func isPushingImportant() -> Bool {
        return !pushingImportant.isEmpty
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
        } else if let observationFavorite = anObject as? ObservationFavorite {
            switch type {
            case .insert:
                NSLog("favorites inserted, push em")
                pushFavorites(favorites: [observationFavorite])
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("favorites updated, push em")
                if observationFavorite.observation?.remoteId != nil {
                    pushFavorites(favorites: [observationFavorite])
                }
            @unknown default:
                break
            }
        } else if let observationImportant = anObject as? ObservationImportant {
            switch type {
            case .insert:
                NSLog("important inserted, push em")
                if observationImportant.observation?.remoteId != nil {
                    pushImportant(importants: [observationImportant])
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("important updated, push em")
                if observationImportant.observation?.remoteId != nil {
                    pushImportant(importants: [observationImportant])
                }
            @unknown default:
                break
            }
        }
    }
}
