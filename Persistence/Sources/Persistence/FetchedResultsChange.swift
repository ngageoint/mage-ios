// 
//     
//  FetchedResultsChange.swift
//  Persistence
//
// 

import Foundation

public enum FetchedResultsChange<T> {
    case initial([T])
    case insert(IndexPath, T)
    case delete(IndexPath, T)
    case update(IndexPath, T)
    case move(IndexPath, IndexPath)
}
