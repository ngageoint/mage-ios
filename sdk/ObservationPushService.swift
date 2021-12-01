//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

import Foundation
import CoreData

@objc public class ObservationPushService: NSObject {
    
    @objc public static let ObservationErrorStatusCode = "errorStatusCode"
    @objc public static let ObservationErrorDescription = "errorDescription"
    @objc public static let ObservationErrorMessage = "errorMessage"
    
    @objc public static let singleton = ObservationPushService()
    @objc public var started = false;
    
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
    
    @objc public func start() {
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
    
    @objc public func stop() {
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

    @objc public func addDelegate(delegate: ObservationPushDelegate) {
        if !self.delegates.contains(where: { delegateInArray in
            delegate == delegateInArray
        }) {
            delegates.append(delegate);
        }
    }
    
    @objc public func removeDelegate(delegate: ObservationPushDelegate) {
        self.delegates.removeAll(where: { delegateInArray in
            delegate == delegateInArray
        });
    }
    
    @objc public func pushObservations(observations: [Observation]?) {
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
    
    @objc public func isPushingFavorites() -> Bool {
        return !pushingFavorites.isEmpty
    }
    
    @objc public func isPushingObservations() -> Bool {
        return !pushingObservations.isEmpty
    }
    
    @objc public func isPushingImportant() -> Bool {
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

//#import "ObservationPushService.h"
//#import "MageSessionManager.h"
//#import "DataConnectionUtilities.h"
//#import "MageServer.h"
//#import "MAGE-Swift.h"
//
//@class Observation;
//
//@protocol ObservationPushDelegate <NSObject>
//
//@required
//
//- (void) didPushObservation:(Observation *) observation success:(BOOL) success error:(NSError *) error;
//
//@end
//
//@interface ObservationPushService : NSObject
//
//extern NSString * const kObservationErrorStatusCode;
//extern NSString * const kObservationErrorDescription;
//extern NSString * const kObservationErrorMessage;
//
//+ (instancetype) singleton;
//- (void) start;
//- (void) stop;
//
//- (void) addObservationPushDelegate:(id<ObservationPushDelegate>) delegate;
//- (void) removeObservationPushDelegate:(id<ObservationPushDelegate>) delegate;
//
//- (void) pushObservations:(NSArray *) observations;
//- (BOOL) isPushingFavorites;
//- (BOOL) isPushingObservations;
//- (BOOL) isPushingImportant;
//
//@property (nonatomic) BOOL started;
//
//NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";
//NSString * const kObservationErrorStatusCode = @"errorStatusCode";
//NSString * const kObservationErrorDescription = @"errorDescription";
//NSString * const kObservationErrorMessage = @"errorMessage";
//
//@interface ObservationPushService () <NSFetchedResultsControllerDelegate>
//@property (nonatomic) NSTimeInterval interval;
//@property (nonatomic, strong) NSMutableSet<id<ObservationPushDelegate>>* delegates;
//@property (nonatomic, strong) NSTimer* observationPushTimer;
//@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
//@property (nonatomic, strong) NSFetchedResultsController *favoritesFetchedResultsController;
//@property (nonatomic, strong) NSFetchedResultsController *importantFetchedResultsController;
//@property (nonatomic, strong) NSMutableDictionary *pushingObservations;
//@property (nonatomic, strong) NSMutableDictionary *pushingFavorites;
//@property (nonatomic, strong) NSMutableDictionary *pushingImportant;
//@end
//
//@implementation ObservationPushService
//
//+ (instancetype) singleton {
//    static ObservationPushService *pushService = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        pushService = [[self alloc] init];
//        pushService.started = false;
//    });
//    return pushService;
//}
//
//- (id) init {
//    if (self = [super init]) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//        _interval = [[defaults valueForKey:kObservationPushFrequencyKey] doubleValue];
//        _pushingObservations = [[NSMutableDictionary alloc] init];
//        _pushingFavorites = [[NSMutableDictionary alloc] init];
//        _pushingImportant = [[NSMutableDictionary alloc] init];
//        _delegates = [NSMutableSet set];
//    }
//
//    return self;
//}
//
//- (BOOL) isPushingFavorites {
//    return _pushingFavorites.allKeys.count != 0;
//}
//
//- (BOOL) isPushingObservations {
//    return _pushingObservations.allKeys.count != 0;
//}
//
//- (BOOL) isPushingImportant {
//    return _pushingImportant.allKeys.count != 0;
//}
//
//- (void) addObservationPushDelegate:(id<ObservationPushDelegate>) delegate {
//    [self.delegates addObject:delegate];
//}
//
//- (void) removeObservationPushDelegate:(id<ObservationPushDelegate>) delegate {
//    [self.delegates removeObject:delegate];
//}
//
//- (void) start {
//    NSLog(@"start pushing observations");
//    self.started = true;
//    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
//
//    self.fetchedResultsController = [Observation MR_fetchAllSortedBy:@"timestamp"
//                                                           ascending:NO
//                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
//                                                             groupBy:nil
//                                                            delegate:self
//                                                           inContext:context];
//
//    self.favoritesFetchedResultsController = [ObservationFavorite MR_fetchAllSortedBy:@"observation.timestamp"
//                                                           ascending:NO
//                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
//                                                             groupBy:nil
//                                                            delegate:self
//                                                           inContext:context];
//
//    self.importantFetchedResultsController = [ObservationImportant MR_fetchAllSortedBy:@"observation.timestamp"
//                                                                            ascending:NO
//                                                                        withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
//                                                                              groupBy:nil
//                                                                             delegate:self
//                                                                            inContext:context];
//
//    [self onTimerFire];
//    [self scheduleTimer];
//}
//
//
//- (void) scheduleTimer {
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([weakSelf.observationPushTimer isValid]) {
//            [weakSelf.observationPushTimer invalidate];
//            weakSelf.observationPushTimer = nil;
//        }
//        weakSelf.observationPushTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
//    });
//}
//
//- (void) onTimerFire {
//    if (![[UserUtility singleton] isTokenExpired] && [DataConnectionUtilities shouldPushObservations]) {
//        [self pushObservations:self.fetchedResultsController.fetchedObjects];
//        [self pushFavorites:self.favoritesFetchedResultsController.fetchedObjects];
//        [self pushImportant:self.importantFetchedResultsController.fetchedObjects];
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
//    if ([anObject isKindOfClass:[Observation class]]) {
//        switch(type) {
//            case NSFetchedResultsChangeInsert: {
//                NSLog(@"observations inserted, push em");
//                [self pushObservations:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeDelete:
//                break;
//            case NSFetchedResultsChangeUpdate: {
//                NSLog(@"observations updated, push em");
//                if ([anObject remoteId]) [self pushObservations:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeMove:
//                break;
//        }
//    } else if ([anObject isKindOfClass:[ObservationFavorite class]]) {
//        switch(type) {
//            case NSFetchedResultsChangeInsert: {
//                NSLog(@"favorites inserted, push em");
//                [self pushFavorites:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeDelete:
//                break;
//            case NSFetchedResultsChangeUpdate: {
//                NSLog(@"favorites updated, push em");
//                if ([[anObject observation] remoteId]) [self pushFavorites:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeMove:
//                break;
//        }
//    } else if ([anObject isKindOfClass:[ObservationImportant class]]) {
//        switch(type) {
//            case NSFetchedResultsChangeInsert: {
//                NSLog(@"important inserted, push em %@", anObject);
//                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeDelete: {
//                break;
//            }
//            case NSFetchedResultsChangeUpdate: {
//                NSLog(@"important updated, push em %@", anObject);
//                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
//                break;
//            }
//            case NSFetchedResultsChangeMove:
//            break;
//        }
//    }
//}
//
//- (void) pushObservations:(NSArray *) observations {
//    if (![DataConnectionUtilities shouldPushObservations]) return;
//    NSLog(@"currently still pushing %lu observations", (unsigned long) self.pushingObservations.count);
//
//    // only push observations that haven't already been told to be pushed
//    NSMutableDictionary *observationsToPush = [[NSMutableDictionary alloc] init];
//    for (Observation *observation in observations) {
//        [[observation managedObjectContext] obtainPermanentIDsForObjects:@[observation] error:nil];
//
//        if ([self.pushingObservations objectForKey:observation.objectID] == nil) {
//            [self.pushingObservations setObject:observation forKey:observation.objectID];
//            [observationsToPush setObject:observation forKey:observation.objectID];
//            observation.syncing = YES;
//        }
//    }
//
//    NSLog(@"about to push an additional %lu observations", (unsigned long) observationsToPush.count);
//    __weak typeof(self) weakSelf = self;
//    MageSessionManager *manager = [MageSessionManager sharedManager];
//    for (Observation *observation in [observationsToPush allValues]) {
//        NSManagedObjectID *observationID = observation.objectID;
//        NSURLSessionDataTask *observationPushTask = [Observation operationToPushObservationWithObservation:observation success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
//            NSLog(@"Successfully submitted observation");
//            // TODO: handle if response is null
//            // save the properties of the observation before they get overwritten so we can match the attachments later
//            NSDictionary *propertiesToSave = [NSDictionary dictionaryWithDictionary:observation.properties];
//            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                Observation *localObservation = [observation MR_inContext:localContext];
//                [localObservation populateWithJson:response];
//                localObservation.dirty = false;
//                localObservation.error = nil;
//
//                if ([MageServer isServerVersion5]) {
//                    for (Attachment *attachment in localObservation.attachments) {
//                        attachment.observationRemoteId = localObservation.remoteId;
//                    }
//                } else {
//                    // when the observation comes back from a new server the attachments will have moved from the field to the attachments array
//                    for (NSDictionary *attachmentResponse in response[@"attachments"]) {
//                        // only look for attachments without a url that match a field we tried to save
//                        if ([attachmentResponse valueForKey:@"url"] == nil) {
//                            NSString *fieldName = [attachmentResponse valueForKey:@"fieldName"];
//                            NSString *name = [attachmentResponse valueForKey:@"name"];
//                            NSArray *forms = [propertiesToSave objectForKey:@"forms"];
//                            if (forms != nil) {
//                                // search through each form for attachments that needed saving
//                                for (NSDictionary *form in forms) {
//                                    if ([form objectForKey:fieldName] != nil) {
//                                        // name will be unique because when the attachment is pulled in, we rename it to MAGE_yyyyMMdd_HHmmss.extension
//                                        NSArray *unfilteredFieldAttachments = [form objectForKey:fieldName];
//                                        if (unfilteredFieldAttachments != nil && [unfilteredFieldAttachments isKindOfClass:[NSArray class]]) {
//                                            NSArray *fieldAttachments = [unfilteredFieldAttachments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
//                                            if ([fieldAttachments count] != 0) {
//                                                NSDictionary *fieldAttachment = fieldAttachments[0];
//                                                Attachment *attachment = [Attachment attachmentWithJson:attachmentResponse context:localContext];
//                                                [attachment setObservation:localObservation];
//                                                [attachment setObservationRemoteId: localObservation.remoteId];
//                                                [attachment setDirty:true];
//                                                [attachment setLocalPath:[fieldAttachment valueForKey:@"localPath"]];
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            } completion:^(BOOL success, NSError *error) {
//
//                [weakSelf.pushingObservations removeObjectForKey:observationID];
//
//                for (id<ObservationPushDelegate> delegate in self.delegates) {
//                    [delegate didPushObservation:observation success:success error:error];
//                }
//            }];
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * error) {
//            NSLog(@"Error submitting observation");
//            // TODO check for 400
//            if (error == nil) {
//                NSLog(@"Error submitting observation, no error returned");
//
//                [weakSelf.pushingObservations removeObjectForKey:observationID];
//                for (id<ObservationPushDelegate> delegate in weakSelf.delegates) {
//                    [delegate didPushObservation:observation success:NO error:error];
//                }
//
//                return;
//            }
//
//            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                Observation *localObservation = [observation MR_inContext:localContext];
//
//                NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
//
//                NSMutableDictionary *localError = localObservation.error ? [localObservation.error mutableCopy] : [NSMutableDictionary dictionary];
//                [localError setObject:[error localizedDescription] forKey:kObservationErrorDescription];
//
//                if (response) {
//                    [localError setObject:[NSNumber numberWithInteger:response.statusCode] forKey:kObservationErrorStatusCode];
//                    [localError setObject:[[NSString alloc] initWithData:(NSData *) error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding] forKey:kObservationErrorMessage];
//                }
//
//                localObservation.error = localError;
//                // TODO if we set the error, the push service sees it as an update so it tries to resend immediately
//                // we need to put in some kind of throttle
//            } completion:^(BOOL success, NSError *coreDataError) {
//                [weakSelf.pushingObservations removeObjectForKey:observationID];
//
//                for (id<ObservationPushDelegate> delegate in weakSelf.delegates) {
//                    [delegate didPushObservation:observation success:NO error:error];
//                }
//            }];
//        }];
//        if (observationPushTask != nil) {
//            [manager addTask:observationPushTask];
//        }
//    }
//}
//
//- (void) pushFavorites:(NSArray *) favorites {
//    if (![DataConnectionUtilities shouldPushObservations]) return;
//    NSLog(@"currently still pushing %lu favorites", (unsigned long) self.pushingFavorites.count);
//
//    // only push favorites that haven't already been told to be pushed
//    NSMutableDictionary *favoritesToPush = [[NSMutableDictionary alloc] init];
//    for (ObservationFavorite *favorite in favorites) {
//        if ([self.pushingFavorites objectForKey:favorite.objectID] == nil) {
//            [self.pushingFavorites setObject:favorite forKey:favorite.objectID];
//            [favoritesToPush setObject:favorite forKey:favorite.objectID];
//        }
//    }
//
//    NSLog(@"about to push an additional %lu favorites", (unsigned long) favoritesToPush.count);
//    __weak typeof(self) weakSelf = self;
//    MageSessionManager *manager = [MageSessionManager sharedManager];
//    for (ObservationFavorite *favorite in [favoritesToPush allValues]) {
//        NSURLSessionDataTask *favoritePushTask = [Observation operationToPushFavoriteWithFavorite:favorite success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
//            NSLog(@"Successfully submitted favorite");
//            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                ObservationFavorite *localFavorite = [favorite MR_inContext:localContext];
//                localFavorite.dirty = false;
//            } completion:^(BOOL success, NSError *error) {
//                [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
//            }];
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            NSLog(@"Error submitting favorite");
//            [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
//        }];
//        [manager addTask:favoritePushTask];
//    }
//}
//
//- (void) pushImportant:(NSArray *) importants {
//    if (![DataConnectionUtilities shouldPushObservations]) return;
//    NSLog(@"currently still pushing %lu important changes", (unsigned long) self.pushingImportant.count);
//
//    // only push important changes that haven't already been told to be pushed
//    NSMutableDictionary *importantsToPush = [[NSMutableDictionary alloc] init];
//    for (ObservationImportant *important in importants) {
//        if (important.observation.remoteId != nil && [self.pushingImportant objectForKey:important.observation.remoteId] == nil) {
//            NSLog(@"adding important to push %@", important.observation.remoteId);
//            [self.pushingImportant setObject:important forKey:important.observation.remoteId];
//            [importantsToPush setObject:important forKey:important.observation.remoteId];
//        }
//    }
//
//    NSLog(@"about to push an additional %lu importants", (unsigned long) importantsToPush.count);
//    __weak typeof(self) weakSelf = self;
//    MageSessionManager *manager = [MageSessionManager sharedManager];
//    for (NSString *observationId in importantsToPush) {
//        ObservationImportant *important = importantsToPush[observationId];
//        NSURLSessionDataTask *importantPushTask = [Observation operationToPushImportantWithImportant:important success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
//            // verify that the current state in our data is the same as returned from the server
//            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                ObservationImportant *localImportant = [important MR_inContext:localContext];
//                BOOL serverImportant = response[@"important"] != nil;
//                if (localImportant.important == serverImportant) {
//                    localImportant.dirty = false;
//                } else {
//                    // force a push again
//                    localImportant.timestamp = [NSDate date];
//                }
//                [localImportant.managedObjectContext refreshObject:localImportant.observation mergeChanges:false];
//            } completion:^(BOOL success, NSError *error) {
//                [weakSelf.pushingImportant removeObjectForKey:observationId];
//            }];
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            NSLog(@"Error submitting important");
//            [weakSelf.pushingImportant removeObjectForKey:observationId];
//        }];
//        [manager addTask:importantPushTask];
//    }
//}
//
//-(void) stop {
//    NSLog(@"stop pushing observations");
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([weakSelf.observationPushTimer isValid]) {
//            [weakSelf.observationPushTimer invalidate];
//            weakSelf.observationPushTimer = nil;
//        }
//    });
//
//    self.fetchedResultsController = nil;
//    self.importantFetchedResultsController = nil;
//    self.favoritesFetchedResultsController = nil;
//    self.started = false;
//}
//
//
//@end
