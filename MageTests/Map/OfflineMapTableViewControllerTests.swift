//
//  OfflineMapTableViewControllerTests.swift
//  MAGETests
//
//

import Foundation
import UIKit
import XCTest

@testable import MAGE

final class OfflineMapTableViewControllerTests: MageCoreDataTestCase {
    
    private let eventId = NSNumber(value: 1)
    private var window: UIWindow?
    
    override func setUp() {
        super.setUp()
        Server.setCurrentEventId(eventId)
        UserDefaults.standard.selectedStaticLayers = nil
        MageCoreDataFixtures.addEvent(remoteId: eventId, name: "Test Event", formsJsonFile: "oneForm")
    }
    
    override func tearDown() {
        UserDefaults.standard.selectedStaticLayers = nil
        window?.isHidden = true
        window = nil
        super.tearDown()
    }
    
    private func addDownloadedStaticLayer(
        remoteId: NSNumber,
        includeRemoteId: Bool = true,
        data: [AnyHashable: Any]? = nil
    ) -> StaticLayer {
        return addStaticLayer(
            remoteId: remoteId,
            loaded: NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED),
            includeRemoteId: includeRemoteId,
            data: data
        )
    }

    private func addStaticLayer(
        remoteId: NSNumber,
        loaded: NSNumber,
        includeRemoteId: Bool = true,
        data: [AnyHashable: Any]? = nil,
        downloading: Bool = false,
        fileSize: String? = nil
    ) -> StaticLayer {
        var layer: StaticLayer!
        context.performAndWait {
            let staticLayer = StaticLayer(context: self.context)
            staticLayer.eventId = self.eventId
            staticLayer.type = LayerType.Feature.key
            staticLayer.name = "KML \(remoteId)"
            staticLayer.loaded = loaded
            staticLayer.downloading = downloading
            if includeRemoteId {
                staticLayer.remoteId = remoteId
            } else {
                staticLayer.remoteId = nil
            }

            let layerData = data ?? [
                "features": [
                    ["id": "f1", "geometry": ["type": "Point", "coordinates": [0, 0]],
                     "properties": ["name": "point-1"]]
                ]
            ]
            staticLayer.data = layerData
            if let fileSize {
                staticLayer.file = ["size": fileSize]
            }
            try? self.context.obtainPermanentIDs(for: [staticLayer])
            try? self.context.save()
            layer = staticLayer
        }
        return layer
    }
    
    private func makeController() -> OfflineMapTableViewController {
        let controller = OfflineMapTableViewController(scheme: MAGEScheme.scheme(), context: context)
        controller.loadViewIfNeeded()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        controller.reloadData()
        controller.tableView.reloadData()
        controller.tableView.layoutIfNeeded()
        return controller
    }

    private func indexPath(for targetLayer: Layer, on controller: OfflineMapTableViewController) -> IndexPath {
        for section in 0..<controller.numberOfSections(in: controller.tableView) {
            for row in 0..<controller.tableView(controller.tableView, numberOfRowsInSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                if let layerAtPath = controller.layer(indexPath: indexPath),
                   layerAtPath.objectID == targetLayer.objectID {
                    return indexPath
                }
            }
        }
        XCTFail("Could not find layer \(targetLayer.name ?? "") in table")
        return IndexPath(row: 0, section: 0)
    }

    private func cellForLayer(_ layer: Layer, on controller: OfflineMapTableViewController) -> UITableViewCell {
        let indexPath = indexPath(for: layer, on: controller)
        controller.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        controller.tableView.layoutIfNeeded()
        return try! XCTUnwrap(controller.tableView.cellForRow(at: indexPath))
    }

    private func switchForLayer(_ layer: Layer, on controller: OfflineMapTableViewController) -> UISwitch {
        let cell = cellForLayer(layer, on: controller)
        return try! XCTUnwrap(cell.accessoryView as? UISwitch)
    }
    
    private func switchAtFirstRow(on controller: OfflineMapTableViewController) -> UISwitch {
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = try! XCTUnwrap(controller.tableView(controller.tableView, cellForRowAt: indexPath))
        return try! XCTUnwrap(cell.accessoryView as? UISwitch)
    }
    
    func testStaticLayerSelectionPersistsWithOnOffToggle() {
        let layerId = NSNumber(value: 42)
        let layer = addDownloadedStaticLayer(remoteId: layerId)
        
        let controller = makeController()
        let layerSwitch = switchForLayer(layer, on: controller)
        XCTAssertFalse(layerSwitch.isOn)
        XCTAssertNil(UserDefaults.standard.selectedStaticLayers)
        
        layerSwitch.setOn(true, animated: false)
        layerSwitch.sendActions(for: .valueChanged)
        
        let selectedAfterOn = UserDefaults.standard.selectedStaticLayers?[eventId.stringValue] ?? []
        XCTAssertEqual(selectedAfterOn.count, 1)
        XCTAssertEqual(selectedAfterOn.first, layerId)
        
        let reopenedController = makeController()
        let reopenedSwitch = switchForLayer(layer, on: reopenedController)
        XCTAssertTrue(reopenedSwitch.isOn)
        
        reopenedSwitch.setOn(false, animated: false)
        reopenedSwitch.sendActions(for: .valueChanged)
        let selectedAfterOff = UserDefaults.standard.selectedStaticLayers?[eventId.stringValue] ?? []
        XCTAssertTrue(selectedAfterOff.isEmpty)
    }
    
    func testDownloadedStaticLayerRowSelectionDoesNotTriggerToggle() {
        let layerId = NSNumber(value: 43)
        let expected = [layerId]
        let layer = addDownloadedStaticLayer(remoteId: layerId)
        UserDefaults.standard.selectedStaticLayers = [eventId.stringValue: expected]
        
        let controller = makeController()
        let indexPath = indexPath(for: layer, on: controller)
        let layerSwitch = switchForLayer(layer, on: controller)
        XCTAssertTrue(layerSwitch.isOn)
        
        controller.tableView(controller.tableView, didSelectRowAt: indexPath)
        XCTAssertTrue(layerSwitch.isOn)
        
        let selected = UserDefaults.standard.selectedStaticLayers?[eventId.stringValue]
        XCTAssertEqual(selected, expected)
    }
    
    func testStaticLayerWithoutRemoteIdDoesNotShowSwitch() {
        let layer = addDownloadedStaticLayer(remoteId: NSNumber(value: 44), includeRemoteId: false)
        
        let controller = makeController()
        let cell = cellForLayer(layer, on: controller)
        XCTAssertNil(cell.accessoryView)
    }
    
    func testTogglePersistsForStaticLayerWithoutGeometryData() {
        let layerId = NSNumber(value: 45)
        let layer = addDownloadedStaticLayer(
            remoteId: layerId,
            data: ["features": []]
        )
        
        let controller = makeController()
        let layerSwitch = switchForLayer(layer, on: controller)
        XCTAssertFalse(layerSwitch.isOn)
        
        layerSwitch.setOn(true, animated: false)
        layerSwitch.sendActions(for: .valueChanged)

        let selected = UserDefaults.standard.selectedStaticLayers?[eventId.stringValue]
        XCTAssertEqual(selected, [layerId])
    }

    func testAvailableLayerAccessoryReflectsDownloadingState() {
        let layer = addStaticLayer(
            remoteId: NSNumber(value: 46),
            loaded: NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED),
            data: ["features": []],
            downloading: false, 
            fileSize: "2048"
        )
        let controller = makeController()
        let idleCell = cellForLayer(layer, on: controller)
        XCTAssertTrue(idleCell.accessoryView is UIImageView)

        context.performAndWait {
            layer.downloading = true
            layer.downloadedBytes = 123
            try? self.context.save()
        }
        controller.reloadData()
        controller.tableView.reloadData()

        let downloadingCell = cellForLayer(layer, on: controller)
        XCTAssertTrue(downloadingCell.accessoryView is UIActivityIndicatorView)
        XCTAssertNotNil(downloadingCell.detailTextLabel?.text)
        XCTAssertTrue(downloadingCell.detailTextLabel?.text?.contains("Downloading, Please wait") ?? false)
    }

    func testAvailableLayerWithoutFileSizeDownloadMessageDuringProgress() {
        let layer = addStaticLayer(
            remoteId: NSNumber(value: 47),
            loaded: NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED),
            data: ["features": []],
            downloading: true
        )

        let controller = makeController()
        let cell = cellForLayer(layer, on: controller)
        XCTAssertTrue(cell.accessoryView is UIActivityIndicatorView)
        XCTAssertEqual(cell.detailTextLabel?.text, "Loading static feature data, Please wait")
    }

    func testAvailableLayerCompletesDownloadAndBecomesDownloadedLayer() {
        let layer = addStaticLayer(
            remoteId: NSNumber(value: 48),
            loaded: NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED),
            data: ["features": []],
            downloading: true, 
            fileSize: "2048"
        )

        let controller = makeController()
        let downloadingCell = cellForLayer(layer, on: controller)
        XCTAssertTrue(downloadingCell.accessoryView is UIActivityIndicatorView)

        context.performAndWait {
            layer.downloading = false
            layer.loaded = NSNumber(value: Layer.OFFLINE_LAYER_LOADED)
            layer.downloadedBytes = 2048
            try? self.context.save()
        }
        controller.reloadData()
        controller.tableView.reloadData()

        let downloadedCell = cellForLayer(layer, on: controller)
        XCTAssertTrue(downloadedCell.accessoryView is UISwitch)
    }

    func testAvailableLayerProgressUpdateRetainsSpinnerAccessoryView() {
        let layer = addStaticLayer(
            remoteId: NSNumber(value: 49),
            loaded: NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED),
            data: ["features": []],
            downloading: true,
            fileSize: "4096"
        )

        let controller = makeController()
        let indexPath = indexPath(for: layer, on: controller)
        let initialCell = cellForLayer(layer, on: controller)
        let initialSpinner = try! XCTUnwrap(initialCell.accessoryView as? UIActivityIndicatorView)
        let initialText = initialCell.detailTextLabel?.text

        context.performAndWait {
            layer.downloadedBytes = 2048
        }

        guard let updatedLayer = controller.layer(indexPath: indexPath) else {
            XCTFail("Updated layer was not found")
            return
        }

        if let fetchedResultsController = controller.mapsFetchedResultsController {
            controller.controller(
                fetchedResultsController,
                didChange: updatedLayer,
                at: indexPath,
                for: .update,
                newIndexPath: nil
            )
        } else {
            XCTFail("Fetched results controller was not loaded")
            return
        }

        let updatedCell = try! XCTUnwrap(controller.tableView.cellForRow(at: indexPath))
        let updatedSpinner = try! XCTUnwrap(updatedCell.accessoryView as? UIActivityIndicatorView)
        XCTAssertTrue(updatedSpinner === initialSpinner)

        let updatedText = updatedCell.detailTextLabel?.text
        XCTAssertNotEqual(initialText, updatedText)
        XCTAssertTrue(updatedText?.contains("Downloading, Please wait") ?? false)
    }
}
