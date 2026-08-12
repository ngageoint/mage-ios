//
//  DataContext.swift
//  FetchOperation
//
//

import Foundation

public protocol DataContext: Sendable {
    var data: Data? { get set }
}
