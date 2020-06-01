//
//  CommonFieldsViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 6/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

//class MockMapViewDelegate: NSObject, MKMapViewDelegate {
//    var mapDidStartLoadingMapClosure: ((MKMapView) -> Void)?
//    var mapDidFinishLoadingClosure: ((MKMapView) -> Void)?
//    var mapDidFinishRenderingClosure: ((MKMapView, Bool) -> Void)?
//    var mapDidAddOverlayViewsClosure: ((MKMapView) -> Void)?
//
//    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
//        mapDidStartLoadingMapClosure?(mapView);
//    }
//    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//        //loading done
//        mapDidFinishLoadingClosure?(mapView)
//    }
//
//    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
//        // rendering done
//        mapDidFinishRenderingClosure?(mapView, fullyRendered);
//    }
//
//    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
//        // added overlay views
//        mapDidAddOverlayViewsClosure?(mapView);
//    }
//}
//
//class ContainingUIViewController: UIViewController {
//    var viewDidLoadClosure: (() -> Void)?
//
//    override func viewWillAppear(_ animated: Bool) {
//        viewDidLoadClosure?();
//    }
//}

class CommonFieldsViewTests: QuickSpec {
    
    override func spec() {
        
        describe("CommonFieldsView") {
            var field: [String: Any]!
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var geometryFieldView: EditGeometryView!
            var view: UIView!
            var controller: ContainingUIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
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
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = ContainingUIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                
                field = ["title": "Field Title"];
                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            it("no initial value") {
                var completeTest = false;
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                controller.viewDidLoadClosure = {
                    geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    
                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
        }
    }
}
