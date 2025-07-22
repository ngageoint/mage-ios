//
//  SettingsRepository.swift
//  MAGE
//
//

import Foundation
import Combine

private struct SettingsRepositoryProviderKey: InjectionKey {
    static var currentValue: SettingsRepository = SettingsRepositoryImpl()
}

extension InjectedValues {
    var settingsRepository: SettingsRepository {
        get { Self[SettingsRepositoryProviderKey.self] }
        set { Self[SettingsRepositoryProviderKey.self] = newValue }
    }
}

// TODO: This is temporary until GeometryEditViewController is a swift class
@objc class SettingsProvider: NSObject {
    @Injected(\.settingsRepository)
    var repository: SettingsRepository
    
    @objc static var instance: SettingsProvider = SettingsProvider()
    
    var currentValue: SettingsModel?
    
    var cancellables: Set<AnyCancellable> = Set()
    
    override init() {
        super.init()
        repository.observeSettings()
            .sink { model in
                self.currentValue = model
            }
            .store(in: &cancellables)
    }

    @objc func getMapSearchTypeCode() -> Int32 {
        return currentValue?.mapSearchTypeCode ?? MapSearchType.none.rawValue
    }
}

protocol SettingsRepository {
    func observeSettings() -> AnyPublisher<SettingsModel?, Never>
    func getSettings() -> SettingsModel?
    func fetchMapSettings() async
}

class SettingsRepositoryImpl: ObservableObject, SettingsRepository {
    @Injected(\.settingsLocalDataSource)
    var localDataSource: SettingsLocalDataSource
    
    @Injected(\.settingsRemoteDataSource)
    var remoteDataSource: SettingsRemoteDataSource
    
    func observeSettings() -> AnyPublisher<SettingsModel?, Never> {
        localDataSource.getSettingsPublisher()
    }
    
    func getSettings() -> SettingsModel? {
        localDataSource.getSettings()
    }
    
    func fetchMapSettings() async {
        if let response = await remoteDataSource.fetchMapSettings() {
            await localDataSource.handleMapSettingsResponse(response: response)
        }
    }
}
