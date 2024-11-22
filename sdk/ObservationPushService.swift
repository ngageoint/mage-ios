//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

import Foundation
import CoreData
import Combine

enum ObservationErrorKeys: String {
    case errorStatusCode, errorDescription, errorMessage
}

private struct ObservationPushServiceProviderKey: InjectionKey {
    static var currentValue: ObservationPushService = ObservationPushServiceImpl()
}

extension InjectedValues {
    var observationPushService: ObservationPushService {
        get { Self[ObservationPushServiceProviderKey.self] }
        set { Self[ObservationPushServiceProviderKey.self] = newValue }
    }
}

protocol ObservationPushService: Actor {
    var started: Bool { get }
    func pushObservations(observations: [Observation]?)
    func start()
    func stop()
    func isPushingObservations() -> Bool
    func addDelegate(delegate: ObservationPushDelegate)
}

public actor ObservationPushServiceImpl: NSObject, ObservationPushService {
    @Injected(\.persistence)
    var persistence: Persistence
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.observationImportantRepository)
    var observationImportantRepository: ObservationImportantRepository
    
    @Injected(\.observationFavoriteRepository)
    var observationFavoriteRepository: ObservationFavoriteRepository
    
    public static let singleton = ObservationPushServiceImpl()
    public var started = false;
    
    let interval: TimeInterval = Double(UserDefaults.standard.observationPushFrequency)
    var delegates: [ObservationPushDelegate] = []
    var observationPushTimer: (any Cancellable)?
    var fetchedResultsController: NSFetchedResultsController<Observation>?;
    var favoritesFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?;
    var importantFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?;
    var pushingObservations: [NSManagedObjectID : Observation] = [:]
    var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    let fetchedResultsControllerDelegate = ObservationPushServiceImplFetchedResultsControllerDelgate()
    
    public func start() {
        self.started = true;
        persistence.contextChange
        .sink { [weak self] _ in
            Task {
                await self?.setUpFetchedResultsController()
            }
        }
        .store(in: &cancellables)

        setUpFetchedResultsController()
        onTimerFire();
        scheduleTimer();
    }
    
    func setUpFetchedResultsController() {
        guard let context = self.context else { return }
        
        let request = Observation.fetchRequest()
        request.predicate = NSPredicate(format: "\(ObservationKey.dirty.key) == true")
        request.sortDescriptors = [NSSortDescriptor(key: ObservationKey.timestamp.key, ascending: false)]
        
        self.fetchedResultsController = NSFetchedResultsController<Observation>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController?.delegate = fetchedResultsControllerDelegate
        try? self.fetchedResultsController?.performFetch()
    }
    
    func stop() {
        if let timer = self.observationPushTimer {
            timer.cancel()
            self.observationPushTimer = nil;
        }
        for cancellable in cancellables {
            cancellable.cancel()
        }
        self.fetchedResultsController = nil;
        self.importantFetchedResultsController = nil;
        self.favoritesFetchedResultsController = nil;
        self.started = false;
    }

    func scheduleTimer() {
        if let timer = self.observationPushTimer {
            timer.cancel()
            self.observationPushTimer = nil;
        }
        
        self.observationPushTimer = DispatchQueue
            .global(qos: .utility)
            .schedule(after: DispatchQueue.SchedulerTimeType(.now()),
                      interval: .seconds(self.interval),
                      tolerance: .seconds(self.interval / 5)) { [weak self] in
            guard let self else { return }
            Task {
                 await self.onTimerFire()
            }
        }
    }
    
    func onTimerFire() {
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
        if let observation = await observationRepository.getObservationNSManagedObject(observationUri: observationUri) {
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
        context?.performAndWait {
            try? context?.obtainPermanentIDs(for: observations)
            
            for observation in observations {
                if self.pushingObservations[observation.objectID] == nil {
                    self.pushingObservations[observation.objectID] = observation
                    observationsToPush[observation.objectID] = observation;
                    observation.syncing = true;
                }
                try? context?.save()
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
                guard let context = self.context else { return }
                context.performAndWait {
                    guard let localObservation = self.context?.object(with: observationID) as? Observation else {
                        return;
                    }
                    localObservation.populate(json: response)
                    localObservation.dirty = false
                    localObservation.error = nil
                    
                    // when the observation comes back from a new server the attachments will have moved from the field to the attachments array
                    var remoteIdsFromJson :Set<String> = []

                    if let attachmentsInResponse = response[ObservationKey.attachments.key] as? [[AnyHashable : Any]] {
                        
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
                    }
                    // If a local attachment if absent on the server, delete it (and the locally cached file)
                    let attachmentsDeletedOnServer = observation.attachments?.filter {
                        !remoteIdsFromJson.contains($0.remoteId ?? "")
                    }
                    attachmentsDeletedOnServer?.forEach {
                        observation.removeFromAttachments($0)
                        context.delete($0)
                    }
                    var contextDidSave = false
                    var saveError: Error?
                    do {
                        try context.save()
                        contextDidSave = true
                    } catch {
                        contextDidSave = false
                        saveError = error
                    }
                    self.pushingObservations.removeValue(forKey: observationID);
                    for delegate in self.delegates {
                        delegate.didPush(observation: observation, success: contextDidSave, error: saveError)
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
                
                guard let context = self.context else { return }
                context.performAndWait {
                    guard let error = error as NSError?, let localObservation = self.context?.object(with: observationID) as? Observation else {
                        return;
                    }
                    
                    var localError = localObservation.error ?? [:]
                    localError[ObservationErrorKeys.errorDescription] = error.localizedDescription;
                    if let response: HTTPURLResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
                        localError[ObservationErrorKeys.errorStatusCode] = response.statusCode;
                        if let data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data {
                            localError[ObservationErrorKeys.errorMessage] = String(data: data, encoding: .utf8)
                        }
                    }
                    localObservation.error = localError;
                    // TODO: verify this if we set the error, the push service sees it as an update so it tries to resend immediately
                    // we need to put in some kind of throttle
                    
                    var contextDidSave = false
                    do {
                        try context.save()
                        contextDidSave = true
                    } catch {
                        contextDidSave = false
                    }
                    self.pushingObservations.removeValue(forKey: observationID);
                    for delegate in self.delegates {
                        delegate.didPush(observation: localObservation, success: contextDidSave, error: error)
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

final class ObservationPushServiceImplFetchedResultsControllerDelgate : NSObject, NSFetchedResultsControllerDelegate {
    @Injected(\.observationPushService)
    var pushService: ObservationPushService
    
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if let observation = anObject as? Observation {
            switch type {
            case .insert:
                NSLog("XXXX observations inserted, push em")
                Task {
                    await pushService.pushObservations(observations: [observation])
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("XXXX observations updated, push em")
                if observation.remoteId != nil {
                    Task {
                        await pushService.pushObservations(observations: [observation])
                    }
                }
            @unknown default:
                break
            }
        }
    }
}
