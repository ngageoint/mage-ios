//
//  AttachmentFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class MockAttachmentSelectionDelegate: AttachmentSelectionDelegate {
    func selectedNotCachedAttachment(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        
    }
    
    func selectedAttachment(_ attachmentUri: URL!) {
        attachmentSelectedUri = attachmentUri
        attachmentSelectedUriCalled = true
    }
    
    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        
    }
    
    var selectedAttachmentCalled = false;
    var attachmentSelected: Attachment?;
    var attachmentSelectedUri: URL?
    var attachmentSelectedUriCalled = false
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        
    }
    
    func selectedAttachment(_ attachment: Attachment!) {
        selectedAttachmentCalled = true;
        attachmentSelected = attachment;
    }
}

class AttachmentFieldViewTests: AsyncMageCoreDataTestCase {

    var field: [String: Any]!
    
    var attachmentFieldView: AttachmentFieldView!
    var view: UIView!
    var controller: UIViewController!
    var window: UIWindow!;
    var stackSetup = false;
    
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
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        TestHelpers.clearImageCache();
        window = TestHelpers.getKeyWindowVisible();
        
        controller = UIViewController(nibName: nil, bundle: nil);
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 300);
        view.backgroundColor = .systemBackground;
        
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
                        
        field = [
            "title": "Field Title",
            "type": "attachment",
            "name": "field0"
        ];
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        controller.dismiss(animated: false, completion: nil);
        attachmentFieldView.removeFromSuperview();
        attachmentFieldView = nil;
        controller = nil;
        window.rootViewController = nil;
    }
    
    @MainActor
    func testNonEditModeWithNoFieldTitle() {
        field["title"] = nil;
        var attachmentLoaded = false;
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, editMode: false, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);
//                tester().waitForAnimationsToFinish();
        
        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testNonEditModeWithFieldTitle() {
        var attachmentLoaded = false;

        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        attachmentFieldView = AttachmentFieldView(field: field, editMode: false, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForAnimationsToFinish(withTimeout: 0.01);
        
        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testNoInitialValue() {
        attachmentFieldView = AttachmentFieldView(field: field, value: nil);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testOneAttachmentSetFromObservation() {
        var attachmentLoaded = false;

        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func test3AttachmentsSetFromObservation() {
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        
        var attachmentLoaded = false;
        var attachmentLoaded2 = false;
        var attachmentLoaded3 = false;

        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL2: URL = URL(string: attachment2.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
            attachmentLoaded2 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL3: URL = URL(string: attachment3.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
            attachmentLoaded3 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        window.rootViewController = controller;
        controller.view.addSubview(view);
        
        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
//                tester().waitForAnimationsToFinish()
        tester().waitForAnimationsToFinish(withTimeout: 0.01);
        
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment2.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment3.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    func test4AttachmentsSetFromObservation() {
        var attachmentLoaded = false;
        var attachmentLoaded2 = false;
        var attachmentLoaded3 = false;
        var attachmentLoaded4 = false;
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL2: URL = URL(string: attachment2.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
            attachmentLoaded2 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL3: URL = URL(string: attachment3.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
            attachmentLoaded3 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment4 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL4: URL = URL(string: attachment4.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL4.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .black, endColor: .white, size: CGSize(width: 50, height: 50))
            attachmentLoaded4 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded4).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment2.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment3.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment4.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func test5AttachmentsSetFromObservation() {
        var attachmentLoaded = false;
        var attachmentLoaded2 = false;
        var attachmentLoaded3 = false;
        var attachmentLoaded4 = false;
        var attachmentLoaded5 = false;
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL2: URL = URL(string: attachment2.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
            attachmentLoaded2 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL3: URL = URL(string: attachment3.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
            attachmentLoaded3 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment4 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL4: URL = URL(string: attachment4.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL4.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .black, endColor: .white, size: CGSize(width: 50, height: 50))
            attachmentLoaded4 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment5 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL5: URL = URL(string: attachment5.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL5.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .magenta, size: CGSize(width: 50, height: 50))
            attachmentLoaded5 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded4).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded5).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment2.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment3.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment4.name ?? "") loaded")
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment5.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testOneAttachmentSetLater() {
        var attachmentLoaded = false;
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        attachmentFieldView.setValue(observation.orderedAttachments as Any?);
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
//            it("two attachments set together later") {
//                var attachmentLoaded = false;
//                var attachmentLoaded2 = false;
//
//                let observation = ObservationBuilder.createBlankObservation();
//                observation.remoteId = "remoteobservationid";
//                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
//                let attachmentURL: URL = URL(string: attachment.url!)!;
//                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
//                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
//                    attachmentLoaded = true;
//                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                }
//                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
//                let attachmentURL2: URL = URL(string: attachment2.url!)!;
//                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
//                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
//                    attachmentLoaded2 = true;
//                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                }
//
//                controller.viewDidLoadClosure = {
//                    attachmentFieldView = AttachmentFieldView(field: field);
//                    attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//
//                    view.addSubview(attachmentFieldView)
//                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
//
//                    attachmentFieldView.setValue(observation.orderedAttachments);
//                }
//
//                window.rootViewController = controller;
//                controller.view.addSubview(view);
//                tester().waitForAnimationsToFinish(withTimeout: 0.01);
//
//                expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//                expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//                tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
//                tester().waitForView(withAccessibilityLabel: "attachment \(attachment2.name ?? "") loaded")
//
////                expect(view).to(haveValidSnapshot(usesDrawRect: true))
//            }
    
    @MainActor
    func testSetOneAttachmentLater() {
        var attachmentLoaded = false;
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment));
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testSetOneAttachmentWithObservationAndOneLater() async {
        var attachmentLoaded = XCTestExpectation(description: "Attachment Loaded")
        var attachmentLoaded2 = XCTestExpectation(description: "Attachment2 Loaded")
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded.fulfill()
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
                   
//                controller.viewDidLoadClosure = {
                    attachmentFieldView = AttachmentFieldView(field: field);
                    attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
        let models = observation.attachments?.map({ attachment in
            AttachmentModel(attachment: attachment)
        }) ?? []
        attachmentFieldView.setValue(set: Set(models));
//
        await awaitDidSave {
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!;
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
                        attachmentLoaded2.fulfill()
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment2));
        }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);
        
        await fulfillment(of: [attachmentLoaded, attachmentLoaded2], timeout: 2)
//
//        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
//        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
//        tester().waitForCell(at: IndexPath(row: 1, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
//        tester().waitForView(withAccessibilityLabel: "attachment name1 loaded")
    }
    
    @MainActor
    func testSetOneAttachmentWithObservationAndTwoLater() async {
        var attachmentLoaded = XCTestExpectation(description: "Attachment Loaded")
        var attachmentLoaded2 = XCTestExpectation(description: "Attachment2 Loaded")
        var attachmentLoaded3 = XCTestExpectation(description: "Attachment3 Loaded")
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded.fulfill()
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
//                controller.viewDidLoadClosure = {
                    attachmentFieldView = AttachmentFieldView(field: field);
                    attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();

        let models = observation.attachments?.map({ attachment in
            AttachmentModel(attachment: attachment)
        }) ?? []
        attachmentFieldView.setValue(set: Set(models));
        
        await awaitDidSave {
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!;
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
                        attachmentLoaded2.fulfill()
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment2));
            
            let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
            let attachmentURL3: URL = URL(string: attachment3.url!)!;
            stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                attachmentLoaded3.fulfill()
                return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
            }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment3));
        }
//
//                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
//                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
//                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
//                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
//                        attachmentLoaded2 = true;
//                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                    }
//                    attachmentFieldView.addAttachment(attachment2);
//
//                    let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
//                    let attachmentURL3: URL = URL(string: attachment3.url!)!;
//                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
//                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
//                        attachmentLoaded3 = true;
//                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                    }
//                    attachmentFieldView.addAttachment(attachment3);
//                }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        await fulfillment(of: [attachmentLoaded, attachmentLoaded2, attachmentLoaded3], timeout: 2)
//        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
//        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        tester().waitForCell(at: IndexPath(row: 1, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
        tester().waitForCell(at: IndexPath(row: 2, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
//        tester().waitForView(withAccessibilityLabel: "attachment name1 loaded")
//        tester().waitForView(withAccessibilityLabel: "attachment name2 loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testSetOneAttachmentWithObservationAndTwoLaterThenRemoveFirst() async {
        var attachmentLoaded2 = XCTestExpectation(description: "Attachment2 Loaded")
        var attachmentLoaded3 = XCTestExpectation(description: "Attachment3 Loaded")
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
//                controller.viewDidLoadClosure = {
                    attachmentFieldView = AttachmentFieldView(field: field);
                    attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
        let models = observation.attachments?.map({ attachment in
            AttachmentModel(attachment: attachment)
        }) ?? []
        attachmentFieldView.setValue(set: Set(models));
//                    attachmentFieldView.setValue(set: observation.attachments);
        await awaitDidSave {
            let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
            let attachmentURL2: URL = URL(string: attachment2.url!)!;
            stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
                attachmentLoaded2.fulfill()
                return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
            }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment2));
        }
        await awaitDidSave {
                    let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
                    let attachmentURL3: URL = URL(string: attachment3.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
                        attachmentLoaded3.fulfill()
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment3));

            self.attachmentFieldView.removeAttachment(AttachmentModel(attachment: attachment));
                }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        await fulfillment(of: [attachmentLoaded2, attachmentLoaded3], timeout: 2)
//        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
//        tester().waitForAbsenceOfView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        tester().waitForCell(at: IndexPath(row: 0, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
        tester().waitForCell(at: IndexPath(row: 1, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
//        tester().waitForView(withAccessibilityLabel: "attachment name1 loaded")
//        tester().waitForView(withAccessibilityLabel: "attachment name2 loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testSetOneAttachmentWithObservationAndTwoLaterThenRemoveSecond() async {
        TestHelpers.printAllAccessibilityLabelsInWindows()
        
        var attachmentLoaded = XCTestExpectation(description: "Attachment Loaded")
        var attachmentLoaded3 = XCTestExpectation(description: "Attachment3 Loaded")
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded.fulfill()
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        self.attachmentFieldView = AttachmentFieldView(field: field);
        self.attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        var attachment2: Attachment!
        await awaitDidSave {
            let models = observation.attachments?.map({ attachment in
                AttachmentModel(attachment: attachment)
            }) ?? []
            self.attachmentFieldView.setValue(set: Set(models));
            attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
            let attachmentURL2: URL = URL(string: attachment2.url!)!;
            stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
                return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
            }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment2))
        }
        
        await awaitDidSave {
            let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
            let attachmentURL3: URL = URL(string: attachment3.url!)!;
            stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
                attachmentLoaded3.fulfill()
                return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
            }
            self.attachmentFieldView.addAttachment(AttachmentModel(attachment: attachment3))

            self.attachmentFieldView.removeAttachment(AttachmentModel(attachment: attachment2))
        }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);
        
        await fulfillment(of: [attachmentLoaded, attachmentLoaded3], timeout: 2)

//        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
        tester().waitForCell(at: IndexPath(row: 0, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
        tester().waitForCell(at: IndexPath(row: 1, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection")
        TestHelpers.printAllAccessibilityLabelsInWindows()
//                there is a leftover window which is causing this to not work
//        tester().waitForAbsenceOfView(withAccessibilityLabel: "attachment name1 loaded")
//        tester().waitForView(withAccessibilityLabel: "attachment name2 loaded")
//        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
        
//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testRequiredFieldIsInvalidIfEmpty() {
        field[FieldKey.required.key] = true;
        
        attachmentFieldView = AttachmentFieldView(field: field);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.attachmentFieldView.isEmpty()).to(beTrue());
        expect(self.attachmentFieldView.isValid(enforceRequired: true)).to(beFalse());
        attachmentFieldView.setValid(attachmentFieldView.isValid());
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testShouldRequiredFieldIsValidIfAttachmentExists() {
        field[FieldKey.required.key] = true;
        var attachmentLoaded = false;
                        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.attachmentFieldView.isEmpty()).to(beFalse());
        expect(self.attachmentFieldView.isValid(enforceRequired: true)).to(beTrue());
        attachmentFieldView.setValid(attachmentFieldView.isValid());
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
//                expect(view).to(haveValidSnapshot(usesDrawRect: true));
        tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
    }
    
    @MainActor
    func testShouldCallTheAttachmentSelectionDelegateOnTap() {
        var attachmentLoaded = false;
        var attachmentLoaded2 = false;
        var attachmentLoaded3 = false;
        
        let observation = ObservationBuilder.createBlankObservation();
        observation.remoteId = "remoteobservationid";
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL2: URL = URL(string: attachment2.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 50, height: 50))
            attachmentLoaded2 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL3: URL = URL(string: attachment3.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 50, height: 50))
            attachmentLoaded3 = true;
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        attachmentFieldView = AttachmentFieldView(field: field, value: observation.orderedAttachments, attachmentSelectionDelegate: attachmentSelectionDelegate);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded2).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        expect(attachmentLoaded3).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");
        
        tester().waitForView(withAccessibilityLabel: "Attachment Collection");
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(observation.orderedAttachments?[0].attachmentUri));
    }
    
    @MainActor
    func testShouldTapCameraButtonToAddAttachment() {
        window.rootViewController = controller;
        controller.view.addSubview(view);
        let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
        attachmentFieldView = AttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Camera");
        tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Camera");
        expect(coordinator.addCameraAttachmentCalled).to(beTrue());
    }
    
    @MainActor
    func testShouldTapVideoButtonToAddAttachment() {
        window.rootViewController = controller;
        controller.view.addSubview(view);
        let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
        attachmentFieldView = AttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Video");
        tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Video");
        expect(coordinator.addVideoAttachmentCalled).to(beTrue());
    }
    
    @MainActor
    func testShouldTapAudioButtonToAddAttachment() {
        window.rootViewController = controller;
        controller.view.addSubview(view);
        let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
        attachmentFieldView = AttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Audio");
        tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Audio");
        expect(coordinator.addVoiceAttachmentCalled).to(beTrue());
    }
    
    @MainActor
    func testShouldTapGalleryButtonToAddAttachment() {
        window.rootViewController = controller;
        controller.view.addSubview(view);
        let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
        attachmentFieldView = AttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
        tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
        expect(coordinator.addGalleryAttachmentCalled).to(beTrue());
    }
    
    @MainActor
    func testShouldAddAnAttachmentViaTheDelegate() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!;
        let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
        let fileToWriteTo = attachmentsDirectory.appendingPathComponent("MAGE_20201101_120000.jpeg");
        
        if FileManager.default.fileExists(atPath: fileToWriteTo.path) {
            do {
                try FileManager.default.removeItem(at: fileToWriteTo);
            } catch {
                print("Error \(error)")
            }
        }
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
        let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
        attachmentFieldView = AttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
        tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
        expect(coordinator.addGalleryAttachmentCalled).to(beTrue());
        
        let newImage = createGradientImage(startColor: .purple, endColor: .blue, size: CGSize(width: 200, height: 200));
        do {
            try FileManager.default.createDirectory(at: fileToWriteTo.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil);
        } catch {
            print("Error creating directory \(error)")
        }
        do {
            try newImage.jpegData(compressionQuality: 1.0)?.write(to: fileToWriteTo);
        } catch {
            print("Error making jpeg \(error)")
        }
        let attachmentJson: [String: Any] = [
            "contentType": "image/jpeg",
            "localPath": fileToWriteTo.path,
            "name": "MAGE_20201101_120000.jpeg",
            "dirty": 1
        ]
                        
        let attachment = Attachment.attachment(json: attachmentJson, context: NSManagedObjectContext.mr_default())!;
        coordinator.delegate?.attachmentCreated(attachment: AttachmentModel(attachment: attachment))
        tester().waitForAnimationsToFinish(withTimeout: 0.01);

//                expect(view).to(haveValidSnapshot(usesDrawRect: true))
    }
    
    @MainActor
    func testSetOneAttachmentThatIsSyncedAndOneThatIsNot() async {
        var attachmentLoaded = XCTestExpectation(description: "Attachment Loaded");
        
        let observation = context.performAndWait {
            let observation = ObservationBuilder.createBlankObservation();
            observation.remoteId = "remoteobservationid";
            return observation
        }
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
            
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded.fulfill();
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        var attachment2: Attachment!
        await awaitDidSave {
            attachment2 = ObservationBuilder.createAttachment(eventId: observation.eventId!, name: "notsynced", observationRemoteId: observation.remoteId)!
            await self.awaitDidSave {
                attachment2.localPath = NSTemporaryDirectory() + "testimage.png"
                try? self.context.save()
            }
            let image: UIImage = self.createGradientImage(startColor: .magenta, endColor: .gray, size: CGSize(width: 50, height: 50));
            FileManager.default.createFile(atPath: attachment2.localPath!, contents: image.pngData()!, attributes: nil);
            
        }
        let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();

        attachmentFieldView = AttachmentFieldView(field: field, attachmentSelectionDelegate: attachmentSelectionDelegate);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        window.rootViewController = controller;
        controller.view.addSubview(view);
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        // not synced attachments should be ordered last so row 0 should be attachment and row 1 should be attachment 2
        attachmentFieldView.setValue([AttachmentModel(attachment: attachment2), AttachmentModel(attachment: attachment)]);
        tester().waitForView(withAccessibilityLabel: "Attachment Collection");
        
        await fulfillment(of: [attachmentLoaded], timeout: 2)
        
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment2.objectID.uriRepresentation()));
        
        attachmentSelectionDelegate.attachmentSelectedUriCalled = false;
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment.objectID.uriRepresentation()));
        
        attachmentSelectionDelegate.attachmentSelectedUriCalled = false;
        // reset the attachments in a different order
        attachmentFieldView.setValue([AttachmentModel(attachment: attachment), AttachmentModel(attachment: attachment2)]);
        tester().waitForView(withAccessibilityLabel: "Attachment Collection");
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment.objectID.uriRepresentation()));
        
        attachmentSelectionDelegate.attachmentSelectedUriCalled = false;
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment2.objectID.uriRepresentation()));
    }
    
    @MainActor
    func testSetOneAttachmentThatIsSyncedAndOneThatIsNotDifferentOrder() async {
        var attachmentLoaded = XCTestExpectation(description: "Attachment Loaded");
        let observation = context.performAndWait {
            let observation = ObservationBuilder.createBlankObservation();
            observation.remoteId = "remoteobservationid";
            return observation
        }
        let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation)!
        let attachmentURL: URL = URL(string: attachment.url!)!;
        stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
            let image: UIImage = self.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 50, height: 50))
            attachmentLoaded.fulfill();
            return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        var attachment2: Attachment!
        await awaitDidSave {
            attachment2 = ObservationBuilder.createAttachment(eventId: observation.eventId!, name: "notsynced", observationRemoteId: observation.remoteId)!
            await self.awaitDidSave {
                attachment2.localPath = NSTemporaryDirectory() + "testimage.png"
                try? self.context.save()
            }
            let image: UIImage = self.createGradientImage(startColor: .magenta, endColor: .gray, size: CGSize(width: 50, height: 50));
            FileManager.default.createFile(atPath: attachment2.localPath!, contents: image.pngData()!, attributes: nil);
            
        }
        let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();
        
        attachmentFieldView = AttachmentFieldView(field: field, attachmentSelectionDelegate: attachmentSelectionDelegate);
        attachmentFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        window.rootViewController = controller;
        controller.view.addSubview(view);
        view.addSubview(attachmentFieldView)
        attachmentFieldView.autoPinEdgesToSuperviewEdges();
        
        // not synced attachments should be ordered last so row 0 should be attachment and row 1 should be attachment 2
        attachmentFieldView.setValue([AttachmentModel(attachment: attachment), AttachmentModel(attachment: attachment2)]);
        tester().waitForView(withAccessibilityLabel: "Attachment Collection");
        await fulfillment(of: [attachmentLoaded], timeout: 2)
//        expect(attachmentLoaded).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Loading Attachment");

        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment.objectID.uriRepresentation()));
        
        attachmentSelectionDelegate.attachmentSelectedUriCalled = false;
        viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
        
        expect(attachmentSelectionDelegate.attachmentSelectedUriCalled).to(beTrue());
        expect(attachmentSelectionDelegate.attachmentSelectedUri).to(equal(attachment2.objectID.uriRepresentation()));
        
//        tester().waitForView(withAccessibilityLabel: "attachment name0 loaded")
    }
}
