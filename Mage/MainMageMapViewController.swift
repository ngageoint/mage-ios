//
//  MainMageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import MaterialComponents
import CoreData

class MainMageMapViewController: MageMapViewController, FilteredObservationsMap, FilteredUsersMap, BottomSheetEnabled, MapDirections,  HasMapSettings, CanCreateObservation, CanReportLocation, UserHeadingDisplay, UserTrackingMap, StaticLayerMap, PersistedMapState, GeoPackageLayerMap {

    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?
    var bottomSheetMixin: BottomSheetMixin?
    var mapDirectionsMixin: MapDirectionsMixin?
    var persistedMapStateMixin: PersistedMapStateMixin?
    var hasMapSettingsMixin: HasMapSettingsMixin?
    var canCreateObservationMixin: CanCreateObservationMixin?
    var canReportLocationMixin: CanReportLocationMixin?
    var userTrackingMapMixin: UserTrackingMapMixin?
    var userHeadingDisplayMixin: UserHeadingDisplayMixin?
    var staticLayerMapMixin: StaticLayerMapMixin?
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    
    private lazy var buttonStack: UIStackView = {
        let buttonStack = UIStackView.newAutoLayout()
        buttonStack.alignment = .fill
        buttonStack.distribution = .fill
        buttonStack.spacing = 10
        buttonStack.axis = .vertical
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.isLayoutMarginsRelativeArrangement = true
        return buttonStack
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .ViewObservation, object: nil)
        NotificationCenter.default.removeObserver(self, name: .StartStraightLineNavigation, object: nil)
        NotificationCenter.default.removeObserver(self, name: .ObservationFiltersChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .LocationFiltersChanged, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapView {
            self.view.insertSubview(buttonStack, aboveSubview: mapView)
            buttonStack.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
            buttonStack.autoPinEdge(toSuperviewMargin: .left)
            
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, scheme: scheme)
            filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, scheme: scheme)
            bottomSheetMixin = BottomSheetMixin(mapView: mapView, navigationController: self.navigationController, scheme: scheme)
            mapDirectionsMixin = MapDirectionsMixin(mapDirections: self, viewController: self, mapStack: mapStack, scheme: scheme)
            persistedMapStateMixin = PersistedMapStateMixin(persistedMapState: self)
            hasMapSettingsMixin = HasMapSettingsMixin(hasMapSettings: self, navigationController: navigationController, rootView: view, scheme: scheme)
            canCreateObservationMixin = CanCreateObservationMixin(canCreateObservation: self, navigationController: navigationController, rootView: view, mapStackView: mapStack, scheme: scheme, locationService: nil)
            canReportLocationMixin = CanReportLocationMixin(canReportLocation: self, buttonParentView: buttonStack, indexInView: 1, scheme: scheme)
            userTrackingMapMixin = UserTrackingMapMixin(userTrackingMap: self, buttonParentView: buttonStack, indexInView: 0, scheme: scheme)
            userHeadingDisplayMixin = UserHeadingDisplayMixin(userHeadingDisplay: self, mapStack: mapStack, scheme: scheme)
            staticLayerMapMixin = StaticLayerMapMixin(staticLayerMap: self, scheme: scheme)
            geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(filteredUsersMapMixin!)
            mapMixins.append(bottomSheetMixin!)
            mapMixins.append(mapDirectionsMixin!)
            mapMixins.append(persistedMapStateMixin!)
            mapMixins.append(hasMapSettingsMixin!)
            mapMixins.append(canCreateObservationMixin!)
            mapMixins.append(canReportLocationMixin!)
            mapMixins.append(userTrackingMapMixin!)
            mapMixins.append(userHeadingDisplayMixin!)
            mapMixins.append(staticLayerMapMixin!)
            mapMixins.append(geoPackageLayerMapMixin!)
        }
        
        initiateMapMixins()
        
        NotificationCenter.default.addObserver(forName: .ViewObservation, object: nil, queue: .main) { [weak self] notification in
            if let observation = notification.object as? Observation {
                self?.viewObservation(observation)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object:nil, queue: .main) { [weak self] notification in
            self?.tabBarController?.selectedViewController = self
        }
        
        NotificationCenter.default.addObserver(forName: .ObservationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }
        
        NotificationCenter.default.addObserver(forName: .LocationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationBar()
        setNavBarTitle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: .MapViewDisappearing, object: nil)
    }
    
    func setupNavigationBar() {
        let filterButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterTapped(_:)))
        navigationItem.rightBarButtonItems = [filterButton]
    }
    
    func setNavBarTitle() {
        guard let event = Event.getCurrentEvent(context: NSManagedObjectContext.mr_default()) else {
            return
        }
        if !MageFilter.getString().isEmpty || !MageFilter.getLocationFilterString().isEmpty {
            self.navigationItem.setTitle(event.name, subtitle: "Showing filtered results.", scheme: scheme)
        } else {
            self.navigationItem.setTitle(event.name, subtitle: nil, scheme: scheme)
        }
    }
    
    @objc func filterTapped(_ sender: UIBarButtonItem) {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil)
        guard let vc = filterStoryboard.instantiateInitialViewController() as? UINavigationController else {
            return
        }
        if let fvc: FilterTableViewController = vc.topViewController as? FilterTableViewController {
            fvc.applyTheme(withContainerScheme: scheme)
        }
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.barButtonItem = sender
        present(vc, animated: true, completion: nil)
    }
}

extension MainMageMapViewController : ObservationActionsDelegate {
    
    func viewObservation(_ observation: Observation) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme)
        navigationController?.pushViewController(ovc, animated: true)
    }
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        observation.toggleFavorite { (_, _) in
            NotificationCenter.default.post(name: .ObservationUpdated, object: observation)
            //            self.mageBottomSheet.currentBottomSheetView?.refresh();
            //            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            //            completion?(observation)
        }
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        //        self.resetEnlargedPin();
        //        self.mageBottomSheet.dismiss(animated: true, completion: {
        //            guard let location = observation.location else {
        //                return;
        //            }
        //            var extraActions: [UIAlertAction] = [];
        //            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
        //                self.observationToNavigateTo = observation;
        //                self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
        //                self.userToNavigateTo = nil;
        //                self.feedItemToNavigateTo = nil;
        //                self.startStraightLineNavigation(location.coordinate, image: ObservationImage.image(observation: observation));
        //            }));
        //            ObservationActionHandler.getDirections(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: observation.primaryFeedFieldText ?? "Observation", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        //        });
    }
    
}
