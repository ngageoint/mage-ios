//
//  AttachmentCreationCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 11/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol AudioRecordingDelegate {
    @objc func recordingAvailable(recording: Recording);
}

protocol AttachmentCreationCoordinatorDelegate {
    // can be removed after server 5
    func attachmentCreated(attachment: Attachment);
    
    func attachmentCreated(fieldValue: [String : AnyHashable]);
    func attachmentCreationCancelled();
}

class AttachmentCreationCoordinator: NSObject {
    weak var rootViewController: UIViewController?;
    var observation: Observation;
    var fieldName: String?;
    var observationFormId: String?;
    var delegate: AttachmentCreationCoordinatorDelegate?;
    var pickerController: UIImagePickerController?;
    var audioRecorderViewController: AudioRecorderViewController?;
    
    // this constructor is only used by the attachment card which is only for server version 5
    // can be removed when server version 5 is gone
    init(rootViewController: UIViewController?, observation: Observation, delegate: AttachmentCreationCoordinatorDelegate? = nil) {
        self.rootViewController = rootViewController;
        self.observation = observation;
        self.delegate = delegate;
    }
    
    init(rootViewController: UIViewController?, observation: Observation, fieldName: String, observationFormId: String, delegate: AttachmentCreationCoordinatorDelegate? = nil) {
        self.rootViewController = rootViewController;
        self.observation = observation;
        self.fieldName = fieldName;
        self.observationFormId = observationFormId;
        self.delegate = delegate;
    }
    
    func addAttachmentForSaving(location: URL, contentType: String) {
        var attachmentJson: [String: AnyHashable] = [
            "type": contentType,
            "contentType": contentType,
            "localPath": location.path,
            "name": location.lastPathComponent
        ]
        DispatchQueue.main.async { [self] in
            if (self.observationFormId != nil) {
                attachmentJson["observationFormId"] = self.observationFormId!
                attachmentJson["fieldName"] = self.fieldName!
                delegate?.attachmentCreated(fieldValue: attachmentJson);
            } else {
                // this is only applicable in the server5 case, can be removed after that
                attachmentJson["dirty"] = 1;
                let attachment = Attachment(forJson: attachmentJson, in: (observation.managedObjectContext)!);
                attachment.observation = observation;
                delegate?.attachmentCreated(attachment: attachment);
            }
        }
    }
}

extension AttachmentCreationCoordinator: AttachmentCreationDelegate {
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
            self.pickerController!.mediaTypes = [kUTTypeMovie as String];
            self.pickerController!.videoQuality = .typeHigh;
            self.rootViewController?.present(self.pickerController!, animated: true, completion: nil);
        }
    }
    
    func addCameraAttachment() {
        print("Add camera")
        ExternalDevice.checkCameraPermissions(for: self.rootViewController) { (permissionGranted) in
            if (permissionGranted) {
                self.presentCamera();
            }
        }
    }
    
    func presentCamera() {
        DispatchQueue.main.async {
            print("Present the camera")
            self.pickerController = UIImagePickerController();
            self.pickerController!.delegate = self;
            self.pickerController!.allowsEditing = true;
            self.pickerController!.sourceType = .camera;
            self.pickerController!.mediaTypes = [kUTTypeImage as String];
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
        DispatchQueue.main.async {
            print("Present the gallery")
            self.pickerController = UIImagePickerController();
            self.pickerController!.delegate = self;
            self.pickerController!.allowsEditing = true;
            self.pickerController!.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            self.pickerController!.sourceType = .photoLibrary;
            self.pickerController!.videoQuality = .typeHigh;
            self.rootViewController?.present(self.pickerController!, animated: true, completion: nil);
        }
    }
    
}

extension AttachmentCreationCoordinator: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("picked a picture \(info)")
        
        let mediaType = info[.mediaType] as? String;
        if (mediaType == kUTTypeImage as String) {
            handleImage(picker: picker, info: info);
        } else if (mediaType == kUTTypeMovie as String) {
            handleMovie(picker: picker, info: info);
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
        delegate?.attachmentCreationCancelled();
    }
    
    func handleImage(picker: UIImagePickerController, info: [UIImagePickerController.InfoKey : Any]) {
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss";
        
        if let chosenImage = info[.editedImage] as? UIImage,
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if (picker.sourceType == .camera) {
                UIImageWriteToSavedPhotosAlbum(chosenImage, nil, nil, nil);
            }
            let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
            let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_\(dateFormatter.string(from: Date())).jpeg");
            do {
                try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete]);
                let finalImage = chosenImage.qualityScaled();
                guard let imageData = finalImage.jpegData(compressionQuality: 1.0) else { return };
                guard let finalData = writeMetadataIntoImageData(imagedata: imageData, metadata: info[.mediaMetadata] as? NSMutableDictionary) else { return };
                do {
                    try finalData.write(to: fileToWriteTo, options: .completeFileProtection)
                    addAttachmentForSaving(location: fileToWriteTo, contentType: "image/jpeg")
                } catch {
                    print("Unable to write image to file \(fileToWriteTo): \(error)")
                }
            } catch {
                print("Error creating directory path \(fileToWriteTo.deletingLastPathComponent()): \(error)")
            }
        }
        picker.dismiss(animated: true, completion: nil);
    }
    
    func writeMetadataIntoImageData(imagedata: Data, metadata: NSMutableDictionary?) -> Data? {
        // Add metadata to jpgData
        guard let source = CGImageSourceCreateWithData(imagedata as CFData, nil),
              let uniformTypeIdentifier = CGImageSourceGetType(source) else { return nil; }
        let finalData = NSMutableData(data: imagedata)
        guard let destination = CGImageDestinationCreateWithData(finalData, uniformTypeIdentifier, 1, nil) else { return nil; }
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
        guard CGImageDestinationFinalize(destination) else { return nil; }
        return finalData as Data;
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
            
        picker.dismiss(animated: true, completion: nil);
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

extension AttachmentCreationCoordinator: UINavigationControllerDelegate {
    
}

extension AttachmentCreationCoordinator: AudioRecordingDelegate {
    func recordingAvailable(recording: Recording) {
        print("Recording available")
        addAttachmentForSaving(location: URL(fileURLWithPath: "\(recording.filePath!)/\(recording.fileName!)"), contentType: recording.mediaType!)
    
        self.audioRecorderViewController?.dismiss(animated: true, completion: nil);
    }
}
