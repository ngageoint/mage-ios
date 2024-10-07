//
//  MageInjectionTestCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import OHHTTPStubs

@testable import MAGE

class MageInjectionTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        injectionSetup()
        clearAndSetUpStack()
    }
    
    override func tearDown() {
        clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    override func setUp() async throws {
        injectionSetup()
        clearAndSetUpStack()
    }
    
    override func tearDown() async throws {
        clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    func injectionSetup() {
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
        InjectedValues[\.feedItemRepository] = FeedItemRepositoryImpl()
        InjectedValues[\.feedItemLocalDataSource] = FeedItemStaticLocalDataSource()
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
