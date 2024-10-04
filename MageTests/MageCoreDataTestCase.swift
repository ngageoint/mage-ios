//
//  MageCoreDataTestCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import Combine
import OHHTTPStubs
import CoreData

@testable import MAGE

class MageCoreDataTestCase: MageInjectionTestCase {
    @Injected(\.persistence)
    var persistence: Persistence
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistence.clearAndSetupStack()
    }
    
    override func tearDown() {
        super.tearDown()
        persistence.clearAndSetupStack()
    }
    
    func awaitDidSave(block: @escaping () async -> Void) async {
        let didSave = expectation(forNotification: .NSManagedObjectContextDidSave, object: context) { notification in
            return notification.userInfo?["inserted"] != nil || notification.userInfo?["deleted"] != nil || notification.userInfo?["updated"] != nil
        }
        await block()
        await fulfillment(of: [didSave], timeout: 3)
    }
}

class KIFMageInjectionTestCase: KIFSpec {
    var cancellables: Set<AnyCancellable> = Set()
    
    override open func setUp() {
        super.setUp()
        defaultObservationInjection()
        defaultImportantInjection()
        defaultObservationFavoriteInjection()
        defaultEventInjection()
        defaultUserInjection()
        defaultFormInjection()
        defaultAttachmentInjection()
        defaultRoleInjection()
        defaultLocationInjection()
        defaultObservationImageInjection()
        defaultStaticLayerInjection()
        defaultGeoPackageInjection()
        defaultFeedItemInjection()
        defaultObservationLocationInjection()
        defaultObservationIconInjection()
        defaultLayerInjection()
        
        clearAndSetUpStack()
    }
    
    override open func tearDown() {
        super.tearDown()
        clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    func clearAndSetUpStack() {
        TestHelpers.clearDocuments();
        TestHelpers.clearImageCache();
        TestHelpers.resetUserDefaults();
    }
    
    func defaultObservationInjection() {
        InjectedValues[\.observationLocalDataSource] = ObservationCoreDataDataSource()
        InjectedValues[\.observationRemoteDataSource] = ObservationRemoteDataSource()
        InjectedValues[\.observationRepository] = ObservationRepositoryImpl()
    }
    
    func defaultImportantInjection() {
        InjectedValues[\.observationImportantLocalDataSource] = ObservationImportantCoreDataDataSource()
        InjectedValues[\.observationImportantRemoteDataSource] = ObservationImportantRemoteDataSource()
        InjectedValues[\.observationImportantRepository] = ObservationImportantRepositoryImpl()
    }
    
    func defaultObservationFavoriteInjection() {
        InjectedValues[\.observationFavoriteLocalDataSource] = ObservationFavoriteCoreDataDataSource()
        InjectedValues[\.observationFavoriteRemoteDataSource] = ObservationFavoriteRemoteDataSource()
        InjectedValues[\.observationFavoriteRepository] = ObservationFavoriteRepositoryImpl()
    }
    
    func defaultEventInjection() {
        InjectedValues[\.eventLocalDataSource] = EventCoreDataDataSource()
        InjectedValues[\.eventRepository] = EventRepositoryImpl()
    }
    
    func defaultUserInjection() {
        InjectedValues[\.userLocalDataSource] = UserCoreDataDataSource()
        InjectedValues[\.userRemoteDataSource] = UserRemoteDataSourceImpl()
        InjectedValues[\.userRepository] = UserRepositoryImpl()
    }
    
    func defaultFormInjection() {
        InjectedValues[\.formRepository] = FormRepositoryImpl()
        InjectedValues[\.formLocalDataSource] = FormCoreDataDataSource()
    }
    
    func defaultAttachmentInjection() {
        InjectedValues[\.attachmentLocalDataSource] = AttachmentCoreDataDataSource()
        InjectedValues[\.attachmentRepository] = AttachmentRepositoryImpl()
    }
    
    func defaultRoleInjection() {
        InjectedValues[\.roleLocalDataSource] = RoleCoreDataDataSource()
        InjectedValues[\.roleRepository] = RoleRepositoryImpl()
    }
    
    func defaultLocationInjection() {
        InjectedValues[\.locationLocalDataSource] = LocationCoreDataDataSource()
        InjectedValues[\.locationRepository] = LocationRepositoryImpl()
    }
    
    func defaultObservationImageInjection() {
        InjectedValues[\.observationImageRepository] = ObservationImageRepositoryImpl()
    }
    
    func defaultStaticLayerInjection() {
        InjectedValues[\.staticLayerLocalDataSource] = StaticLayerCoreDataDataSource()
        InjectedValues[\.staticLayerRepository] = StaticLayerRepository()
    }
    
    func defaultLayerInjection() {
        InjectedValues[\.layerLocalDataSource] = LayerLocalCoreDataDataSource()
        InjectedValues[\.layerRepository] = LayerRepositoryImpl()
    }
    
    func defaultGeoPackageInjection() {
        if !(InjectedValues[\.geoPackageRepository] is GeoPackageRepositoryImpl) {
            InjectedValues[\.geoPackageRepository] = GeoPackageRepositoryImpl()
        }
    }
    
    func defaultFeedItemInjection() {
        InjectedValues[\.feedItemLocalDataSource] = FeedItemCoreDataDataSource()
        InjectedValues[\.feedItemRepository] = FeedItemRepositoryImpl()
    }
    
    func defaultObservationLocationInjection() {
        InjectedValues[\.observationLocationLocalDataSource] = ObservationLocationCoreDataDataSource()
        InjectedValues[\.observationLocationRepository] = ObservationLocationRepositoryImpl()
    }
    
    func defaultObservationIconInjection() {
        InjectedValues[\.observationIconLocalDataSource] = ObservationIconCoreDataDataSource()
        InjectedValues[\.observationIconRepository] = ObservationIconRepository()
    }
}
