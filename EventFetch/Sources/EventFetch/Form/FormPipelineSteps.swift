import FetchOperation
import ServerDTO
import Pipeline

public extension PipelineStep where Context: EventToEventFormDTOContext & EventFormSaveResultContext {
    static func saveForms(
        formImporter: EventFormImporter
    ) -> Self {
        Self(
            phase: .saving,
            perform: { context, progress in
                
                var context = context
                
                var saveResult = DefaultSaveResult.empty
                for eventToEventFormDTO in context.eventToEventFormDTO {
                    let deleteResult = try await formImporter.deleteForms(
                        eventID: eventToEventFormDTO.eventID
                    )
                    let saveFormsResult = try await formImporter.saveForms(
                        eventToEventFormDTO.eventFormDTO,
                        eventID: eventToEventFormDTO.eventID,
                        progress: progress
                    )
                    saveResult.combine(with: deleteResult)
                    saveResult.combine(with: saveFormsResult)
                }
                
                context.eventFormSaveResult = saveResult
                
                return context
            }
        )
    }
}
