//
//  AttachmentCreationCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 11/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import UniformTypeIdentifiers

@objc public protocol AudioRecordingDelegate {
    @objc func recordingAvailable(recording: Recording);
}

protocol AttachmentCreationCoordinatorDelegate: AnyObject {
    // can be removed after server 5
    func attachmentCreated(attachment: Attachment);
    
    func attachmentCreated(fieldValue: [String : AnyHashable]);
    func attachmentCreationCancelled();
}

class AttachmentCreationCoordinator: NSObject {
    var scheme: MDCContainerScheming?;
    var photoLocations: [TimeInterval : CLLocation] = [:]
    var photoHeadings: [TimeInterval : CLHeading] = [:]
    var locationManager: CLLocationManager?;
    weak var rootViewController: UIViewController?;
    var observation: Observation;
    var fieldName: String?;
    var observationFormId: String?;
    weak var delegate: AttachmentCreationCoordinatorDelegate?;
    var pickerController: UIImagePickerController?;
    var audioRecorderViewController: AudioRecorderViewController?;
    var workingOverlayController: AttachmentProgressViewController?;
    
    // this constructor is only used by the attachment card which is only for server version 5
    // can be removed when server version 5 is gone
    init(rootViewController: UIViewController?, observation: Observation, delegate: AttachmentCreationCoordinatorDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        self.rootViewController = rootViewController;
        self.observation = observation;
        self.delegate = delegate;
        self.scheme = scheme;
    }
    
    init(rootViewController: UIViewController?, observation: Observation, fieldName: String?, observationFormId: String?, delegate: AttachmentCreationCoordinatorDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        self.rootViewController = rootViewController;
        self.observation = observation;
        self.fieldName = fieldName;
        self.observationFormId = observationFormId;
        self.delegate = delegate;
        self.scheme = scheme;
    }
    
    public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
    }
    
    func addAttachmentForSaving(location: URL, contentType: String) {
        var attachmentJson: [String: AnyHashable] = [
            "type": contentType,
            "contentType": contentType,
            "localPath": location.path,
            "name": location.lastPathComponent
        ]
        DispatchQueue.main.async { [self] in
            // once server 5 goes away, this will always be the case
            if (self.observationFormId != nil || self.fieldName != nil) {
                attachmentJson["observationFormId"] = self.observationFormId
                attachmentJson["fieldName"] = self.fieldName
                attachmentJson["action"] = "add";
                delegate?.attachmentCreated(fieldValue: attachmentJson);
            } else {
                // this is only applicable in the server5 case, can be removed after that
                attachmentJson["dirty"] = 1;
                if let attachment = Attachment.attachment(json: attachmentJson, context: (observation.managedObjectContext)!) {
                    attachment.observation = observation;
                    delegate?.attachmentCreated(attachment: attachment);
                }
            }
        }
    }
    
    func initializeLocationManager() {
        // ask for permission
        locationManager = CLLocationManager();
        locationManager?.delegate = self;
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager?.distanceFilter = kCLDistanceFilterNone;
        locationManager?.headingFilter = kCLHeadingFilterNone;
        locationManager?.requestWhenInUseAuthorization();
    }
}

extension AttachmentCreationCoordinator: AttachmentCreationDelegate {
    func addFileAttachment() {
        print("Add file")
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        controller.delegate = self
        self.rootViewController?.present(controller, animated: true, completion: nil)
    }
    
    func addVoiceAttachment() {
        print("Add voice")
        ExternalDevice.checkMicrophonePermissions(for: self.rootViewController) { (permissionGranted) in
            self.presentVoiceRecorder()
        }
    }
    
    func presentVoiceRecorder() {
        DispatchQueue.main.async {
            print("Present the voice recorder");
            self.audioRecorderViewController = AudioRecorderViewController(delegate: self);
            self.rootViewController?.present(self.audioRecorderViewController!, animated: true);
        }
    }
    
    func addVideoAttachment() {
        print("Add video")
        ExternalDevice.checkCameraPermissions(for: self.rootViewController) { (permissionGranted) in
            if (permissionGranted) {
                ExternalDevice.checkMicrophonePermissions(for: self.rootViewController) { (permissionGranted) in
                    self.presentVideo()
                }
            }
        }
    }
    
    func presentVideo() {
        DispatchQueue.main.async {
            print("Present the video")
            self.pickerController = UIImagePickerController();
            self.pickerController!.delegate = self;
            self.pickerController!.allowsEditing = true;
            self.pickerController!.sourceType = .camera;
            self.pickerController!.mediaTypes = [UTType.movie.identifier];
            self.pickerController!.videoQuality = .typeHigh;
            self.rootViewController?.present(self.pickerController!, animated: true, completion: nil);
        }
    }
    
    func addCameraAttachment() {
        print("Add camera")
        ExternalDevice.checkCameraPermissions(for: self.rootViewController) { (permissionGranted) in
            if (permissionGranted) {
                self.initializeLocationManager()
                self.presentCamera();
            }
        }
    }
    
    func presentCamera() {
        DispatchQueue.main.async {
            print("Present the camera")
            self.pickerController = UIImagePickerController();
            self.pickerController!.delegate = self;
            self.pickerController!.sourceType = .camera;
            self.pickerController!.mediaTypes = [UTType.image.identifier];
            self.rootViewController?.present(self.pickerController!, animated: true, completion: nil);
        }
    }
    
    func addGalleryAttachment() {
        print("Add gallery")
        ExternalDevice.checkGalleryPermissions(for: self.rootViewController) { (permissionGranted) in
            if (permissionGranted) {
                self.presentGallery();
            }
        }
    }
    
    func presentGallery() {
        DispatchQueue.main.async { [weak self] in
            print("Present the gallery")
            var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = 1;
            
            // This is to compensate for iOS not setting all the colors on the PHPicker
            // it only sets the tint color not anything else, so let's make the button actually viewable
            UINavigationBar.appearance().tintColor = .systemBlue
            let photoPicker = PHPickerViewController(configuration: configuration);
            photoPicker.delegate = self;
            self?.rootViewController?.present(photoPicker, animated: true)
        }
    }
}

extension AttachmentCreationCoordinator: PHPickerViewControllerDelegate {
    
    func handlePhoto(phasset: PHAsset?, utType: UTType?) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            if let phasset = phasset {
                let dateFormatter = DateFormatter();
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
                
                let fileType = utType?.preferredFilenameExtension ?? "jpeg"
                let mimeType = utType?.preferredMIMEType ?? "image/jpeg"
                
                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return;
                }
                let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments")
                let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date())).\(fileType)");
                
                let manager = PHImageManager.default()
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .fastFormat
                requestOptions.isNetworkAccessAllowed = true
                
                manager.requestImageDataAndOrientation(for: phasset, options: requestOptions) { (data, fileName, orientation, info) in
                    if let data = data,
                       let cImage = CIImage(data: data) {
                        do {
                            try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete]);
                            
                            guard let finalData = cImage.qualityScaled() else { return }
                            
                            do {
                                try finalData.write(to: fileToWriteTo, options: .completeFileProtection)
                                self.addAttachmentForSaving(location: fileToWriteTo, contentType: mimeType)
                            } catch {
                                print("Unable to write image to file \(fileToWriteTo): \(error)")
                            }
                            
                        } catch {
                            print("Error creating directory path \(fileToWriteTo.deletingLastPathComponent()): \(error)")
                        }
                        
                    }
                }
            } else {
                galleryPermissionDenied()
            }
        }
    }
    
    func handleVideo(phasset: PHAsset?, utType: UTType?) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            if let phasset = phasset {
                
                let dateFormatter = DateFormatter();
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
                
                let manager = PHImageManager.default()
                let requestOptions = PHVideoRequestOptions()
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.isNetworkAccessAllowed = true
                
                manager.requestAVAsset(forVideo: phasset, options: requestOptions) { avAsset, audioMix, info in
                    guard let avAsset = avAsset else {
                        return
                    }
                    
                    let videoQuality: String = self.videoUploadQuality();
                    print("video quality \(videoQuality)")
                    let compatiblePresets: [String] = AVAssetExportSession.exportPresets(compatibleWith: avAsset);
                    if (compatiblePresets.contains(videoQuality)) {
                        guard let exportSession: AVAssetExportSession = AVAssetExportSession(asset: avAsset, presetName: videoQuality) else {
                            print("Export session not created")
                            return
                        }
                        let fileType = utType?.preferredFilenameExtension ?? "mp4"
                        let mimeType = utType?.preferredMIMEType ?? "video/mp4"
                        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                            return;
                        }
                        let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments")
                        let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date())).\(fileType)");
                        
                        do {
                            try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete]);
                            exportSession.outputURL = fileToWriteTo;
                            exportSession.outputFileType = .mp4;
                            print("exporting async")
                            exportSession.exportAsynchronously {
                                print("export session status \(exportSession.status)")
                                switch (exportSession.status) {
                                case .completed:
                                    print("Export complete")
                                    self.addAttachmentForSaving(location: fileToWriteTo, contentType: mimeType)
                                case .failed:
                                    print("Export Failed: \(String(describing: exportSession.error?.localizedDescription))")
                                case .cancelled:
                                    print("Export cancelled");
                                case .unknown:
                                    print("Unknown")
                                case .waiting:
                                    print("Waiting")
                                case .exporting:
                                    print("Exporting")
                                @unknown default:
                                    print("Unknown")
                                }
                            }
                        } catch {
                            print("Error creating directory path \(fileToWriteTo.deletingLastPathComponent()): \(error)")
                        }
                    }
                }
            } else {
               galleryPermissionDenied()
            }
        }
    
    }
    
    func galleryPermissionDenied() {
        // The user selected certain photos to share with MAGE and this wasn't one of them
        // prompt the user to pick more photos to share
        print("Cannot access asset")
        let alert = UIAlertController(title: "Permission Denied", message: "MAGE is unable to access the photo you have chosen.  Please update the photos MAGE is allowed to access and try again.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Update allowed photos", style: .default , handler:{ (UIAlertAction)in
            let library = PHPhotoLibrary.shared()
            library.register(self);
            if let rootViewController = self.rootViewController {
                library.presentLimitedLibraryPicker(from: rootViewController)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let rootViewController = self.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("picked a photo \(results)")
        // This is to compensate for iOS not setting all the colors on the PHPicker so now we have to set it back
        UINavigationBar.appearance().barTintColor = self.scheme?.colorScheme.primaryColorVariant

        guard !results.isEmpty else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
        
        for result in results {
            let itemProvider = result.itemProvider
            
            // find the first type that we can handle
            for typeIdentifier in itemProvider.registeredTypeIdentifiers {
                guard let utType = UTType(typeIdentifier) else {
                    continue
                }
                // Matches both com.apple.live-photo-bundle and com.apple.private.live-photo-bundle
                if utType.conforms(to: .image) || typeIdentifier.contains("live-photo-bundle") {
                    if let assetIdentifier = result.assetIdentifier {
                        let options = PHFetchOptions()
                        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                        handlePhoto(phasset: fetchResult.firstObject, utType: utType)
                        picker.dismiss(animated: true, completion: nil)
                        return
                    }
                }
                
                // otherwise it should be a movie
                if utType.conforms(to: .movie), let assetIdentifier = result.assetIdentifier {
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                    handleVideo(phasset: fetchResult.firstObject, utType: utType)
                    picker.dismiss(animated: true, completion: nil)
                    return
                }
            }
            MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Could not handle asset of types: \(itemProvider.registeredTypeIdentifiers)"))
        }
    }
}

extension AttachmentCreationCoordinator: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let library = PHPhotoLibrary.shared()
        library.unregisterChangeObserver(self);
        // show the image picker again
        self.presentGallery();
    }
}

extension AttachmentCreationCoordinator: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("picked a picture \(info)")
        
        picker.dismiss(animated: true, completion: nil);
        
        let mediaType = info[.mediaType] as? String;
        if (mediaType == UTType.image.identifier && picker.sourceType == .camera) {
            handleCameraImage(picker: picker, info: info);
        } else if (mediaType == UTType.movie.identifier) {
            handleMovie(picker: picker, info: info);
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
        delegate?.attachmentCreationCancelled();
        locationManager?.stopUpdatingHeading();
        locationManager?.stopUpdatingLocation();
        photoHeadings.removeAll();
        photoLocations.removeAll();
    }
    
    func handleCameraImage(picker: UIImagePickerController, info: [UIImagePickerController.InfoKey : Any]) {
        locationManager?.stopUpdatingHeading();
        locationManager?.stopUpdatingLocation();
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
        
        if let chosenImage = info[.originalImage] as? UIImage,
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
                let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date())).jpeg");
                let originalFileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date()))_original.jpeg");

                do {
                    try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete]);
//                    let finalImage = chosenImage.qualityScaled();
                    guard let imageData = chosenImage.qualityScaled() else { return };
                    var metadata: [AnyHashable : Any] = info[.mediaMetadata] as? [AnyHashable : Any] ?? [:];
                    
                    if let gpsDictionary = createGpsExifData(metadata: metadata) {
                        metadata[kCGImagePropertyGPSDictionary] = gpsDictionary
                    }
                    
                    guard let finalData = writeMetadataIntoImageData(imagedata: imageData, metadata: NSDictionary(dictionary: metadata)) else { return };
                    do {
                        try finalData.write(to: fileToWriteTo, options: .completeFileProtection)
                        
                        addAttachmentForSaving(location: fileToWriteTo, contentType: "image/jpeg")
                    } catch {
                        print("Unable to write image to file \(fileToWriteTo): \(error)")
                    }
                    
                    // save the original image that was not resized to the photo library, with GPS data
                    guard let originalImageData = chosenImage.jpegData(compressionQuality: 1.0) else { return };
                    guard let originalWithGPS = writeMetadataIntoImageData(imagedata: originalImageData, metadata: NSDictionary(dictionary: metadata)) else { return };
                    do {
                        try originalWithGPS.write(to: originalFileToWriteTo, options: .completeFileProtection)

                        try? PHPhotoLibrary.shared().performChangesAndWait {
                            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: originalFileToWriteTo)
                        }
                        
                        try FileManager.default.removeItem(at: originalFileToWriteTo);

                    } catch {
                        print("Unable to write image to file \(originalFileToWriteTo): \(error)")
                    }
                } catch {
                    print("Error creating directory path \(fileToWriteTo.deletingLastPathComponent()): \(error)")
                }
                photoHeadings.removeAll();
                photoLocations.removeAll();
            }
        }
    }
    
    func writeMetadataIntoImageData(imagedata: Data, metadata: NSDictionary?) -> Data? {
        // Add metadata to jpgData
        guard let source = CGImageSourceCreateWithData(imagedata as CFData, nil),
              let uniformTypeIdentifier = CGImageSourceGetType(source) else { return nil; }
        let finalData = NSMutableData(data: imagedata)
        guard let destination = CGImageDestinationCreateWithData(finalData, uniformTypeIdentifier, 1, nil) else { return nil; }
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
        guard CGImageDestinationFinalize(destination) else { return nil; }
        return finalData as Data;
    }
    
    func createGpsExifFromLocation(location: CLLocation?, heading: CLHeading?) -> [AnyHashable : Any]? {
        guard let location: CLLocation = location else {
            return nil;
        }
        
        let metersPerSecondMeasurement = Measurement(value: location.speed, unit: UnitSpeed.metersPerSecond);
        
        var gpsDictionary: [AnyHashable : Any] = [
            kCGImagePropertyGPSLatitude: location.coordinate.latitude,
            kCGImagePropertyGPSLongitude: location.coordinate.longitude,
            kCGImagePropertyGPSSpeed: metersPerSecondMeasurement.converted(to: UnitSpeed.kilometersPerHour),
            kCGImagePropertyGPSSpeedRef: "K",
            kCGImagePropertyGPSTrack: location.course,
            kCGImagePropertyGPSTrackRef: "T",
            kCGImagePropertyGPSAltitude: location.altitude,
            kCGImagePropertyGPSAltitudeRef: 0
        ];
        
        if let heading: CLHeading = heading {
            gpsDictionary[kCGImagePropertyGPSImgDirection] = heading.trueHeading;
            gpsDictionary[kCGImagePropertyGPSImgDirectionRef] = "T";
            gpsDictionary[kCGImagePropertyGPSDestBearing] = heading.trueHeading;
            gpsDictionary[kCGImagePropertyGPSDestBearingRef] = "T";
        }
        return gpsDictionary;
    }
    
    func createGpsExifData(metadata: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        if (photoLocations.count != 0) {
            if let exifDictionary = metadata[kCGImagePropertyExifDictionary] as? [AnyHashable : AnyObject], let dateTimeString = exifDictionary[kCGImagePropertyExifDateTimeOriginal] as? String {
                let dateFormatter = DateFormatter();
                dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss";
                dateFormatter.locale = Locale(identifier: "en_US_POSIX");
                let dateTimeOfImage = dateFormatter.date(from: dateTimeString);
                let timeIntervalOfImage = dateTimeOfImage?.timeIntervalSince1970 ?? 0;
                
                let sortedKeys: [TimeInterval] = photoLocations.keys.sorted(by: <);
                let firstLocationAfterImageIndex = sortedKeys.firstIndex { time in
                    return time > timeIntervalOfImage
                } ?? sortedKeys.count - 1;
                
                var maybeLocation: CLLocation? = photoLocations[sortedKeys[firstLocationAfterImageIndex]]
                
                if (firstLocationAfterImageIndex != 0) {
                    let locationTimeBeforeImage = sortedKeys[firstLocationAfterImageIndex - 1]
                    let locationTimeAfterImage = sortedKeys[firstLocationAfterImageIndex]
                    if ((timeIntervalOfImage - locationTimeBeforeImage) <= (locationTimeAfterImage - timeIntervalOfImage)) {
                        maybeLocation = photoLocations[sortedKeys[firstLocationAfterImageIndex - 1]]
                    }
                }
                
                var maybeHeading: CLHeading?;
                if (photoHeadings.count != 0) {
                    let sortedHeadingKeys: [TimeInterval] = photoHeadings.keys.sorted(by: <);
                    let firstHeadingAfterImageIndex = sortedHeadingKeys.firstIndex { time in
                        return time > timeIntervalOfImage
                    } ?? sortedHeadingKeys.count - 1;
                    
                    maybeHeading = photoHeadings[sortedHeadingKeys[firstHeadingAfterImageIndex]]
                    
                    if (firstHeadingAfterImageIndex != 0) {
                        let headingTimeBeforeImage = sortedHeadingKeys[firstHeadingAfterImageIndex - 1]
                        let headingTimeAfterImage = sortedHeadingKeys[firstHeadingAfterImageIndex]
                        if ((timeIntervalOfImage - headingTimeBeforeImage) <= (headingTimeAfterImage - timeIntervalOfImage)) {
                            maybeHeading = photoHeadings[sortedHeadingKeys[firstHeadingAfterImageIndex - 1]]
                        }
                    }
                }
                
                return createGpsExifFromLocation(location: maybeLocation, heading: maybeHeading);
            }
        }
        return nil;
    }

    func handleMovie(picker: UIImagePickerController, info: [UIImagePickerController.InfoKey : Any]) {
        print("handling movie \(info)")
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
        guard let videoUrl = info[.mediaURL] as? URL else { return }
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        if (picker.sourceType == .camera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoUrl.path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.path, nil, nil, nil);
        }
        let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
        let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date())).mp4");
        
        let videoQuality: String = videoUploadQuality();
        print("video quality \(videoQuality)")
        let avAsset = AVURLAsset(url: videoUrl);
        let compatiblePresets: [String] = AVAssetExportSession.exportPresets(compatibleWith: avAsset);
        if (compatiblePresets.contains(videoQuality)) {
            guard let exportSession: AVAssetExportSession = AVAssetExportSession(asset: avAsset, presetName: videoQuality) else {
                print("Export session not created")
                return
            }
            do {
                try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete]);
                exportSession.outputURL = fileToWriteTo;
                exportSession.outputFileType = .mp4;
                print("exporting async")
                exportSession.exportAsynchronously {
                    print("export session status \(exportSession.status)")
                    switch (exportSession.status) {
                        case .completed:
                            print("Export complete")
                            self.addAttachmentForSaving(location: fileToWriteTo, contentType: "video/mp4")
                        case .failed:
                            print("Export Failed: \(String(describing: exportSession.error?.localizedDescription))")
                        case .cancelled:
                            print("Export cancelled");
                        case .unknown:
                            print("Unknown")
                        case .waiting:
                            print("Waiting")
                        case .exporting:
                            print("Exporting")
                        @unknown default:
                            print("Unknown")
                        }
                }
            } catch {
                print("Error creating directory path \(fileToWriteTo.deletingLastPathComponent()): \(error)")
            }
        }
    }
    
    func videoUploadQuality() -> String {
        let videoDefaults = UserDefaults.standard.videoUploadQualities;
        let videoUploadQualityPreference: String = UserDefaults.standard.string(forKey: videoDefaults?["preferenceKey"] as? String ?? "videoUploadSize") ?? AVAssetExportPresetHighestQuality;
        
        if (videoUploadQualityPreference == AVAssetExportPresetLowQuality) {
            return AVAssetExportPresetLowQuality;
        } else if (videoUploadQualityPreference == AVAssetExportPresetMediumQuality) {
            return AVAssetExportPresetMediumQuality;
        }
        return AVAssetExportPresetHighestQuality;
    }
}

extension AttachmentCreationCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            let uttype = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
            addAttachmentForSaving(location: url, contentType: uttype?.preferredMIMEType ?? (UTType.item.preferredMIMEType ?? ""))
        }
    }
}

extension AttachmentCreationCoordinator: UINavigationControllerDelegate {
    
}

extension AttachmentCreationCoordinator: AudioRecordingDelegate {
    func recordingAvailable(recording: Recording) {
        print("Recording available")
        addAttachmentForSaving(location: URL(fileURLWithPath: recording.filePath!), contentType: recording.mediaType!)
    
        self.audioRecorderViewController?.dismiss(animated: true, completion: nil);
    }
}

extension AttachmentCreationCoordinator: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedAlways || status == .authorizedWhenInUse) {
            locationManager?.startUpdatingLocation();
            locationManager?.startUpdatingHeading();
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // save the locations so we can get the correct one when an image is taken
        for location in locations {
            photoLocations[location.timestamp.timeIntervalSince1970] = location;
            print("location to be saved is \(location)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        photoHeadings[newHeading.timestamp.timeIntervalSince1970] = newHeading;
        print("heading to be saved is \(newHeading)")
    }
}
