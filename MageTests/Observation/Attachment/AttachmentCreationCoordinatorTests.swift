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
import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class MockAttachmentCreationCoordinatorDelegate: AttachmentCreationCoordinatorDelegate {
    var attachmentCreatedCalled = false;
    var createdAttachment: Attachment?;
    var attachmentCreationCancelledCalled = false;
    func attachmentCreated(attachment: Attachment) {
        createdAttachment = attachment;
        attachmentCreatedCalled = true;
    }
    
    func attachmentCreationCancelled() {
        attachmentCreationCancelledCalled = true;
    }
}

class AttachmentCreationCoordinatorTests: KIFSpec {
    
    override func spec() {
        
        describe("AttachmentCreationCoordinatorTests") {
            let recordSnapshots = false;
            
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
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, usesDrawRect: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.5);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: usesDrawRect);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(frame: UIScreen.main.bounds);
                
                controller = UIViewController();
                window.rootViewController = controller;
                window.makeKeyAndVisible();
                
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: window.bounds.size.width);
                view.autoSetDimension(.height, toSize: window.bounds.size.height);
                view.backgroundColor = .systemBackground;
                controller.view.addSubview(view);
                                
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                HTTPStubs.removeAllStubs();
            }
            
            it("present gallery") {
                let observation: Observation = Observation.mr_createEntity()!;
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.addGalleryAttachment();
                
                tester().waitForAnimationsToFinish();
                expect(attachmentCreationCoordinator.pickerController).toEventuallyNot(beNil());
                expect(attachmentCreationCoordinator.pickerController?.mediaTypes).toEventually(contain(kUTTypeImage as String, kUTTypeMovie as String))
                
                let info: [UIImagePickerController.InfoKey : Any] = [
                    .mediaType: kUTTypeImage as String,
                    .editedImage: createGradientImage(startColor: .purple, endColor: .white, size: CGSize(width: 500, height: 500)),
                    .mediaMetadata: [ "mykey": "myvalue" ]
                ];
                
                attachmentCreationCoordinator.pickerController!.delegate?.imagePickerController?(attachmentCreationCoordinator.pickerController!, didFinishPickingMediaWithInfo: info);
                
                expect(delegate.attachmentCreatedCalled).to(beTrue());
                expect(delegate.createdAttachment).toNot(beNil());
                
                let createdAttachment: Attachment = delegate.createdAttachment!;
                FileManager.default.fileExists(atPath: createdAttachment.localPath!);
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(equal(1));
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal("image/jpeg"));

            }
            
            it("choose a movie") {
                let observation: Observation = Observation.mr_createEntity()!;
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.addGalleryAttachment();
                
                expect(attachmentCreationCoordinator.pickerController).toEventuallyNot(beNil());
                expect(attachmentCreationCoordinator.pickerController?.mediaTypes).toEventually(contain(kUTTypeImage as String, kUTTypeMovie as String))

                let url = Bundle(for: AttachmentCreationCoordinatorTests.self).url(forResource: "testmovie", withExtension: "MOV")!
                
                print("URL is \(url)")
                
                let info: [UIImagePickerController.InfoKey : Any] = [
                    .mediaType: kUTTypeMovie as String,
                    .mediaURL: url
                ];

                attachmentCreationCoordinator.pickerController!.delegate?.imagePickerController?(attachmentCreationCoordinator.pickerController!, didFinishPickingMediaWithInfo: info);
                
                expect(delegate.attachmentCreatedCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Movie failed to export");
                expect(delegate.createdAttachment).toEventuallyNot(beNil());

                let createdAttachment: Attachment = delegate.createdAttachment!;
                FileManager.default.fileExists(atPath: createdAttachment.localPath!);
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(equal(1));
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal("video/mp4"));
            }
            
            it("create a recording") {
                let observation: Observation = Observation.mr_createEntity()!;
                
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                let recording: Recording = Recording();
                recording.fileName = "recording.mp4";
                recording.filePath = "/path/to/file/recording.mp4";
                recording.mediaType = "audio/mp4";
                
                attachmentCreationCoordinator.recordingAvailable(recording);
                
                expect(delegate.attachmentCreatedCalled).toEventually(beTrue());
                expect(delegate.createdAttachment).toNot(beNil());
                
                let createdAttachment: Attachment = delegate.createdAttachment!;
                print("created attachment \(createdAttachment)")
                expect(createdAttachment.lastModified).toNot(beNil());
                expect(createdAttachment.dirty).to(equal(1));
                expect(createdAttachment.observation).to(equal(observation));
                expect(createdAttachment.remoteId).to(beNil());
                expect(createdAttachment.remotePath).to(beNil());
                expect(createdAttachment.url).to(beNil());
                expect(createdAttachment.contentType).to(equal(recording.mediaType));
                expect(createdAttachment.name).to(equal(recording.fileName))
                expect(createdAttachment.localPath).to(equal(recording.filePath))
            }
            
            // this will simply present an alert about the camera not being available on the simulator
            // good enough to verify it tried to launch
            it("present camera") {
                let observation = Observation();
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.addCameraAttachment();
                
                tester().waitForAnimationsToFinish();
                
                expect(UIApplication.getTopViewController()?.isKind(of: NSClassFromString("UIAlertController")!)).toEventually(beTrue());
                
                tester().waitForView(withAccessibilityLabel: "No Camera");
            }
            
            // this will simply present an alert about the camera not being available on the simulator
            // good enough to verify it tried to launch
            it("present video") {
                let observation = Observation();
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.addVideoAttachment();
                
                tester().waitForAnimationsToFinish();
                
                expect(UIApplication.getTopViewController()?.isKind(of: NSClassFromString("UIAlertController")!)).toEventually(beTrue());
                
                tester().waitForView(withAccessibilityLabel: "No Camera");
            }
            
            it("present voice recorder") {
                let observation = Observation();
                let delegate = MockAttachmentCreationCoordinatorDelegate();
                
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: controller, observation: observation, delegate: delegate)
                
                attachmentCreationCoordinator.addVoiceAttachment();
                
                tester().waitForAnimationsToFinish();
                
                expect(UIApplication.getTopViewController()?.isKind(of: NSClassFromString("AudioRecorderViewController")!)).toEventually(beTrue());
            }
        }
    }
}
