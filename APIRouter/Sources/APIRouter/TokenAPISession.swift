//
//  TokenAPISession.swift
//  APIRouter
//
//  Created by Daniel Barela on 8/12/26.
//


import Alamofire

public protocol TokenAPISession: Sendable {
    var session: Session { get }
    func validateResponse() -> DataRequest.Validation
    func validateDownloadResponse() -> DownloadRequest.Validation
    func addTrustedHost(_ host: String)
}
