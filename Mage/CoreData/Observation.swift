//
//  Observation.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import sf_ios
import UIKit
import MagicalRecord
import geopackage_ios

enum State: Int, CustomStringConvertible {
    case Archive, Active
    
    var description: String {
        switch self {
        case .Archive:
            return "archive"
        case .Active:
            return "active"
        }
    }
}

@objc public class Observation: NSManagedObject, Navigable {
    var coordinate: CLLocationCoordinate2D {
        get {
            return location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }

    public func viewRegion(mapView: MKMapView) -> MKCoordinateRegion {
        if let geometry = self.geometry {
            var latitudeMeters = 2500.0
            var longitudeMeters = 2500.0
            if geometry is SFPoint {
                if let properties = properties, let accuracy = properties[ObservationKey.accuracy.key] as? Double {
                    latitudeMeters = accuracy * 2.5
                    longitudeMeters = accuracy * 2.5
                }
            } else {
                let envelope = SFGeometryEnvelopeBuilder.buildEnvelope(with: geometry)
                let boundingBox = GPKGBoundingBox(envelope: envelope)
                if let size = boundingBox?.sizeInMeters() {
                    latitudeMeters = size.height + (2 * (size.height * 0.1))
                    longitudeMeters = size.width + (2 * (size.width * 0.1))
                    
                }
            }
            if let centroid = geometry.centroid() {
                return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue), latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
            }
        }
        
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 50000, longitudinalMeters: 50000)
    }
    
    static func fetchedResultsController(_ observation: Observation, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Observation>? {
        guard let remoteId = observation.remoteId else {
            return nil
        }
        let fetchRequest = Observation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteId = %@", remoteId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let observationFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        observationFetchedResultsController.delegate = delegate
        do {
            try observationFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        return observationFetchedResultsController
    }
    
    @objc public static func operationToPullInitialObservations(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        return Observation.operationToPullObservations(initial: true, success: success, failure: failure);
    }
    
    @objc public static func operationToPullObservations(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        return Observation.operationToPullObservations(initial: false, success: success, failure: failure);
    }
    
    static func operationToPullObservations(initial: Bool, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let currentEventId = Server.currentEventId(), let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(currentEventId)/observations";
        print("Fetching observations from event \(currentEventId)");
        
        var parameters: [AnyHashable : Any] = [
            // does this work on the server?
            "sort" : "lastModified+DESC"
        ]
        
        if let lastObservationDate = Observation.fetchLastObservationDate(context: NSManagedObjectContext.mr_default()) {
            parameters["startDate"] = ISO8601DateFormatter.string(from: lastObservationDate, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
        }
        
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: parameters, progress: nil, success: { task, responseObject in
            guard let features = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            
            print("Fetched \(features.count) observations from the server, saving");
            if features.count == 0 {
                success?(task, responseObject)
                return;
            }
            
            let rootSavingContext = NSManagedObjectContext.mr_rootSaving();
            let localContext = NSManagedObjectContext.mr_context(withParent: rootSavingContext);
            localContext.perform {
                localContext.mr_setWorkingName(#function)
                var chunks = features.chunked(into: 250);
                var newObservationCount = 0;
                var observationToNotifyAbout: Observation?;
                while (chunks.count > 0) {
                    autoreleasepool {
                        guard let features = chunks.last else {
                            return;
                        }
                        chunks.removeLast();
                        
                        for observation in features {
                            if let newObservation = Observation.create(feature: observation, context: localContext) {
                                newObservationCount = newObservationCount + 1;
                                if (!initial) {
                                    observationToNotifyAbout = newObservation;
                                }
                            }
                        }
                        print("Saved \(features.count) observations")
                    }
                    
                    // only save once per chunk
                    do {
                        try localContext.save()
                    } catch {
                        print("Error saving observations: \(error)")
                    }
                    
                    rootSavingContext.perform {
                        do {
                            try rootSavingContext.save()
                        } catch {
                            print("Error saving observations: \(error)")
                        }
                    }
                    
                    localContext.reset();
                    NSLog("Saved chunk \(chunks.count)")
                }
                
                NSLog("Received \(newObservationCount) new observations and send bulk is \(initial)")
                if ((initial && newObservationCount > 0) || newObservationCount > 1) {
                    NotificationRequester.sendBulkNotificationCount(UInt(newObservationCount), in: Event.getCurrentEvent(context: localContext));
                } else if let observationToNotifyAbout = observationToNotifyAbout {
                    NotificationRequester.observationPulled(observationToNotifyAbout);
                }
                
                DispatchQueue.main.async {
                    success?(task, responseObject);
                }
            }
        }, failure: { task, error in
            print("Error \(error)")
            failure?(task, error);
        })
        
        return task;
    }
    
    @objc public static func operationToPushObservation(observation: Observation, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error?) -> Void)?) -> URLSessionDataTask? {
        let archived = (observation.state?.intValue ?? 0) == State.Archive.rawValue
        if observation.remoteId != nil {
            if (archived) {
                return Observation.operationToDelete(observation: observation, success: success, failure: failure);
            } else {
                return Observation.operationToUpdate(observation: observation, success: success, failure: failure);
            }
        } else {
            return Observation.operationToCreate(observation: observation, success: success, failure: failure);
        }
    }
    
    @objc public static func operationToPushFavorite(favorite: ObservationFavorite, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let eventId = favorite.observation?.eventId, let observationRemoteId = favorite.observation?.remoteId, let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(eventId)/observations/\(observationRemoteId)/favorite";
        NSLog("Trying to push favorite to server \(url)")

        let manager = MageSessionManager.shared();
        
        if (!favorite.favorite) {
            return manager?.delete_TASK(url, parameters: nil, success: success, failure: failure);
        } else {
            return manager?.put_TASK(url, parameters: nil, success: success, failure: failure);
        }
    }
    
    @objc public static func operationToPushImportant(important: ObservationImportant, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let eventId = important.observation?.eventId, let observationRemoteId = important.observation?.remoteId, let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(eventId)/observations/\(observationRemoteId)/important";
        NSLog("Trying to push favorite to server \(url)")
        
        let manager = MageSessionManager.shared();
        
        if (important.important) {
            let parameters: [String : String?] = [
                ObservationImportantKey.description.key : important.reason
            ]
            return manager?.put_TASK(url, parameters: parameters, success: success, failure: failure);
        } else {
            return manager?.delete_TASK(url, parameters: nil, success: success, failure: failure);
        }
    }
    
    static func operationToDelete(observation: Observation, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error?) -> Void)?) -> URLSessionDataTask? {
        NSLog("Trying to delete observation \(observation.url ?? "no url")");
        let deleteMethod = MAGERoutes.observation().deleteRoute(observation);
        
        let manager = MageSessionManager.shared();
        
        return manager?.post_TASK(deleteMethod.route, parameters: deleteMethod.parameters, progress: nil, success: { task, responseObject in
            // if the delete worked, remove the observation from the database on the phone
            MagicalRecord.save { context in
                observation.mr_deleteEntity(in: context);
            } completion: { contextDidSave, error in
                // TODO: why are we calling failure here?
                // I think because the ObservationPushService is going to try to parse the response and update the observation which we do not want
                failure?(task, nil);
            }
        }, failure: { task, error in
            NSLog("Failure to delete")
            let error = error as NSError
            if let data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data {
                let errorString = String(data: data, encoding: .utf8);
                NSLog("Error deleting observation \(errorString ?? "unknown error")");
                if let response = task?.response as? HTTPURLResponse {
                    if (response.statusCode == 404) {
                        // Observation does not exist on the server, delete it
                        MagicalRecord.save { context in
                            observation.mr_deleteEntity(in: context);
                        } completion: { contextDidSave, error in
                            // TODO: why are we calling failure here?
                            // I think because the ObservationPushService is going to try to parse the response and update the observation which we do not want
                            failure?(task, nil);
                        }
                    }
                } else {
                    failure?(task, error);
                }
            } else {
                failure?(task, error);
            }
        });
    }
    
    static func operationToUpdate(observation: Observation, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        NSLog("Trying to update observation \(observation.url ?? "unknown url")")
        let manager = MageSessionManager.shared();
        guard let context = observation.managedObjectContext, let event = Event.getCurrentEvent(context:context) else {
            return nil;
        }
        if (MageServer.isServerVersion5) {
            if let observationUrl = observation.url {
                return manager?.put_TASK(observationUrl, parameters: observation.createJsonToSubmit(event:event), success: success, failure: failure);
            }
        } else { //} if MageServer.isServerVersion6_0() {
            if let observationUrl = observation.url {
                return manager?.put_TASK(observationUrl, parameters: observation.createJsonToSubmit(event:event), success: success, failure: failure);
            }
        }
//        else {
//            // TODO: 6.1 and above
//            if let observationUrl = observation.url {
//                return manager?.patch_TASK(observationUrl, parameters: observation.createJsonToSubmit(event:event), success: success, failure: failure);
//            }
//        }
        return nil;
    }
    
    static func operationToCreate(observation: Observation, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        let create = MAGERoutes.observation().createId(observation);
        NSLog("Trying to create observation %@", create.route);
        let manager = MageSessionManager.shared();
        
        let task = manager?.post_TASK(create.route, parameters: nil, progress: nil, success: { task, response in
            NSLog("Successfully created location for observation resource");
            guard let response = response as? [AnyHashable : Any], let observationUrl = response[ObservationKey.url.key] as? String, let remoteId = response[ObservationKey.id.key] as? String else {
                return;
            }
            MagicalRecord.save { context in
                guard let localObservation = observation.mr_(in: context) else {
                    return;
                }
                localObservation.remoteId = remoteId
                localObservation.url = observationUrl;
            } completion: { contextDidSave, error in
                if !contextDidSave {
                    NSLog("Failed to save observation to DB after getting an ID")
                }
                guard let context = observation.managedObjectContext, let event = Event.getCurrentEvent(context: context) else {
                    return;
                }
                let putTask = manager?.put_TASK(observationUrl, parameters: observation.createJsonToSubmit(event:event), success: { task, response in
                    print("successfully submitted observation")
                    success?(task, response);
                }, failure: { task, error in
                    print("failure");
                });
                manager?.addTask(putTask);
            }
        }, failure: failure)
        return task;
    }
    
    func fieldNameToField(formId: NSNumber, name: String) -> [AnyHashable : Any]? {
        if let managedObjectContext = managedObjectContext, let form : Form = Form.mr_findFirst(byAttribute: "formId", withValue: formId, in: managedObjectContext) {
            return form.getFieldByName(name: name)
        }
        return nil
    }

    func createJsonToSubmit(event: Event) -> [AnyHashable : Any] {
        var observationJson: [AnyHashable : Any] = [:]
        
        if let remoteId = self.remoteId {
            observationJson[ObservationKey.id.key] = remoteId;
        }
        if let userId = self.userId {
            observationJson[ObservationKey.userId.key] = userId;
        }
        if let deviceId = self.deviceId {
            observationJson[ObservationKey.deviceId.key] = deviceId;
        }
        if let url = self.url {
            observationJson[ObservationKey.url.key] = url;
        }
        observationJson[ObservationKey.type.key] = "Feature";
        
        let state = self.state?.intValue ?? State.Active.rawValue
        observationJson[ObservationKey.state.key] = ["name":(State(rawValue: state) ?? .Active).description]
        
        if let geometry = self.geometry {
            observationJson[ObservationKey.geometry.key] = GeometrySerializer.serializeGeometry(geometry);
        }
        
        if let timestamp = self.timestamp {
            observationJson[ObservationKey.timestamp.key] = ISO8601DateFormatter.string(from: timestamp, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone]);
        }
        
        var jsonProperties : [AnyHashable : Any] = self.properties ?? [:]
        
        var attachmentsToDelete : [String: [String : [Attachment]]] = [:]
        if (!MageServer.isServerVersion5) {
            // check for attachments marked for deletion and be sure to add them to the form properties
            if let attachments = attachments {
                for case let attachment in attachments where attachment.markedForDeletion {
                    var attachmentsPerForm: [String : [Attachment]] = [:]
                    if let observationFormId = attachment.observationFormId, let currentAttachmentsPerForm = attachmentsToDelete[observationFormId] {
                        attachmentsPerForm = currentAttachmentsPerForm;
                    }
                    
                    var attachmentsInField: [Attachment] = [];
                    if let fieldName = attachment.fieldName, let currentAttachmentsInField = attachmentsPerForm[fieldName] {
                        attachmentsInField = currentAttachmentsInField;
                    }
                    
                    attachmentsInField.append(attachment);
                    if let fieldName = attachment.fieldName, let observationFormId = attachment.observationFormId {
                        attachmentsPerForm[fieldName] = attachmentsInField;
                        attachmentsToDelete[observationFormId] = attachmentsPerForm
                    }
                }
            }
        }
        
        let forms = jsonProperties[ObservationKey.forms.key] as? [[String: Any]]
        var formArray: [Any] = [];
        
        if let forms = forms {
            for form in forms {
                var formProperties: [String: Any] = form;
                for (key, value) in form {
                    if let formId = form[FormKey.formId.key] as? NSNumber {
                        if let field = self.fieldNameToField(formId: formId, name:key) {
                            if let fieldType = field[FieldKey.type.key] as? String, fieldType == FieldType.geometry.key {
                                if let fieldGeometry = value as? SFGeometry {
                                    formProperties[key] = GeometrySerializer.serializeGeometry(fieldGeometry);
                                }
                            }
                        }
                    }
                }
                
                // check for deleted attachments and add them to the proper field
                if let formId = form[FormKey.id.key] as? String, let attachmentsToDeleteForForm = attachmentsToDelete[formId] {
                    for (field, attachmentsToDeleteForField) in attachmentsToDeleteForForm {
                        var newAttachments: [[AnyHashable : Any]] = [];
                        if let value = form[field] as? [[AnyHashable : Any]] {
                            newAttachments = value;
                        }
                        for a in attachmentsToDeleteForField {
                            if let remoteId = a.remoteId {
                                newAttachments.append([
                                    AttachmentKey.id.key: remoteId,
                                    AttachmentKey.action.key: "delete"
                                ])
                            }
                        }
                        formProperties[field] = newAttachments;
                    }
                }
                formArray.append(formProperties);
            }
        }
        jsonProperties[ObservationKey.forms.key] = formArray;
        observationJson[ObservationKey.properties.key] = jsonProperties;
        
        return observationJson;
    }
    
    @objc public static func fetchLastObservationDate(context: NSManagedObjectContext) -> Date? {
        let user = User.fetchCurrentUser(context: context);
        if let userRemoteId = user?.remoteId, let currentEventId = Server.currentEventId() {
            let observation = Observation.mr_findFirst(with: NSPredicate(format: "\(ObservationKey.eventId.key) == %@ AND user.\(UserKey.remoteId.key) != %@", currentEventId, userRemoteId), sortedBy: ObservationKey.lastModified.key, ascending: false, in:context);
            return observation?.lastModified;
        }
        return nil;
    }
    
    @objc public static func create(geometry: SFGeometry?, accuracy: CLLocationAccuracy, provider: String?, delta: Double, context: NSManagedObjectContext) -> Observation {
        var observationDate = Date();
        observationDate = Calendar.current.date(bySetting: .second, value: 0, of: observationDate)!
        observationDate = Calendar.current.date(bySetting: .nanosecond, value: 0, of: observationDate)!
        
        let observation = Observation.mr_createEntity(in: context)!;
        observation.timestamp = observationDate;
        
        var properties: [AnyHashable : Any] = [:];
        properties[ObservationKey.timestamp.key] = ISO8601DateFormatter.string(from: observationDate, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
        if let geometry = geometry, let provider = provider {
            properties[ObservationKey.provider.key] = provider;
            if (provider != "manual") {
                properties[ObservationKey.accuracy.key] = accuracy;
                properties[ObservationKey.delta.key] = delta;
            }
            observation.geometry = geometry;
        }
        properties[ObservationKey.forms.key] = [];
        observation.properties = properties;
        observation.user = User.fetchCurrentUser(context: context);
        observation.dirty = false;
        observation.state = NSNumber(value: State.Active.rawValue)
        observation.eventId = Server.currentEventId();
        return observation;
    }
    
    static func idFromJson(json: [AnyHashable : Any]) -> String? {
        return json[ObservationKey.id.key] as? String
    }
    
    static func stateFromJson(json: [AnyHashable : Any]) -> State {
        if let stateJson = json[ObservationKey.state.key] as? [AnyHashable : Any], let stateName = stateJson["name"] as? String {
            if stateName == State.Archive.description {
                return State.Archive
            } else {
                return State.Active;
            }
        }
        return State.Active;
    }
    
    @objc public static func create(feature: [AnyHashable : Any], context:NSManagedObjectContext) -> Observation? {
        var newObservation: Observation? = nil;
        let eventId = Server.currentEventId();
        let remoteId = Observation.idFromJson(json: feature);
        
        let state = Observation.stateFromJson(json: feature);
        
        if let remoteId = remoteId, let existingObservation = Observation.mr_findFirst(byAttribute: ObservationKey.remoteId.key, withValue: remoteId, in: context) {
            // if the observation is archived, delete it
            if state == .Archive {
                NSLog("Deleting archived observation with id: %@", remoteId);
                existingObservation.mr_deleteEntity(in: context);
            } else if !existingObservation.isDirty {
                // if the observation is not dirty, and has been updated, update it
                if let lastModified = feature[ObservationKey.lastModified.key] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
                    let lastModifiedDate = formatter.date(from: lastModified) ?? Date();
                    if lastModifiedDate == existingObservation.lastModified {
                        // If the last modified date for this observation has not changed no need to update.
                        return newObservation
                    }
                }
                
                existingObservation.populate(json: feature);
                if let userId = existingObservation.userId {
                    existingObservation.user = User.mr_findFirst(byAttribute: ObservationKey.remoteId.key, withValue: userId, in: context);
                }
                
                if let importantJson = feature[ObservationKey.important.key] as? [String : Any] {
                    if let important = ObservationImportant.important(json: importantJson, context: context) {
                        important.observation = existingObservation;
                        existingObservation.observationImportant = important;
                    }
                } else if let existingObservationImportant = existingObservation.observationImportant {
                    existingObservationImportant.mr_deleteEntity(in: context);
                    existingObservation.observationImportant = nil;
                }
                
                let favoritesMap = existingObservation.favoritesMap;
                let favoriteUserIds = (feature[ObservationKey.favoriteUserIds.key] as? [String]) ?? []
                for favoriteUserId in favoriteUserIds {
                    if favoritesMap[favoriteUserId] == nil {
                        if let favorite = ObservationFavorite.favorite(userId: favoriteUserId, context: context) {
                            favorite.observation = existingObservation;
                            existingObservation.addToFavorites(favorite);
                        }
                    }
                }
                
                for (userId, favorite) in favoritesMap {
                    if !favoriteUserIds.contains(userId) {
                        favorite.mr_deleteEntity(in: context);
                        existingObservation.removeFromFavorites(favorite);
                    }
                }
                
                if let attachmentsJson = feature[ObservationKey.attachments.key] as? [[AnyHashable : Any]] {
                    for attachmentJson in attachmentsJson {
                        var attachmentFound = false;
                        if let remoteId = attachmentJson[AttachmentKey.id.key] as? String, let attachments = existingObservation.attachments {
                            
                            for attachment in attachments {
                                if remoteId == attachment.remoteId {
                                    attachment.contentType = attachmentJson[AttachmentKey.contentType.key] as? String
                                    attachment.name = attachmentJson[AttachmentKey.name.key] as? String
                                    attachment.size = attachmentJson[AttachmentKey.size.key] as? NSNumber
                                    attachment.url = attachmentJson[AttachmentKey.url.key] as? String
                                    attachment.remotePath = attachmentJson[AttachmentKey.remotePath.key] as? String
                                    attachment.observation = existingObservation;
                                    attachmentFound = true;
                                    break;
                                }
                            }
                        }
                        if !attachmentFound {
                            if let attachment = Attachment.attachment(json: attachmentJson, context: context) {
                                existingObservation.addToAttachments(attachment);
                            }
                        }
                    }
                }
                existingObservation.eventId = eventId;
            }
        } else {
            if state != .Archive {
                // if the observation doesn't exist, insert it
                if let observation = Observation.mr_createEntity(in: context) {
                    observation.eventId = eventId;
                    observation.populate(json: feature);
                    if let userId = observation.userId {
                        observation.user = User.mr_findFirst(byAttribute: UserKey.remoteId.key, withValue: userId, in: context);
                    }
                    
                    if let importantJson = feature[ObservationKey.important.key] as? [String : Any] {
                        if let important = ObservationImportant.important(json: importantJson, context: context) {
                            important.observation = observation;
                            observation.observationImportant = important;
                        }
                    }
                    
                    if let favoriteUserIds = feature[ObservationKey.favoriteUserIds.key] as? [String] {
                        for favoriteUserId in favoriteUserIds {
                            if let favorite = ObservationFavorite.favorite(userId: favoriteUserId, context: context) {
                                favorite.observation = observation;
                                observation.addToFavorites(favorite);
                            }
                        }
                    }
                    
                    if let attachmentsJson = feature[ObservationKey.attachments.key] as? [[AnyHashable : Any]] {
                        for attachmentJson in attachmentsJson {
                            if let attachment = Attachment.attachment(json: attachmentJson, context: context) {
                                observation.addToAttachments(attachment);
                            }
                        }
                    }
                    
                    newObservation = observation;
                }
            }
        }
        
        return newObservation;
    }
    
    @objc public static func isRectangle(points: [SFPoint]) -> Bool {
        let size = points.count
        
        if size == 4 || size == 5 {
            let point1 = points[0]
            let lastPoint = points[size - 1]
            let closed: Bool = point1.x == lastPoint.x && point1.y == lastPoint.y;
            if ((closed && size == 5) || (!closed && size == 4)) {
                let point2 = points[1]
                let point3 = points[2]
                let point4 = points[3]
                if ((point1.x == point2.x) && (point2.y == point3.y)) {
                    if ((point1.y == point4.y) && (point3.x == point4.x)) {
                        return true;
                    }
                } else if ((point1.y == point2.y) && (point2.x == point3.x)) {
                    if ((point1.x == point4.x) && (point3.y == point4.y)) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    }
    
    @discardableResult
    @objc public func populate(json: [AnyHashable : Any]) -> Observation {
        self.remoteId = Observation.idFromJson(json: json);
        self.userId = json[ObservationKey.userId.key] as? String
        self.deviceId = json[ObservationKey.deviceId.key] as? String
        self.dirty = false
        
        if let properties = json[ObservationKey.properties.key] as? [String : Any] {
            self.properties = self.generateProperties(propertyJson: properties);
        }
        
        if let lastModified = json[ObservationKey.lastModified.key] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            self.lastModified = formatter.date(from: lastModified);
        }
        
        if let timestamp = self.properties?[ObservationKey.timestamp.key] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            self.timestamp = formatter.date(from: timestamp);
        }
        
        self.url = json[ObservationKey.url.key] as? String
        let state = Observation.stateFromJson(json: json);
        self.state = NSNumber(value: state.rawValue)
        
        self.geometry = GeometryDeserializer.parseGeometry(json: json[ObservationKey.geometry.key] as? [AnyHashable : Any])
        return self;
    }
    
    func generateProperties(propertyJson: [String : Any]) -> [AnyHashable : Any] {
        var parsedProperties: [String : Any] = [:]
        
        if self.event == nil {
            return parsedProperties;
        }
        
        for (key, value) in propertyJson {
            if key == ObservationKey.forms.key {
                var forms:[[String : Any]] = []
                if let formsProperties = value as? [[String : Any]] {
                    for formProperties in formsProperties {
                        var parsedFormProperties:[String:Any] = formProperties;
                        if let formId = formProperties[EventKey.formId.key] as? NSNumber, let managedObjectContext = managedObjectContext, let form : Form = Form.mr_findFirst(byAttribute: "formId", withValue: formId, in: managedObjectContext) {
                            for (formKey, value) in formProperties {
                                if let field = form.getFieldByName(name: formKey) {
                                    if let type = field[FieldKey.type.key] as? String, type == FieldType.geometry.key {
                                        if let value = value as? [String: Any] {
                                            let geometry = GeometryDeserializer.parseGeometry(json: value)
                                            parsedFormProperties[formKey] = geometry;
                                        }
                                    }
                                }
                            }
                        }
                        forms.append(parsedFormProperties);
                    }
                }
                parsedProperties[ObservationKey.forms.key] = forms;
            } else {
                parsedProperties[key] = value;
            }
        }
        
        return parsedProperties;
    }
    
    @objc public func addTransientAttachment(attachment: Attachment) {
        self.transientAttachments.append(attachment);
    }
    
    @objc public var transientAttachments: [Attachment] = [];
    
    @objc public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self.geometryData = SFGeometryUtils.encode(newValue);
            }
        }
    }
    
    @objc public var location: CLLocation? {
        get {
            if let geometry = geometry, let centroid = SFGeometryUtils.centroid(of: geometry) {
                return CLLocation(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue);
            }
            return CLLocation(latitude: 0, longitude: 0);
        }
    }
    
    @objc public var isDirty: Bool {
        get {
            return self.dirty
        }
    }
    
    @objc public var isImportant: Bool {
        get {
            if let observationImportant = self.observationImportant, observationImportant.important {
                return true;
            }
            return false;
        }
    }
    
    @objc public var isDeletableByCurrentUser: Bool {
        get {
            guard let managedObjectContext = self.managedObjectContext,
                  let currentUser = User.fetchCurrentUser(context: managedObjectContext),
                  let event = self.event else {
                return false;
            }
        
            // if the user has update on the event
            if let userRemoteId = currentUser.remoteId,
               let acl = event.acl,
               let userAcl = acl[userRemoteId] as? [String : Any],
               let userPermissions = userAcl[PermissionsKey.permissions.key] as? [String] {
                if (userPermissions.contains(PermissionsKey.update.key)) {
                    return true;
                }
            }
            
            // if the user has DELETE_OBSERVATION permission
            if let role = currentUser.role, let rolePermissions = role.permissions {
                if rolePermissions.contains(PermissionsKey.DELETE_OBSERVATION.key) {
                    return true;
                }
            }

            // If the observation was created by this user
            if let userRemoteId = currentUser.remoteId, let user = self.user {
                if userRemoteId == user.remoteId {
                    return true;
                }
            }
            return false;
        }
    }
    
    @objc public var currentUserCanUpdateImportant: Bool {
        get {
            guard let managedObjectContext = self.managedObjectContext,
                  let currentUser = User.fetchCurrentUser(context: managedObjectContext),
                  let event = self.event else {
                      return false;
                  }
            
            // if the user has update on the event
            if let userRemoteId = currentUser.remoteId,
               let acl = event.acl,
               let userAcl = acl[userRemoteId] as? [String : Any],
               let userPermissions = userAcl[PermissionsKey.permissions.key] as? [String] {
                if (userPermissions.contains(PermissionsKey.update.key)) {
                    return true;
                }
            }
            
            // if the user has UPDATE_EVENT permission
            if let role = currentUser.role, let rolePermissions = role.permissions {
                if rolePermissions.contains(PermissionsKey.UPDATE_EVENT.key) {
                    return true;
                }
            }

            return false;
        }
    }
    
    var event : Event? {
        get {
            if let eventId = self.eventId, let managedObjectContext = self.managedObjectContext {
                return Event.getEvent(eventId: eventId, context: managedObjectContext)
            }
            return nil;
        }
    }
    
    @objc public var hasValidationError: Bool {
        get {
            if let error = self.error {
                return error[ObservationPushService.ObservationErrorStatusCode] != nil
            }
            return false;
        }
    }
    
    @objc public var errorMessage: String {
        get {
            if let error = self.error {
                if let errorMessage = error[ObservationPushService.ObservationErrorMessage] as? String {
                    return errorMessage
                } else if let errorMessage = error[ObservationPushService.ObservationErrorDescription] as? String {
                    return errorMessage
                }
            }
            return "";
        }
    }

    @objc public var formsToBeDeleted: NSMutableIndexSet = NSMutableIndexSet()
    
    @objc public func clearFormsToBeDeleted() {
        formsToBeDeleted = NSMutableIndexSet()
    }
    
    @objc public func addFormToBeDeleted(formIndex: Int) {
        self.formsToBeDeleted.add(formIndex);
    }
    
    @objc public func removeFormToBeDeleted(formIndex: Int) {
        self.formsToBeDeleted.remove(formIndex);
    }
    
    @objc public var primaryObservationForm: [AnyHashable : Any]? {
        get {
            if let properties = self.properties, let forms = properties[ObservationKey.forms.key] as? [[AnyHashable:Any]] {
                for (index, form) in forms.enumerated() {
                    // here we can ignore forms which will be deleted
                    if !self.formsToBeDeleted.contains(index) {
                        return form;
                    }
                }
            }
            return nil
        }
    }
    
    @objc public var primaryEventForm: Form? {
        get {
            
            if let primaryObservationForm = primaryObservationForm, let formId = primaryObservationForm[EventKey.formId.key] as? NSNumber {
                return Form.mr_findFirst(byAttribute: "formId", withValue: formId, in: managedObjectContext ?? NSManagedObjectContext.mr_default())
            }
            return nil;
        }
    }
    
    @objc public var primaryField: String? {
        get {
            if let primaryEventForm = primaryEventForm {
                return primaryEventForm.primaryMapField?[FieldKey.name.key] as? String
            }
            return nil
        }
    }
    
    @objc public var secondaryField: String? {
        get {
            if let primaryEventForm = primaryEventForm {
                return primaryEventForm.secondaryMapField?[FieldKey.name.key] as? String
            }
            return nil
        }
    }
    
    @objc public var primaryFieldText: String? {
        get {
            if let primaryField = primaryEventForm?.primaryMapField, let observationForms = self.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let primaryFieldName = primaryField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[primaryFieldName]
                return Observation.fieldValueText(value: value, field: primaryField)
            }
            return nil;
        }
    }
    
    @objc public var secondaryFieldText: String? {
        get {
            if let variantField = primaryEventForm?.secondaryMapField, let observationForms = self.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let variantFieldName = variantField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[variantFieldName]
                return Observation.fieldValueText(value: value, field: variantField)
            }
            return nil;
        }
    }
    
    @objc public var primaryFeedFieldText: String? {
        get {
            if let primaryFeedField = primaryEventForm?.primaryFeedField, let observationForms = self.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let primaryFeedFieldName = primaryFeedField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = primaryObservationForm?[primaryFeedFieldName]
                return Observation.fieldValueText(value: value, field: primaryFeedField)
            }
            return nil;
        }
    }
    
    @objc public var secondaryFeedFieldText: String? {
        get {
            if let secondaryFeedField = primaryEventForm?.secondaryFeedField, let observationForms = self.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let secondaryFeedFieldName = secondaryFeedField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[secondaryFeedFieldName]
                return Observation.fieldValueText(value: value, field: secondaryFeedField)
            }
            return nil;
        }
    }
    
    @objc public static func fieldValueText(value: Any?, field: [AnyHashable : Any]) -> String {
        guard let value = value, let type = field[FieldKey.type.key] as? String else {
            return "";
        }
        
        if type == FieldType.geometry.key {
            var geometry: SFGeometry?;
            if let valueDictionary = value as? [AnyHashable : Any] {
                geometry = GeometryDeserializer.parseGeometry(json: valueDictionary);
            } else {
                geometry = value as? SFGeometry
            }
            if let geometry = geometry, let centroid = SFGeometryUtils.centroid(of: geometry) {
                return "\(String(format: "%.6f", centroid.y.doubleValue)), \(String(format: "%.6f", centroid.x.doubleValue))"
            }
        } else if type == FieldType.date.key {
            if let value = value as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
                formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
                let date = formatter.date(from: value);
                return (date as NSDate?)?.formattedDisplay() ?? "";
            }
        } else if type == FieldType.checkbox.key {
            if let value = value as? Bool {
                if value {
                    return "YES"
                } else {
                    return "NO"
                }
            } else if let value = value as? NSNumber {
                if value == 1 {
                    return "YES"
                } else {
                    return "NO"
                }
            }
        } else if type == FieldType.numberfield.key {
            return String(describing:value);
        } else if type == FieldType.multiselectdropdown.key {
            if let value = value as? [String] {
                return value.joined(separator: ", ")
            }
        } else if (type == FieldType.textfield.key ||
                   type == FieldType.textarea.key ||
                   type == FieldType.email.key ||
                   type == FieldType.password.key ||
                   type == FieldType.radio.key ||
                   type == FieldType.dropdown.key) {
            if let value = value as? String {
                return value;
            }
        }
        return "";
    }
    
    @objc public func toggleFavorite(completion:((Bool,Error?) -> Void)?) {
        MagicalRecord.save({ [weak self] localContext in
            if let localObservation = self?.mr_(in: localContext),
               let user = User.fetchCurrentUser(context: localContext),
               let userRemoteId = user.remoteId {
                if let favorite = localObservation.favoritesMap[userRemoteId], favorite.favorite {
                    // toggle off
                    favorite.dirty = true;
                    favorite.favorite = false
                } else {
                    // toggle on
                    if let favorite = localObservation.favoritesMap[userRemoteId] {
                        favorite.dirty = true;
                        favorite.favorite = true
                        favorite.userId = userRemoteId
                    } else {
                        if let favorite = ObservationFavorite.mr_createEntity(in: localContext) {
                            localObservation.addToFavorites(favorite);
                            favorite.observation = localObservation;
                            favorite.dirty = true;
                            favorite.favorite = true
                            favorite.userId = userRemoteId
                        }
                    }
                }
            }
        }, completion: completion)
    }
    
    @objc public var favoritesMap: [String : ObservationFavorite] {
        get {
            var favoritesMap: [String:ObservationFavorite] = [:]
            if let favorites = self.favorites {
                for favorite in favorites {
                    if let userId = favorite.userId {
                        favoritesMap[userId] = favorite
                    }
                }
            }
            return favoritesMap
        }
    }
    
    @objc public func flagImportant(description: String, completion:((Bool,Error?) -> Void)?) {
        if !self.currentUserCanUpdateImportant {
            completion?(false, nil);
            return;
        }
        
        MagicalRecord.save({ [weak self] localContext in
            if let localObservation = self?.mr_(in: localContext),
               let user = User.fetchCurrentUser(context: localContext),
               let userRemoteId = user.remoteId {
                if let important = self?.observationImportant {
                    important.dirty = true;
                    important.important = true;
                    important.userId = userRemoteId;
                    important.reason = description
                    // this will get overridden by the server, but let's set an initial value so the UI has something to display
                    important.timestamp = Date();
                } else {
                    if let important = ObservationImportant.mr_createEntity(in: localContext) {
                        important.observation = localObservation
                        localObservation.observationImportant = important;
                        important.dirty = true;
                        important.important = true;
                        important.userId = userRemoteId;
                        important.reason = description
                        // this will get overridden by the server, but let's set an initial value so the UI has something to display
                        important.timestamp = Date();
                    }
                }
            }
        }, completion: completion)
    }
    
    @objc public func removeImportant(completion:((Bool,Error?) -> Void)?) {
        if !self.currentUserCanUpdateImportant {
            completion?(false, nil);
            return;
        }
        
        MagicalRecord.save({ [weak self] localContext in
            if let localObservation = self?.mr_(in: localContext),
               let user = User.fetchCurrentUser(context: localContext),
               let userRemoteId = user.remoteId {
                if let important = self?.observationImportant {
                    important.dirty = true;
                    important.important = false;
                    important.userId = userRemoteId;
                    important.reason = nil
                    // this will get overridden by the server, but let's set an initial value so the UI has something to display
                    important.timestamp = Date();
                } else {
                    if let important = ObservationImportant.mr_createEntity(in: localContext) {
                        important.observation = localObservation
                        localObservation.observationImportant = important;
                        important.dirty = true;
                        important.important = false;
                        important.userId = userRemoteId;
                        important.reason = nil
                        // this will get overridden by the server, but let's set an initial value so the UI has something to display
                        important.timestamp = Date();
                    }
                }
            }
        }, completion: completion)
    }
    
    @objc public func delete(completion:((Bool,Error?) -> Void)?) {
        if !self.isDeletableByCurrentUser {
            completion?(false, nil);
            return;
        }
        if self.remoteId != nil {
            self.state = NSNumber(value: State.Archive.rawValue)
            self.dirty = true
            self.managedObjectContext?.mr_saveToPersistentStore(completion: completion)
        } else {
            MagicalRecord.save({ [weak self] localContext in
                self?.mr_deleteEntity(in: localContext);
            }, completion: completion)
        }
    }
}
