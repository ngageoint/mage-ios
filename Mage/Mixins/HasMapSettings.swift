//
//  HasMapSettings.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol HasMapSettings {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var navigationController: UINavigationController? { get set }
    var hasMapSettingsMixin: HasMapSettingsMixin? { get set }
}

class HasMapSettingsMixin: NSObject, MapMixin {
    var geoPackageImportedObserver: Any?
    var hasMapSettings: HasMapSettings
    var settingsCoordinator: MapSettingsCoordinator?
    weak var rootView: UIView?
    
    private lazy var mapSettingsButton: MDCFloatingButton = {
        let mapSettingsButton = MDCFloatingButton(shape: .mini)
        mapSettingsButton.setImage(UIImage(systemName:"square.stack.3d.up"), for: .normal)
        mapSettingsButton.addTarget(self, action: #selector(mapSettingsButtonTapped(_:)), for: .touchUpInside)
        mapSettingsButton.accessibilityLabel = "map_settings"
        return mapSettingsButton
    }()
    
    init(hasMapSettings: HasMapSettings, rootView: UIView?) {
        self.hasMapSettings = hasMapSettings
        self.rootView = rootView
    }
    
    deinit {
        if let geoPackageImportedObserver = geoPackageImportedObserver {
            NotificationCenter.default.removeObserver(geoPackageImportedObserver, name: .GeoPackageImported, object: nil)
        }
        geoPackageImportedObserver = nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        hasMapSettings.scheme = scheme
        mapSettingsButton.backgroundColor = scheme?.colorScheme.surfaceColor;
        mapSettingsButton.tintColor = scheme?.colorScheme.primaryColorVariant;
    }
    
    func setupMixin() {
        guard let mapView = self.hasMapSettings.mapView else {
            return
        }
        rootView?.insertSubview(mapSettingsButton, aboveSubview: mapView)
        mapSettingsButton.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
        mapSettingsButton.autoPinEdge(toSuperviewMargin: .right)
        
        setupMapSettingsButton()

        applyTheme(scheme: hasMapSettings.scheme)
        
        geoPackageImportedObserver = NotificationCenter.default.addObserver(forName: .GeoPackageImported, object: nil, queue: .main) { [weak self] notification in
            self?.setupMapSettingsButton()
        }
    }
    
    @objc func mapSettingsButtonTapped(_ sender: UIButton) {
        settingsCoordinator = MapSettingsCoordinator(rootViewController: hasMapSettings.navigationController, scheme: hasMapSettings.scheme)
        settingsCoordinator?.delegate = self
        settingsCoordinator?.start()
    }
    
    func setupMapSettingsButton() {
        let count = Layer.mr_countOfEntities(with: NSPredicate(format: "eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", Server.currentEventId() ?? -1, "GeoPackage"), in: NSManagedObjectContext.mr_default())
        for subview in mapSettingsButton.subviews {
            if subview.tag == 998 {
                subview.removeFromSuperview()
            }
        }
        if count > 0 {
            let circle = UIView(frame: CGRect(x: 25, y: -10, width: 20, height: 20))
            circle.tag = 998
            circle.layer.cornerRadius = 10
            circle.layer.borderWidth = 0.5
            circle.layer.borderColor = hasMapSettings.scheme?.colorScheme.onPrimaryColor.withAlphaComponent(0.87).cgColor
            circle.backgroundColor = hasMapSettings.scheme?.colorScheme.primaryColor
            circle.accessibilityLabel = "layer_download_circle"
            let imageView = UIImageView(image: UIImage(named: "download"))
            imageView.frame = CGRect(x: 3, y: 2, width: 14, height: 15)
            imageView.tintColor = hasMapSettings.scheme?.colorScheme.onPrimaryColor
            circle.addSubview(imageView)
            mapSettingsButton.addSubview(circle)
        }
    }
}

extension HasMapSettingsMixin : MapSettingsCoordinatorDelegate {
    func mapSettingsComplete(_ coordinator: NSObject!) {
        settingsCoordinator = nil
    }
}
