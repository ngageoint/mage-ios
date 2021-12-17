//
//  MainMageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class MainMageMapViewController: MageMapViewController, FilteredObservationsMap, FilteredUsersMap, BottomSheetEnabled, MapDirections, PersistedMapState {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?
    var bottomSheetMixin: BottomSheetMixin?
    var mapDirectionsMixin: MapDirectionsMixin?
    var persistedMapStateMixin: PersistedMapStateMixin?
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .ViewObservation, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapView {
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, scheme: scheme)
            filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, scheme: scheme)
            bottomSheetMixin = BottomSheetMixin(mapView: mapView, navigationController: self.navigationController, scheme: scheme)
            mapDirectionsMixin = MapDirectionsMixin(mapDirections: self, viewController: self, mapStack: mapStack, scheme: scheme)
            persistedMapStateMixin = PersistedMapStateMixin(persistedMapState: self)
            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(filteredUsersMapMixin!)
            mapMixins.append(bottomSheetMixin!)
            mapMixins.append(mapDirectionsMixin!)
            mapMixins.append(persistedMapStateMixin!)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: .MapViewDisappearing, object: nil)
    }
    
    func setupNavigationBar() {
        let filterButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterTapped(_:)))
        navigationItem.rightBarButtonItems = [filterButton]
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
