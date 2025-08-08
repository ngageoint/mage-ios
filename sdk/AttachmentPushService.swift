//
//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//

import AFNetworking
import Combine
import Alamofire

enum AttachmentPushKeys: String {
    case attachmentPushFrequency,
         sessionIdentifier = "mil.nga.mage.background.attachment"
}

private struct AttachmentPushServiceProviderKey: InjectionKey {
    static var currentValue: AttachmentPushService = AttachmentPushServiceImpl()
}

extension InjectedValues {
    var attachmentPushService: AttachmentPushService {
        get { Self[AttachmentPushServiceProviderKey.self] }
        set { Self[AttachmentPushServiceProviderKey.self] = newValue }
    }
}

@objc protocol AttachmentPushService {
    func pushAttachments(_ attachments: [Attachment])
    func start(_ context: NSManagedObjectContext)
    func stop()
    var backgroundSessionCompletionHandler: (() -> Void)? { get set }
    var context: NSManagedObjectContext? { get }
    var started: Bool { get }
}

// TODO: This is temporary while obj-c classes are removed
@objc class AttachmentPushServiceProvider: NSObject {
    @objc static var instance: AttachmentPushServiceProvider = AttachmentPushServiceProvider()

    @objc func getAttachmentPushService() -> AttachmentPushService {
        @Injected(\.attachmentPushService)
        var attachmentPushService: AttachmentPushService
        
        return attachmentPushService
    }
}

@objc class AttachmentPushServiceImpl: NSObject, AttachmentPushService {
    @objc public var started: Bool = false
    @objc public var context: NSManagedObjectContext?
    
    @objc public var backgroundSessionCompletionHandler: (() -> Void)?
    
    var interval: TimeInterval
    var fetchedResultsControllerDelegate: AttachmentPushServiceImplFetchedResultsControllerDelgate!
    var fetchedResultsController: NSFetchedResultsController<Attachment>?;
    var pushTasks: [Int] = []
    var attachmentPushTimer: (any Cancellable)?
    var pushData: [Int: Data] = [:]
    
    override init() {
        interval = UserDefaults.standard.attachmentPushFrequency
        super.init()
        fetchedResultsControllerDelegate = AttachmentPushServiceImplFetchedResultsControllerDelgate()
        setUpFetchedResultsController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func start(_ context: NSManagedObjectContext) {
        self.context = context
        setUpFetchedResultsController()
    }
    
    @MainActor
    func handleTaskCompletion(uploadTasks: [URLSessionUploadTask]) {
        pushTasks = uploadTasks.compactMap(\.taskIdentifier)
        pushAttachments(fetchedResultsController?.fetchedObjects ?? [])
        scheduleTimer()
    }
    
    @objc public func stop() {
        if let timer = self.attachmentPushTimer {
            timer.cancel()
            self.attachmentPushTimer = nil;
        }
        self.fetchedResultsController = nil
        self.started = false
    }
    
    func setUpFetchedResultsController() {
        guard let context = self.context else { return }
        
        let request = Attachment.fetchRequest()
        request.predicate = NSPredicate(format: "\(AttachmentKey.observationRemoteId.key) != nil && \(AttachmentKey.dirty.key) == YES")
        request.sortDescriptors = [NSSortDescriptor(key: AttachmentKey.lastModified.key, ascending: false)]
        
        self.fetchedResultsController = NSFetchedResultsController<Attachment>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController?.delegate = fetchedResultsControllerDelegate
        try? self.fetchedResultsController?.performFetch()
    }
    
    func scheduleTimer() {
        if let timer = self.attachmentPushTimer {
            timer.cancel()
            self.attachmentPushTimer = nil;
        }
        
        self.attachmentPushTimer = DispatchQueue
            .global(qos: .utility)
            .schedule(after: DispatchQueue.SchedulerTimeType(.now()),
                      interval: .seconds(self.interval),
                      tolerance: .seconds(self.interval / 5)) { [weak self] in
            guard let self else { return }
                self.onTimerFire()
        }
    }
    
    func onTimerFire() {
        if !UserUtility.singleton.isTokenExpired {
            MageLogger.misc.debug("ATTACHMENT - push timer fired, checking for attachments to push")
            pushAttachments(fetchedResultsController?.fetchedObjects as? [Attachment] ?? [])
        }
    }
        
    func pushAttachments(_ attachments: [Attachment]) {
        MageLogger.misc.debug("XXX told to push attachments \(attachments)")
        if !DataConnectionUtilities.shouldPushAttachments() { return }
                
        for attachment in attachments {
            if let taskIdentifier = attachment.taskIdentifier, pushTasks.contains(taskIdentifier.intValue) {
                // already pushing this attachment
                continue
            }
            
            // determine if this is a delete or a push
            if attachment.markedForDeletion {
                self.deleteAttachment(attachment)
            } else {
                self.pushAttachment(attachment)
            }
        }
    }
    
    func deleteAttachment(_ attachment: Attachment) {
        guard let observationRemoteId = attachment.observation?.remoteId,
              let eventId = attachment.observation?.eventId?.intValue,
              let attachmentRemoteId = attachment.remoteId else { return }
        let delete = AttachmentService.deleteAttachment(eventId: eventId, observationRemoteId: observationRemoteId, attachmentRemoteId: attachmentRemoteId)
        
        MageSession.shared.session.request(delete)
            .responseData { response in
                switch response.result {
                case .success(_):
                    MageLogger.misc.debug("Attachment deleted")
                    guard let context = self.context else { return }
                    context.performAndWait {
                        guard let attachment = context.object(with: attachment.objectID) as? Attachment else {
                            return
                        }
                        context.delete(attachment)
                        try? context.save()
                    }
                case .failure(let error):
                    MageLogger.misc.error("Failure to delete attachment \(error)")
                }
            }

    }
    
    func pushAttachment(_ attachment: Attachment) {
        // Always work on the attachment's own context
        guard let context = self.context else {
            MageLogger.misc.debug("BBB: ATTACHMENT - no context available")
            return
        }

        // If we don't have a local path anymore, do NOT delete.
        // If server already knows about this attachment (remoteId or url), just mark it clean.
        // Otherwise leave it dirty and bail (user can retry when the file exists again).
        if (attachment.localPath == nil || attachment.localPath?.isEmpty == true) {
            if attachment.remoteId != nil || attachment.url != nil {
                context.performAndWait {
                    attachment.dirty = false
                    attachment.taskIdentifier = nil
                    try? context.save()
                }
            } else {
                MageLogger.misc.debug("BBB: ATTACHMENT - missing localPath for \(attachment.name ?? "<unnamed>"); leaving dirty (not deleting).")
            }
            return
        }

        // Resolve the file URL from localPath
        let fileURL: URL
        if let localPath = attachment.localPath, localPath.hasPrefix("file://") {
            guard let u = URL(string: localPath) else {
                MageLogger.misc.debug("BBB: ATTACHMENT - invalid file:// URL string: \(localPath)")
                return
            }
            fileURL = u
        } else if let localPath = attachment.localPath {
            fileURL = URL(fileURLWithPath: localPath)
        } else {
            // Shouldn't get here but be defensive
            MageLogger.misc.debug("BBB: ATTACHMENT - no localPath after earlier guard")
            return
        }

        // If the file is missing on disk after a reinstall/new container, do NOT delete the row.
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            if attachment.remoteId != nil || attachment.url != nil {
                // We already uploaded before — just mark clean
                context.performAndWait {
                    attachment.dirty = false
                    attachment.taskIdentifier = nil
                    try? context.save()
                }
                return
            } else {
                MageLogger.misc.debug("BBB: ATTACHMENT - file missing at path: \(fileURL.path); leaving dirty (not deleting).")
                return
            }
        }

        // Load the data to send
        guard let attachmentData = try? Data(contentsOf: fileURL) else {
            MageLogger.misc.debug("BBB: ATTACHMENT - failed reading data at path: \(fileURL.path)")
            return
        }

        // Build request identifiers
        guard let observationRemoteId = attachment.observation?.remoteId,
              let attachmentRemoteId = attachment.remoteId,
              let eventId = attachment.observation?.eventId?.intValue
        else {
            MageLogger.misc.debug("BBB: ATTACHMENT - missing identifiers (eventId/observationRemoteId/attachmentRemoteId)")
            return
        }

        let mimeType = attachment.contentType ?? "application/octet-stream"
        let fileName = attachment.name ?? fileURL.lastPathComponent

        // Multipart body
        let formData = MultipartFormData()
        formData.append(attachmentData,
                        withName: "attachment",
                        fileName: fileName,
                        mimeType: mimeType)

        // Build the request via your existing service
        let request = AttachmentService.uploadAttachment(
            eventId: eventId,
            observationRemoteId: observationRemoteId,
            attachmentRemoteId: attachmentRemoteId
        )

        MageLogger.misc.debug("BBB: ATTACHMENT - uploading \(fileName) (\(mimeType)) to \(request.urlRequest?.url?.absoluteString ?? "<nil>")")

        // Start the upload
        let uploader = MageSession.shared.session.upload(
            multipartFormData: formData,
            with: request
        )

        // Track the URLSession task id on the attachment
        uploader.onURLSessionTaskCreation { [weak self] _ in
            guard let self = self else { return }
            if let taskIdentifier = uploader.task?.taskIdentifier,
               self.pushTasks.contains(taskIdentifier) == false
            {
                self.pushTasks.append(taskIdentifier)
                self.context?.performAndWait {
                    if let obj = self.context?.object(with: attachment.objectID) as? Attachment {
                        obj.taskIdentifier = NSNumber(value: taskIdentifier)
                        try? self.context?.save()
                    }
                }
            }
        }
        .uploadProgress { progress in
            MageLogger.misc.debug("BBB: ATTACHMENT - upload progress \(progress.fractionCompleted)")
        }
        .response { [weak self] response in
            guard let self = self else { return }

            // If Alamofire gave us an error, use the existing handler (it expects the task id to still be set).
            if let error = response.error {
                self.attachmentUploadCompleteWithTask(response: response,
                                                      task: uploader.task,
                                                      error: error)
                return
            }

            // --- SUCCESS PATH ---
            // Parse server json (optional, best-effort)
            var returnedJSON: [AnyHashable: Any] = [:]
            if let data = response.data, !data.isEmpty,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any] {
                returnedJSON = obj
            }

            let finishedTaskId = uploader.task?.taskIdentifier

            // Persist fields and clear dirty flag
            if let context = self.context {
                context.performAndWait {
                    if let obj = context.object(with: attachment.objectID) as? Attachment {
                        if let urlStr = (returnedJSON["url"] as? String) ?? (returnedJSON["remotePath"] as? String) {
                            obj.url = urlStr
                        }
                        if let sizeNum = (returnedJSON["size"] as? NSNumber) ?? (returnedJSON["length"] as? NSNumber) {
                            obj.size = sizeNum
                        }
                        if let lm = returnedJSON["lastModified"] as? String {
                            obj.lastModified = Date.ISO8601FormatStyle.gmtZeroDate(from: lm)
                        } else {
                            obj.lastModified = Date()
                        }
                        obj.dirty = false
                        // IMPORTANT: clear it AFTER we grabbed finishedTaskId
                        obj.taskIdentifier = nil
                        try? context.save()
                    }
                }
            }

            // Remove from our in-memory queue
            if let id = finishedTaskId,
               let idx = self.pushTasks.firstIndex(of: id) {
                self.pushTasks.remove(at: idx)
            }

            MageLogger.misc.debug("BBB: ATTACHMENT - upload completed successfully for task \(finishedTaskId.map(String.init) ?? "<nil>")")
        }

    }

    
    func pushAttachment_OLD(_ attachment: Attachment) {
        guard let localPath = attachment.localPath,
            let attachmentData = try? Data(contentsOf: URL(filePath: localPath))
        else {
            MageLogger.misc.debug("Attachment data nil for observation: \(attachment.observation?.remoteId ?? "") at path: \(attachment.localPath ?? "")")
            guard let context = self.context else { return }
            context.performAndWait {
                guard let attachment = context.object(with: attachment.objectID) as? Attachment else {
                    return
                }
                context.delete(attachment)
                try? context.save()
            }
            return
        }
        
        let push = MAGERoutes.attachment().push(attachment)
        
        MageLogger.misc.debug("pushing attachment \(push.route)")

        guard let observationRemoteId = attachment.observation?.remoteId,
              let attachmentRemoteId = attachment.remoteId,
              let eventId = attachment.observation?.eventId?.intValue
        else { return }
        let formData = MultipartFormData()
        formData.append(attachmentData, withName: "attachment", fileName: attachment.name, mimeType: attachment.contentType ?? "application/octet-stream")
        let uploader = MageSession.shared.session.upload(multipartFormData: formData, with: AttachmentService.uploadAttachment(eventId: eventId, observationRemoteId: observationRemoteId, attachmentRemoteId: attachmentRemoteId))
        uploader.onURLSessionTaskCreation { task in
            if let taskIdentifier = uploader.task?.taskIdentifier,
               self.pushTasks.contains(taskIdentifier) == false
            {
                self.pushTasks.append(taskIdentifier)
                guard let context = self.context else { return }
                context.performAndWait {
                    attachment.taskIdentifier = NSNumber(value: taskIdentifier)
                    
                    try? context.save()
                }
            }
        }
        .uploadProgress { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
        }
        .response { response in
            self.attachmentUploadCompleteWithTask(response: response, task: uploader.task, error: response.error)
        }
    }
    
    
    func attachmentUploadReceivedData(data: Data, forTask: URLSessionTask) {
        MageLogger.misc.debug("ATTACHMENT - upload received data for task \(forTask)")
        let taskIdentifier = forTask.taskIdentifier
        
        if let existingData = pushData[taskIdentifier] {
            let data = existingData + data
            pushData[taskIdentifier] = data
        } else {
            pushData[taskIdentifier] = data
        }
    }
    
    func attachmentUploadCompleteWithTask(response: AFDataResponse<Data?>, task: URLSessionTask?, error: Error?) {
        if let request = task?.originalRequest, request.httpMethod == "DELETE" {
            MageLogger.misc.error("ATTACHMENT - delete complete with error \(error?.localizedDescription ?? "none")")
            return
        }
        
        let data = response.data
        let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
        
        if let error {
            MageLogger.misc.error("ATTACHMENT - upload complete with error \(error)")
            // try again
            removeTask(taskIdentifier: task?.taskIdentifier)
            return
        }
        
        if let httpResponse = task?.response as? HTTPURLResponse,
           httpResponse.statusCode != 200
        {
            MageLogger.misc.debug("ATTACHMENT - non 200 response, \(httpResponse)")
            if let json {
                MageLogger.misc.debug("ATTACHMENT - non 200 json response, \(json)")
            }
            // try again
            removeTask(taskIdentifier: task?.taskIdentifier)
            return
        }
        
        if data == nil {
            MageLogger.misc.debug("ATTACHMENT - error uploading attachment, did not receive response from the server")
            // try again
            removeTask(taskIdentifier: task?.taskIdentifier)
            return
        }
        
        guard let context else {
            return
        }
        
        context.performAndWait {
            guard let taskIdentifier = task?.taskIdentifier,
                  let attachment = context.fetchFirst(Attachment.self, key: "taskIdentifier", value: taskIdentifier)
            else {
                MageLogger.misc.debug("ATTACHMENT - error completing attachment upload, could not retrieve attachment for task id \("\(task?.taskIdentifier)")")
                return
            }
            
            guard let response = json else {
                // try again
                removeTask(taskIdentifier: taskIdentifier)
                return
            }
            
            attachment.dirty = false
            attachment.remoteId = response["id"] as? String
            attachment.name = response["name"] as? String
            attachment.url = response["url"] as? String
            attachment.taskIdentifier = nil
            if let dateString = response["lastModified"] as? String,
               let date = try? Date.ISO8601FormatStyle().parse(dateString)
            {
                attachment.lastModified = date
            }
            try? context.save()
            
            if let attachmentUrl = attachment.url {
                removeTask(taskIdentifier: taskIdentifier)
                // push local file to the image cache
                if (attachment.contentType ?? "").hasPrefix("image"),
                   let localPath = attachment.localPath,
                   FileManager.default.fileExists(atPath: localPath),
                   let fileData = FileManager.default.contents(atPath: localPath),
                   let image = UIImage(data: fileData)
                {
                    ImageCacheProvider.shared.cacheImage(image: image, key: attachmentUrl)
                }
                
                NotificationCenter.default.post(name: .AttachmentPushed, object: nil)
            } else {
                // try again
                removeTask(taskIdentifier: taskIdentifier)
                return
            }
        }
        
        if let handler = self.backgroundSessionCompletionHandler {
            MageLogger.misc.debug("ATTACHMENT - MageBackgroundSessionManager calling backgroundSessionCompletionHandler");
            self.backgroundSessionCompletionHandler = nil;
            handler()
        }
        
    }
    
    func removeTask(taskIdentifier: Int?) {
        if let taskIdentifier {
            pushTasks.removeAll { identifier in
                identifier == taskIdentifier
            }
        }
    }
}

final class AttachmentPushServiceImplFetchedResultsControllerDelgate : NSObject, NSFetchedResultsControllerDelegate {
    @Injected(\.attachmentPushService)
    var attachmentPushService: AttachmentPushService
    
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if let attachment = anObject as? Attachment {
            switch type {
            case .insert:
                Task {
                    attachmentPushService.pushAttachments([attachment])
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                Task {
                    attachmentPushService.pushAttachments([attachment])
                }
            @unknown default:
                break
            }
        }
    }
}
