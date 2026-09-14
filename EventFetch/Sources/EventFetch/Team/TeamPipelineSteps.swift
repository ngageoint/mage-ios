import FetchOperation
import Pipeline

public extension PipelineStep where Context: TeamContext & TeamSaveResultContext {
    static func saveTeams(
        local: any TeamFetchLocal
    ) -> Self {
        Self(
            phase: .saving,
            perform: { context, progress in
                
                var context = context
                
                context.teamSaveResult = try await local.save(
                    context.teamDTO,
                    progress: progress
                )
                
                return context
            }
        )
    }
}
