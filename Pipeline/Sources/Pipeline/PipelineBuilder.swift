//
//  PipelineBuilder.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/22/26.
//


@resultBuilder
public enum PipelineBuilder {
    
    public static func buildBlock<Context>(
        _ steps: PipelineStep<Context>...
    ) -> [PipelineStep<Context>] {
        
        steps
    }
    
    public static func buildArray<Context>(
        _ components: [[PipelineStep<Context>]]
    ) -> [PipelineStep<Context>] {
        
        components.flatMap { $0 }
    }
    
    public static func buildOptional<Context>(
        _ component: [PipelineStep<Context>]?
    ) -> [PipelineStep<Context>] {
        
        component ?? []
    }
    
    public static func buildEither<Context>(
        first component: [PipelineStep<Context>]
    ) -> [PipelineStep<Context>] {
        
        component
    }
    
    public static func buildEither<Context>(
        second component: [PipelineStep<Context>]
    ) -> [PipelineStep<Context>] {
        
        component
    }
}
