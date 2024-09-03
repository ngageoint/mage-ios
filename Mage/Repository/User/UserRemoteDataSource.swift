//
//  UserRemoteDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/21/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct UserRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: UserRemoteDataSource = UserRemoteDataSourceImpl()
}

extension InjectedValues {
    var userRemoteDataSource: UserRemoteDataSource {
        get { Self[UserRemoteDataSourceProviderKey.self] }
        set { Self[UserRemoteDataSourceProviderKey.self] = newValue }
    }
}

protocol UserRemoteDataSource {
    func uploadAvatar(user: UserModel, imageData: Data) async -> [AnyHashable: Any]
    func fetchMyself() async -> [AnyHashable: Any]?
}

class UserRemoteDataSourceImpl: UserRemoteDataSource {
    func uploadAvatar(user: UserModel, imageData: Data) async -> [AnyHashable: Any]  {
        let request = UserService.uploadAvatar(imageData: imageData)
        
        return await withCheckedContinuation { continuation in
            MageSession.shared.session.upload(multipartFormData: { formData in
                formData.append(imageData, withName: "avatar", fileName: "avatar.jpeg", mimeType: "image/jpeg")
            }, with: request)
                .validate(MageSession.shared.validateMageResponse)
                .uploadProgress { progress in
                    print("progress \(progress)")
                }
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try JSONSerialization.jsonObject(with: data)
                            if let json = json as? [AnyHashable: Any] {
                                continuation.resume(returning: json)
                            }
                        } catch {
                            print("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            continuation.resume(returning: [:])
                        }
                    case .failure(let error):
                        print("Error \(error)")
                        continuation.resume(returning: [:])
                    }
                }
        }
    }
    
    func fetchMyself() async -> [AnyHashable: Any]? {
        let request = UserService.fetchMyself
        
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
                            }
                        } catch {
                            print("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            // TODO: what should this throw?
                            continuation.resume(returning: nil)
                        }
                    case .failure(let error):
                        print("Error \(error)")
                        // TODO: what should this throw?
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
}
