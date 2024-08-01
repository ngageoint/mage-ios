//
//  MageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 2/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MageMapViewController: UIViewController {
    var mapView: MainMageMapView?
    var scheme: MDCContainerScheming?;
    
    public init(scheme: MDCContainerScheming?) {
        super.init(nibName: nil, bundle: nil)
        self.scheme = scheme
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MainMageMapView(viewController: self, navigationController: self.navigationController, scheme: scheme)
        view.addSubview(mapView!)
        mapView?.autoPinEdgesToSuperviewEdges()
        NotificationCenter.default.addObserver(forName: .ObservationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }

        NotificationCenter.default.addObserver(forName: .LocationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        setNavBarTitle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        mapView = nil
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
        self.present(vc, animated: true, completion: nil)
    }
    
}
