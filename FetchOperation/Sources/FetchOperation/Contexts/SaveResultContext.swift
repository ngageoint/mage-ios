//
//  SaveResultContext.swift
//  FetchOperation
//
//  Created by Daniel Barela on 8/11/26.
//


public protocol SaveResultContext: Sendable {
    associatedtype SaveResult: Sendable
    
    var saveResult: SaveResult? { get set }
}
