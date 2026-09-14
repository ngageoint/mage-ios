import Foundation
import FetchOperation
import ServerDTO
import LayerFetch
import Pipeline

public extension PipelineStep where Context: EventDTOContext & TeamContext & EventToEventFormDTOContext & EventToLayerContext & URLRequestContext {
    static func downloadEvents(
        remote: any EventFetchRemote
    ) -> Self
    {
        
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            
            context.eventDTO = try await remote.fetch(
                urlRequest: context.urlRequest,
                progress: progress
            )
            
            context.teamDTO = context.eventDTO.map {
                EventTeamDTO(
                    eventID: EventID($0.id.rawValue),
                    teamDTO: $0.teams ?? []
                )
            }
            
            context.eventToEventFormDTO = context.eventDTO.map {
                EventToEventFormDTO(
                    eventID: EventID($0.id.rawValue),
                    eventFormDTO: $0.forms ?? []
                )
            }
            
            context.eventToLayerDTO = context.eventDTO.map {
                EventToLayerDTO(
                    eventID: EventID($0.id.rawValue),
                    layerDTO: $0.layers ?? []
                )
            }
            
            return context
        }
    }
}

public extension PipelineStep where Context: EventDTOContext & EventSaveResultContext {
    static func saveEvents(
        local: any EventFetchLocal
    ) -> Self {
        Self(
            phase: .saving,
            perform: { context, progress in
                
                var context = context
                
                context.eventSaveResult = try await local.save(
                    context.eventDTO,
                    progress: progress
                )
                
                return context
            }
        )
    }
}
