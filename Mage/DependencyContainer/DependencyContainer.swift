// 
//     
//  DependencyContainer.swift
//  MAGE
//
// 

import Persistence
import APIRouter
import Foundation
import UseCaseFactory
import SettingsFetch
import Settings

@MainActor
@objc public final class DependencyContainer: NSObject {
    @objc public static let shared = DependencyContainer()

    var persistence: PersistenceProtocol?
    var url: URL?
    var session: TokenAPISession?
    private var _useCaseFactory: UseCaseFactory?
    
    var appDependencies: AppDependencies?
    
    @objc public func configure(
        url: URL,
        additionalHeaders: [String: String]? = nil
    ) {
        
        self.persistence = PersistenceContainer.shared.get()
        self.url = url
        self.session = TokenAPISessionImpl(
            baseURL: url,
            loginType: UserDefaults.standard.loginType,
            additionalHeaders: additionalHeaders,
            notificationCenter: NotificationCenter.default
        )
        
        if let session, let persistence {
            let appDependencies = AppDependencies(
                settingsRepository: SettingsRepositoryFactory
                    .createRepository(
                        url: url,
                        session: session,
                        persistence: persistence
                    ),
                settingsFetch: SettingsFetchRepositoryFactory
                    .createFetchRepository(
                        url: url,
                        session: session,
                        persistence: persistence
                    )
            )
            _useCaseFactory = UseCaseComposition.build(deps: appDependencies)
        }
    }
    
    var useCaseFactory: UseCaseFactory {
        get throws {
            guard let factory = _useCaseFactory else {
                throw DependencyError.notConfigured
            }
            return factory
        }
    }
}
