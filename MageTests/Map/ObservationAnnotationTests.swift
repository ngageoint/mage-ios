//
//  ObservationAnnotationTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs
import MagicalRecord
import DateTools

@testable import MAGE

class ObservationAnnotationTests: KIFSpec {
    
    override func spec() {
        xdescribe("ObservationImage Tests") {
            
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            beforeEach {
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                Server.setCurrentEventId(1);
//                NSManagedObject.mr_setDefaultBatchSize(0);
            }
            
            afterEach {
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
//                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
            }
            
            func getDocumentsDirectory() -> String {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0]
                return documentsDirectory as String
            }
            
            func getFormsJsonWithExtraFields() -> [[AnyHashable: Any]] {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                var fields = (formsJson[0]["fields"] as! [[AnyHashable: Any]])
                
                fields.append([
                    "name": "testfield",
                    "type": "textfield",
                    "title": "Test Field",
                    "id": 100
                ])
                fields.append([
                    "name": "secondary",
                    "type": "textfield",
                    "title": "secondary Field",
                    "id": 101
                ])
                
                formsJson[0]["fields"] = fields;
                return formsJson
            }
            
            it("should get the annotation name with primary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()
                
                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["primaryFeedField"] = "testfield";
                
                MageCoreDataFixtures.addEventFromJson(context: context, remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createPointObservation(eventId:1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date())
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                let location = CLLocation(latitude: 40.0085, longitude: -105.2678)
                let annotation = ObservationAnnotation(observation: observation)
                expect(annotation.coordinate.latitude).to(beCloseTo(location.coordinate.latitude))
                expect(annotation.coordinate.longitude).to(beCloseTo(location.coordinate.longitude))
                expect(annotation.title).to(equal("Hi"))
                expect(annotation.subtitle).to(equal((observation.timestamp! as NSDate).timeAgoSinceNow()))
                expect(annotation.accessibilityLabel).to(equal("Observation Annotation"))
                expect(annotation.accessibilityValue).to(equal("Observation Annotation"))
                
                let mapView = MKMapView(forAutoLayout: ());
                let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
                
                let annotationView = annotation.viewForAnnotation(on: mapView, scheme: MAGEScheme.scheme());
                expect(annotationView).toNot(beNil());
                expect(annotationView.accessibilityLabel).to(equal("Observation"))
                expect(annotationView.accessibilityValue).to(equal("Observation"))
                expect(annotationView.displayPriority).to(equal(MKFeatureDisplayPriority.required))
                expect(annotationView.image).to(equal(imageRepository.image(observation: observation)))
                expect(annotationView.isEnabled).to(beTrue());
                expect(annotationView.centerOffset.x).to(equal(0))
                expect(annotationView.centerOffset.y).to(beCloseTo(-23.86363))
            }
            
            it("should get the annotation with no primary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                let formsJson = getFormsJsonWithExtraFields()
                
                MageCoreDataFixtures.addEventFromJson(context: context, remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createPointObservation(eventId:1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date())
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                let location = CLLocation(latitude: 40.0085, longitude: -105.2678)
                let annotation = ObservationAnnotation(observation: observation)
                expect(annotation.coordinate.latitude).to(beCloseTo(location.coordinate.latitude))
                expect(annotation.coordinate.longitude).to(beCloseTo(location.coordinate.longitude))
                expect(annotation.title).to(equal("Observation"))
                expect(annotation.subtitle).to(equal((observation.timestamp! as NSDate).timeAgoSinceNow()))
                expect(annotation.accessibilityLabel).to(equal("Observation Annotation"))
                expect(annotation.accessibilityValue).to(equal("Observation Annotation"))
                
                let mapView = MKMapView(forAutoLayout: ());
                let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()

                let annotationView = annotation.viewForAnnotation(on: mapView, scheme: MAGEScheme.scheme());
                expect(annotationView).toNot(beNil());
                expect(annotationView.accessibilityLabel).to(equal("Observation"))
                expect(annotationView.accessibilityValue).to(equal("Observation"))
                expect(annotationView.displayPriority).to(equal(MKFeatureDisplayPriority.required))
                expect(annotationView.image).to(equal(imageRepository.image(observation: observation)))
                expect(annotationView.isEnabled).to(beTrue());
                expect(annotationView.centerOffset.x).to(equal(0))
                expect(annotationView.centerOffset.y).to(beCloseTo(-23.86363))
            }
            
            it("should get the annotation with a line annotation") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                let formsJson = getFormsJsonWithExtraFields()
                
                MageCoreDataFixtures.addEventFromJson(context: context, remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createLineObservation()
                ObservationBuilder.setObservationDate(observation: observation, date: Date())
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                let annotation = ObservationAnnotation(observation: observation, location: observation.location!.coordinate)
                expect(annotation.coordinate.latitude).to(beCloseTo(40.0085))
                expect(annotation.coordinate.longitude).to(beCloseTo(-105.2666))
                expect(annotation.title).to(equal("Observation"))
                expect(annotation.subtitle).to(equal((observation.timestamp! as NSDate).timeAgoSinceNow()))
                expect(annotation.accessibilityLabel).to(equal("Observation Annotation"))
                expect(annotation.accessibilityValue).to(equal("Observation Annotation"))
                
                let mapView = MKMapView(forAutoLayout: ());
                
                let annotationView = annotation.viewForAnnotation(on: mapView, scheme: MAGEScheme.scheme());
                expect(annotationView).toNot(beNil());
                expect(annotationView.accessibilityLabel).to(equal("Observation"))
                expect(annotationView.accessibilityValue).to(equal("Observation"))
                expect(annotationView.displayPriority).to(equal(MKFeatureDisplayPriority.required))
                expect(annotationView.image).to(beNil())
                expect(annotationView.isEnabled).to(beTrue());
                expect(annotationView.centerOffset.x).to(equal(0))
                expect(annotationView.centerOffset.y).to(equal(0))
            }
          
           it("should init with the observation id and not an _observation reference if has a remote id and not dirty") {
              let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
              
              do {
                 try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                 let image: UIImage = UIImage(named: "marker")!
                 FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
              }
              
              var formsJson = getFormsJsonWithExtraFields()
              
              formsJson[0]["primaryField"] = "testfield";
              formsJson[0]["primaryFeedField"] = "testfield";
              
               MageCoreDataFixtures.addEventFromJson(context: context, remoteId: 1, name: "Event", formsJson: formsJson)
              
              let observation = ObservationBuilder.createPointObservation(eventId:1);
              observation.remoteId = "1"
              observation.dirty = false

              let annotation = ObservationAnnotation(observation: observation, location: observation.location!.coordinate)
              expect(annotation.observationId).to(be(observation.remoteId))
              
              print(annotation.observation)
              expect(annotation._observation).to(beNil())
           }
        
           
           it("should init with the observation reference and not an id if the observation is dirty") {
              let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
              
              do {
                 try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                 let image: UIImage = UIImage(named: "marker")!
                 FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
              }
              
              var formsJson = getFormsJsonWithExtraFields()
              formsJson[0]["primaryField"] = "testfield";
              formsJson[0]["primaryFeedField"] = "testfield";
              
               MageCoreDataFixtures.addEventFromJson(context: context, remoteId: 1, name: "Event", formsJson: formsJson)
              
              let observation = ObservationBuilder.createPointObservation(eventId:1);
              observation.remoteId = "1"
              observation.dirty = true
               
              let annotation = ObservationAnnotation(observation: observation, location: observation.location!.coordinate)
              expect(annotation.observationId).to(beNil())
              expect(annotation.observation).to(beIdenticalTo(observation))
           }
        }
    }
}
