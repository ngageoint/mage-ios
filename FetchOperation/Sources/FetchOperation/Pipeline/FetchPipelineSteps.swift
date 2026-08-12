import ProgressReportingJSONDecoder
import Pipeline

public extension PipelineStep where Context: DTOContext & URLRequestContext {
    
    static func download<Remote>(
        remote: Remote
    ) -> Self
    where
    Remote: FetchRemoteDataSource,
    Context.DTO == Remote.DTO
    {
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            
            context.dto = try await remote.fetch(
                urlRequest: context.urlRequest,
                progress: progress
            )
            
            return context
        }
    }
}

public extension PipelineStep where Context: DataContext & URLRequestContext {
    
    static func downloadData<Remote>(
        remote: Remote
    ) -> Self
    where
    Remote: FetchDataRemoteDataSource
    {
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            
            context.data = try await remote.fetch(
                urlRequest: context.urlRequest,
                progress: progress
            )
            
            return context
        }
    }
}

public extension PipelineStep where Context: DTOContext & DataContext {
    
    static func decode() -> Self
    {
        Self(
            phase: .decoding
        ) { context, progress in
            
            var context = context
            
            let decoder = ProgressReportingJSONDecoder { decodingProgress in
                progress(
                    OperationProgress(
                        completed: Int64(decodingProgress.completed),
                        total: Int64(decodingProgress.total)
                    )
                )
            }
            guard let data = context.data else { return context }
            context.dto = try decoder.decode(
                [Context.DTO].self,
                from: data
            )
            
            return context
        }
    }
}

public extension PipelineStep where Context: DTOContext & SaveResultContext {
    
    static func save<Local>(
        local: Local
    ) -> Self
    where
    Local: FetchLocalDataSource,
    Context.DTO == Local.DTO,
    Context.SaveResult == Local.SaveResult
    {
        Self(
            phase: .saving
        ) { context, progress in
            
            var context = context
            
            context.saveResult = try await local.save(
                context.dto,
                progress: progress
            )
            
            return context
        }
    }
}
