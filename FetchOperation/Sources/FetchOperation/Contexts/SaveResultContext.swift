//
//  SaveResultContext.swift
//  FetchOperation
//
//


public protocol SaveResultContext: Sendable {
    associatedtype SaveResult: Sendable
    
    var saveResult: SaveResult? { get set }
}
