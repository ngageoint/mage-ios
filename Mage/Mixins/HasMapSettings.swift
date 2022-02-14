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
    var hasMapSettingsMixin: HasMapSettingsMixin? { get set }
}

class HasMapSettingsMixin: NSObject, MapMixin {
    var geoPackageImportedObserver: Any?
    weak var mapView: MKMapView?
    var hasMapSettings: HasMapSettings
    weak var navigationController: UINavigationController?
    var scheme: MDCContainerScheming?
    var settingsCoordinator: MapSettingsCoordinator?
    weak var rootView: UIView?
    
    private lazy var mapSettingsButton: MDCFloatingButton = {
        let mapSettingsButton = MDCFloatingButton(shape: .mini)
        mapSettingsButton.setImage(UIImage(named:"layers"), for: .normal)
        mapSettingsButton.addTarget(self, action: #selector(mapSettingsButtonTapped(_:)), for: .touchUpInside)
        return mapSettingsButton
    }()
    
    init(hasMapSettings: HasMapSettings, navigationController: UINavigationController?, rootView: UIView?, scheme: MDCContainerScheming?) {
        self.hasMapSettings = hasMapSettings
        self.navigationController = navigationController
        self.scheme = scheme
        self.rootView = rootView
    }
    
    deinit {
        if let geoPackageImportedObserver = geoPackageImportedObserver {
            NotificationCenter.default.removeObserver(geoPackageImportedObserver, name: .GeoPackageImported, object: nil)
        }
        geoPackageImportedObserver = nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        self.scheme = scheme
        mapSettingsButton.backgroundColor = scheme?.colorScheme.surfaceColor;
        mapSettingsButton.tintColor = scheme?.colorScheme.primaryColor;
    }
    
    func setupMixin() {
        guard let mapView = self.hasMapSettings.mapView else {
            return
        }
        rootView?.insertSubview(mapSettingsButton, aboveSubview: mapView)
        mapSettingsButton.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
        mapSettingsButton.autoPinEdge(toSuperviewMargin: .right)
        
        setupMapSettingsButton()

        applyTheme(scheme: scheme)
        
        geoPackageImportedObserver = NotificationCenter.default.addObserver(forName: .GeoPackageImported, object: nil, queue: .main) { [weak self] notification in
            self?.setupMapSettingsButton()
        }
    }
    
    @objc func mapSettingsButtonTapped(_ sender: UIButton) {
        settingsCoordinator = MapSettingsCoordinator(rootViewController: navigationController, scheme: scheme)
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
            circle.layer.borderColor = scheme?.colorScheme.onSecondaryColor.withAlphaComponent(0.6).cgColor
            circle.backgroundColor = scheme?.colorScheme.primaryColorVariant
            let imageView = UIImageView(image: UIImage(named: "download"))
            imageView.frame = CGRect(x: 3, y: 2, width: 14, height: 15)
            imageView.tintColor = scheme?.colorScheme.onSecondaryColor
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
