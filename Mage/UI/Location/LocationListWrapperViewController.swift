//
//  LocationListWrapperViewController.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class LocationListWrapperViewController: SwiftUIViewController {
    @Injected(\.locationRepository)
    var locationRepository: LocationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    var scheme: MDCContainerScheming?
    var router: MageRouter
    
    init(scheme: MDCContainerScheming?, router: MageRouter) {
        self.scheme = scheme
        self.router = router
        super.init()
        swiftUIView = AnyView( LocationList(
            viewLocationUser: { locationUri in
                self.viewUser(locationUri: locationUri)
            },
            launchFilter: {
                self.launchFilter()
            }
        ).environmentObject(router))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavBarTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchFilter))
    }
    
    @objc func launchFilter() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: LocationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "locationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.navigationController?.pushViewController(fvc, animated: true);
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getLocationFilterString()
        self.navigationItem.setTitle("People", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    func viewUser(locationUri: URL) {
        
        Task { @MainActor [weak self] in
            if let location = await self?.locationRepository.getLocation(locationUri: locationUri),
               let userId = location.userModel?.userId
            {
                let uvc = UserViewWrapperViewController(userUri: userId, scheme: self?.scheme, router: router)
                self?.navigationController?.pushViewController(uvc, animated: true)
            }
        }
    }
}
