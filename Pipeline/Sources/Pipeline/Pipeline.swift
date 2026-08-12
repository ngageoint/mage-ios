//
//  Pipeline.swift
//

public struct Pipeline<
    Context: Sendable,
    Output: Sendable
>: Sendable {
    
    private let operation: PipelineOperationKind
    private let initialContext: Context
    private let steps: [PipelineStep<Context>]
    private let output: @Sendable (Context) -> Output
    
    public init(
        operation: PipelineOperationKind,
        context: Context,
        
        @PipelineBuilder
        steps: () -> [PipelineStep<Context>],
        
        output: @escaping @Sendable (Context) -> Output
        
    ) {
        self.operation = operation
        self.initialContext = context
        self.steps = steps()
        self.output = output
    }
}

public extension Pipeline {
    
    func execute() -> any PipelineOperation<Output> {
        PipelineOperationState(
            kind: operation
        ) { execution in
            
            var context = initialContext
            
            for step in steps {
                let currentContext = context
                
                context = try await execution.run(
                    phase: step.phase
                ) { progress in
                    try await step.perform(
                        currentContext,
                        progress
                    )
                }
            }
            
            return output(context)
        }
    }
    
}
