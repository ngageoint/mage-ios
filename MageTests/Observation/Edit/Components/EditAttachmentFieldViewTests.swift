//
//  EditAttachmentFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class MockAttachmentSelectionDelegate: AttachmentSelectionDelegate {
    var selectedAttachmentCalled = false;
    var attachmentSelected: Attachment?;
    
    func selectedAttachment(_ attachment: Attachment!) {
        selectedAttachmentCalled = true;
        attachmentSelected = attachment;
    }
}

class EditAttachmentFieldViewTests: KIFSpec {
    
    override func spec() {
        
        describe("EditAttachmentFieldViewTests") {
            var field: [String: Any]!
            let recordSnapshots = false;
            
            var attachmentFieldView: EditAttachmentFieldView!
            var view: UIView!
            var controller: ContainingUIViewController!
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
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 0.5);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = ContainingUIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .systemBackground;
                window.makeKeyAndVisible();
                
                field = [
                    "title": "Field Title",
                    "type": "attachment",
                    "name": "field0"
                ];
                
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                HTTPStubs.removeAllStubs();
            }
            
            it("non edit mode with no field title") {
                field["title"] = nil;
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, editMode: false, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("non edit mode with field title") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, editMode: false, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("no initial value") {
                var completeTest = false;

                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: nil);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one attachment set from observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("3 attachments set from observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL2: URL = URL(string: attachment2.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL3: URL = URL(string: attachment3.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("4 attachments set from observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL2: URL = URL(string: attachment2.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL3: URL = URL(string: attachment3.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment4 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL4: URL = URL(string: attachment4.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL4.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .black, endColor: .white, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("5 attachments set from observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL2: URL = URL(string: attachment2.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL3: URL = URL(string: attachment3.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment4 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL4: URL = URL(string: attachment4.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL4.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .black, endColor: .white, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment5 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL5: URL = URL(string: attachment5.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL5.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .magenta, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one attachment set later") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("two attachments set together later") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL2: URL = URL(string: attachment2.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment later") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.addAttachment(attachment);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment with observation and one later") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                           
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                    
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment2);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment with observation and two later") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                    
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment2);
                    
                    let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL3: URL = URL(string: attachment3.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment3);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment with observation and two later then remove first") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                    
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment2);
                    
                    let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL3: URL = URL(string: attachment3.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment3);
                    
                    attachmentFieldView.removeAttachment(attachment);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment with observation and two later then remove second") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    attachmentFieldView.setValue(observation.attachments);
                    
                    let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL2: URL = URL(string: attachment2.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment2);
                    
                    let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                    let attachmentURL3: URL = URL(string: attachment3.url!)!;
                    stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                        let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                        return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    }
                    attachmentFieldView.addAttachment(attachment3);
                    
                    attachmentFieldView.removeAttachment(attachment2);
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field is invalid if empty") {
                var completeTest = false;
                
                field[FieldKey.required.key] = true;
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    expect(attachmentFieldView.isEmpty()).to(beTrue());
                    expect(attachmentFieldView.isValid(enforceRequired: true)).to(beFalse());
                    attachmentFieldView.setValid(attachmentFieldView.isValid());
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field is valid if attachment exists") {
                field[FieldKey.required.key] = true;
                
                var completeTest = false;
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller.viewDidLoadClosure = {
                    attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments);
                    
                    view.addSubview(attachmentFieldView)
                    attachmentFieldView.autoPinEdgesToSuperviewEdges();
                    
                    expect(attachmentFieldView.isEmpty()).to(beFalse());
                    expect(attachmentFieldView.isValid(enforceRequired: true)).to(beTrue());
                    attachmentFieldView.setValid(attachmentFieldView.isValid());
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("should call the attachment selection delegate on tap") {
                
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment2 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL2: URL = URL(string: attachment2.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL2.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .green, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                let attachment3 = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL3: URL = URL(string: attachment3.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL3.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .orange, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                attachmentFieldView = EditAttachmentFieldView(field: field, value: observation.attachments, attachmentSelectionDelegate: attachmentSelectionDelegate);
                
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: "Attachment Collection");
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment));
            }
            
            it("should tap camera button to add attachment") {
                window.rootViewController = controller;
                controller.view.addSubview(view);
                let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
                
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Camera");
                tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Camera");
                expect(coordinator.addCameraAttachmentCalled).to(beTrue());
            }
            
            it("should tap video button to add attachment") {
                window.rootViewController = controller;
                controller.view.addSubview(view);
                let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
                
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Video");
                tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Video");
                expect(coordinator.addVideoAttachmentCalled).to(beTrue());
            }
            
            it("should tap gallery button to add attachment") {
                window.rootViewController = controller;
                controller.view.addSubview(view);
                let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
                
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
                tester().tapView(withAccessibilityLabel: (field[FieldKey.name.key] as? String ?? "") + " Gallery");
                expect(coordinator.addGalleryAttachmentCalled).to(beTrue());
            }
            
            it("should add an attachment via the delegate") {
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
                
                var completeTest = false;

                window.rootViewController = controller;
                controller.view.addSubview(view);
                let coordinator = MockAttachmentCreationCoordinator(rootViewController: controller, observation: Observation())
                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentCreationCoordinator: coordinator);
                
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
                                
                let attachment = Attachment(forJson: attachmentJson, in: NSManagedObjectContext.mr_default());
                coordinator.delegate?.attachmentCreated(attachment: attachment);
                
                tester().waitForAnimationsToFinish();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set one attachment that is synced and one that is not") {
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let attachment2 = ObservationBuilder.createAttachment(eventId: observation.eventId!, name: "notsynced", observationRemoteId: observation.remoteId);
                attachment2.localPath = NSTemporaryDirectory() + "testimage.png"
                let image: UIImage = createGradientImage(startColor: .magenta, endColor: .gray, size: CGSize(width: 500, height: 500));
                FileManager.default.createFile(atPath: attachment2.localPath!, contents: image.pngData()!, attributes: nil);
                let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();

                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentSelectionDelegate: attachmentSelectionDelegate);
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                
                // not synced attachments should be ordered last so row 0 should be attachment and row 1 should be attachment 2
                attachmentFieldView.setValue(Set(arrayLiteral: attachment2, attachment));
                tester().waitForView(withAccessibilityLabel: "Attachment Collection");
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment));
                
                attachmentSelectionDelegate.selectedAttachmentCalled = false;
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment2));
                
                attachmentSelectionDelegate.selectedAttachmentCalled = false;
                // reset the attachments in a different order
                attachmentFieldView.setValue(Set(arrayLiteral: attachment, attachment2));
                tester().waitForView(withAccessibilityLabel: "Attachment Collection");
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment));
                
                attachmentSelectionDelegate.selectedAttachmentCalled = false;
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment2));
            }
            
            it("set one attachment that is synced and one that is not different order") {
                let observation = ObservationBuilder.createBlankObservation();
                observation.remoteId = "remoteobservationid";
                let attachment = ObservationBuilder.addAttachmentToObservation(observation: observation);
                let attachmentURL: URL = URL(string: attachment.url!)!;
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath(attachmentURL.path)) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let attachment2 = ObservationBuilder.createAttachment(eventId: observation.eventId!, name: "notsynced", observationRemoteId: observation.remoteId);
                attachment2.localPath = NSTemporaryDirectory() + "testimage.png"
                let image: UIImage = createGradientImage(startColor: .magenta, endColor: .gray, size: CGSize(width: 500, height: 500));
                FileManager.default.createFile(atPath: attachment2.localPath!, contents: image.pngData()!, attributes: nil);
                let attachmentSelectionDelegate = MockAttachmentSelectionDelegate();
                
                attachmentFieldView = EditAttachmentFieldView(field: field, attachmentSelectionDelegate: attachmentSelectionDelegate);
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(attachmentFieldView)
                attachmentFieldView.autoPinEdgesToSuperviewEdges();
                
                // not synced attachments should be ordered last so row 0 should be attachment and row 1 should be attachment 2
                attachmentFieldView.setValue(Set(arrayLiteral: attachment, attachment2));
                tester().waitForView(withAccessibilityLabel: "Attachment Collection");
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 0, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment));
                
                attachmentSelectionDelegate.selectedAttachmentCalled = false;
                viewTester().usingLabel("Attachment Collection").tapCollectionViewItem(at: IndexPath(row: 1, section: 0));
                
                expect(attachmentSelectionDelegate.selectedAttachmentCalled).to(beTrue());
                expect(attachmentSelectionDelegate.attachmentSelected).to(equal(attachment2));
            }
        }
    }
}
