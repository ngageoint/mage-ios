//
//  URLRequestContext.swift
//  FetchOperation
//
//

import Foundation

public protocol URLRequestContext: Sendable {
    var urlRequest: URLRequest? { get set }
}
