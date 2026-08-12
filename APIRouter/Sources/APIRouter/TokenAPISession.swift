//
//  TokenAPISession.swift
//  APIRouter
//
//


import Alamofire

public protocol TokenAPISession: Sendable {
    var session: Session { get }
    func validateResponse() -> DataRequest.Validation
    func validateDownloadResponse() -> DownloadRequest.Validation
    func addTrustedHost(_ host: String)
}
