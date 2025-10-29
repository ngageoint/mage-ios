//
//  SettingsRemoteDataSource.swift
//  MAGE
//
//

import Foundation

private struct SettingsRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: SettingsRemoteDataSource = SettingsRemoteDataSourceImpl()
}

extension InjectedValues {
    var settingsRemoteDataSource: SettingsRemoteDataSource {
        get { Self[SettingsRemoteDataSourceProviderKey.self] }
        set { Self[SettingsRemoteDataSourceProviderKey.self] = newValue }
    }
}

protocol SettingsRemoteDataSource {
    func fetchMapSettings() async -> [AnyHashable: Any]?
}

class SettingsRemoteDataSourceImpl: ObservableObject, SettingsRemoteDataSource {
    func fetchMapSettings() async -> [AnyHashable: Any]? {
        let request = SettingsService.fetchMapSettings
        
        return await withCheckedContinuation { continuation in
            MageSession.shared.session.request(request)
                .validate(MageSession.shared.validateMageResponse)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try JSONSerialization.jsonObject(with: data)
                            if let json = json as? [AnyHashable: Any] {
                                continuation.resume(returning: json)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        } catch {
                            MageLogger.misc.error("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            continuation.resume(returning: nil)
                        }
                    case .failure(let error):
                        MageLogger.misc.error("Error \(error)")
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
    
}
