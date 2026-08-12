//
//  OperationProgressHandler.swift
//  FetchOperation
//
//  Created by Daniel Barela on 8/11/26.
//


public typealias OperationProgressHandler = @Sendable (
    OperationProgress
) -> Void
