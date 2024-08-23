//
//  AttachmentCreationCoordinatorTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import OHHTTPStubs
import UniformTypeIdentifiers
import Photos
import PhotosUI

@testable import MAGE

class MockAttachmentCreationCoordinatorDelegate: AttachmentCreationCoordinatorDelegate {
    func attachmentCreated(attachment: MAGE.AttachmentModel) {
        
    }
    

    let attachmentCreatedCalled = XCTestExpectation(description: "attachmentCreated called")
    let attachmentCreationCancelledCalled = XCTestExpectation(description: "attachmentCreationCancelled called")
    var createdAttachment: Attachment?

    func attachmentCreated(attachment: Attachment) {
        createdAttachment = attachment
        attachmentCreatedCalled.fulfill()
    }
    
    func attachmentCreated(fieldValue: [String : AnyHashable]) {
        
    }
    
    func attachmentCreationCancelled() {
        attachmentCreationCancelledCalled.fulfill()
    }
}

class AttachmentCreationCoordinatorTests: KIFSpec {
    
    override func spec() {
        
        describe("AttachmentCreationCoordinatorTests") {

            var attachmentCreationCoordinator: AttachmentCreationCoordinator!
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            func createGradientImage(startColor: UIColor, endColor: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
                let rect = CGRect(origin: .zero, size: size)
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = rect
                gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
                
                UIGraphicsBeginImageContext(gradientLayer.bounds.size)
                gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                guard let cgImage = image?.cgImage else { return UIImage() }
                return UIImage(cgImage: cgImage)
            }

            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                controller = UIViewController();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: window.bounds.size.width);
                view.autoSetDimension(.height, toSize: window.bounds.size.height);
                view.backgroundColor = .systemBackground;
                controller.view.addSubview(view);
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                HTTPStubs.removeAllStubs();
            }
            
            xit("presents the gallery") {
                let observation: Observation = Observation.mr_createEntity()!;
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.presentGallery();
                
                let mockPicker: UIImagePickerController = MockUIImagePickerController();
                mockPicker.sourceType = .camera;
                
                let info: [UIImagePickerController.InfoKey : Any] = [
                    .mediaType: UTType.image,
                    .editedImage: createGradientImage(startColor: .purple, endColor: .white, size: CGSize(width: 500, height: 500)),
                    .mediaMetadata: [ "mykey": "myvalue" ]
                ];
                
                attachmentCreationCoordinator.imagePickerController(mockPicker, didFinishPickingMediaWithInfo: info)

                self.wait(for: [ delegate.attachmentCreatedCalled ], timeout: 0.0)
                expect(delegate.createdAttachment).toNot(beNil());
                
                let createdAttachment: Attachment = delegate.createdAttachment!;
                FileManager.default.fileExists(atPath: createdAttachment.localPath!);
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(beTrue());
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal("image/jpeg"));
            }

            it("converts png to jpeg and marks the attachment as a jpeg") {

                let pngUrl = Bundle(for: AttachmentFieldViewTests.self).url(forResource: "test_image_attachment", withExtension: "png")!
                var assetId: String? = nil
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let addPngToLibrary = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: pngUrl)
                    let placeholder = addPngToLibrary?.placeholderForCreatedAsset
                    assetId = placeholder?.localIdentifier
                }
                let selectedAsset = PHAsset.fetchAssets(withLocalIdentifiers: [ assetId! ], options: nil).firstObject!
                let observation: Observation = Observation.mr_createEntity()!
                let delegate = MockAttachmentCreationCoordinatorDelegate()
                let attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)

                // there is no way to call the delegate method picker(picker:didFinishPicking:) because
                // the sdk provides no accessible constructor for the PHPickerResult struct. thanks, apple
                attachmentCreationCoordinator.handlePhoto(selectedAsset: selectedAsset, utType: UTType.png)
                self.wait(for: [ delegate.attachmentCreatedCalled ], timeout: 5.0)

                let createdAttachment: Attachment = delegate.createdAttachment!
                expect(createdAttachment).toNot(beNil())
                let createdJpegData = FileManager.default.contents(atPath: createdAttachment.localPath!)
                let jpegFirstBytes = Data([ 0xff, 0xd8, 0xff ])
                expect(createdJpegData).notTo(beNil())
                expect(createdJpegData?[0..<3]).to(equal(jpegFirstBytes))
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(beTrue());
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal("image/jpeg"));
                expect(createdAttachment.name).to(endWith(".jpeg"))
            }
            
            xit("choose a movie") {
                let observation: Observation = Observation.mr_createEntity()!;
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)

                let url = Bundle(for: AttachmentCreationCoordinatorTests.self).url(forResource: "testmovie", withExtension: "MOV")!
                
                print("URL is \(url)")
                
                let info: [UIImagePickerController.InfoKey : Any] = [
                    .mediaType: UTType.movie,
                    .mediaURL: url
                ];
                
                let mockPicker: UIImagePickerController = MockUIImagePickerController();
                mockPicker.sourceType = .camera;
                
                attachmentCreationCoordinator.imagePickerController(mockPicker, didFinishPickingMediaWithInfo: info)

                self.wait(for: [ delegate.attachmentCreatedCalled ], timeout: 10.0)
                expect(delegate.createdAttachment).toEventuallyNot(beNil());

                let createdAttachment: Attachment = delegate.createdAttachment!;
                FileManager.default.fileExists(atPath: createdAttachment.localPath!);
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(beTrue());
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal("video/mp4"));
            }
            
            xit("create a recording") {
                let observation: Observation = Observation.mr_createEntity()!;
                
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                let url = Bundle(for: AttachmentCreationCoordinatorTests.self).url(forResource: "testRecording", withExtension: "mp4")!
                
                let recording: Recording = Recording();
                recording.fileName = "testRecording.mp4";
                recording.filePath = url.absoluteString;
                recording.mediaType = "audio/mp4";
                
                attachmentCreationCoordinator.recordingAvailable(recording: recording);
                
                self.wait(for: [ delegate.attachmentCreatedCalled ]);
                expect(delegate.createdAttachment).toNot(beNil());
                
                let createdAttachment: Attachment = delegate.createdAttachment!;
                print("created attachment \(createdAttachment)")
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(beTrue());
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal(recording.mediaType));
                expect(createdAttachment.name).to(equal(recording.fileName))
                expect(createdAttachment.localPath).to(equal(recording.filePath))
            }
        }
    }
}
