//
//  DataContext.swift
//  FetchOperation
//
//  Created by Daniel Barela on 8/12/26.
//

import Foundation

public protocol DataContext: Sendable {
    var data: Data? { get set }
}
