//
//  DefaultFetchPipeline.swift
//  FetchOperation
//
//

import Foundation
import Pipeline

public enum FetchPipelines {
    
    public static func `default`<
        Remote: FetchRemoteDataSource,
        Local: FetchLocalDataSource
    >(
        remote: Remote,
        local: Local,
        operation: PipelineOperationKind
    ) -> Pipeline<
        FetchPipelineContext<Remote.DTO, Local.SaveResult>,
        [Remote.DTO]
    >
    where Remote.DTO == Local.DTO {
        
        Pipeline<FetchPipelineContext<Remote.DTO, Local.SaveResult>, [Remote.DTO]>(
            operation: operation,
            context: FetchPipelineContext<Remote.DTO, Local.SaveResult>()
        ) {
            PipelineStep<FetchPipelineContext<Remote.DTO, Local.SaveResult>>.download(remote: remote)
            PipelineStep<FetchPipelineContext<Remote.DTO, Local.SaveResult>>.save(local: local)
        } output: {
            $0.dto
        }
    }
    
    public static func `defaultWithDecodingProgress`<
        Remote: FetchDataRemoteDataSource,
        Local: FetchLocalDataSource
    >(
        remote: Remote,
        local: Local,
        operation: PipelineOperationKind
    ) -> Pipeline<
        FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>,
        [Local.DTO]
    > {
        
        Pipeline<FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>, [Local.DTO]>(
            operation: operation,
            context: FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>()
        ) {
            PipelineStep<FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>>.downloadData(remote: remote)
            PipelineStep<FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>>.decode()
            PipelineStep<FetchPipelineDecodingContext<Local.DTO, Local.SaveResult>>.save(local: local)
        } output: {
            $0.dto
        }
    }
}
