//
//  URLRequestContext.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/29/26.
//

import Foundation

public protocol URLRequestContext: Sendable {
    var urlRequest: URLRequest? { get set }
}
