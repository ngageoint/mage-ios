//
//  FetchPipelineOperationPhase.swift
//  FetchOperation
//
//


import Foundation
import Pipeline

public extension PipelineOperationPhase {
    static let downloading =
        PipelineOperationPhase(rawValue: "downloading")

    static let saving =
        PipelineOperationPhase(rawValue: "saving")

    static let syncing =
        PipelineOperationPhase(rawValue: "syncing")

    static let preparing =
        PipelineOperationPhase(rawValue: "preparing")

    static let parsing =
        PipelineOperationPhase(rawValue: "parsing")
    
    static let decoding =
        PipelineOperationPhase(rawValue: "decoding")
}
