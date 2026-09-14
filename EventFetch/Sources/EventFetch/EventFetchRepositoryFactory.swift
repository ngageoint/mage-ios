import Foundation
import Persistence
import FetchOperation
import ServerDTO
import APIRouter
import LayerFetch
import Pipeline

public enum EventFetchRepositoryFactory {
    public static let fetchOperationKind = PipelineOperationKind(rawValue: "fetch events")
    
    public static func make(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<Void, EventRepositoryFetchResult> {
        
        make(
            remote: EventFetchRemoteImpl(url: url, session: session),
            eventLocal: EventFetchLocalImpl(persistence: persistence),
            teamLocal: TeamFetchLocalImpl(persistence: persistence),
            formImporter: EventFormImporterImpl(persistence: persistence),
            layerImporter: LayerImporterImpl(persistence: persistence)
        )
    }
    
    public static func make(
        remote: any EventFetchRemote,
        eventLocal: any EventFetchLocal,
        teamLocal: any TeamFetchLocal,
        formImporter: EventFormImporter,
        layerImporter: LayerImporter
    ) -> AnyFetchRepository<Void, EventRepositoryFetchResult> {
        AnyFetchRepository(
            FetchRepository<Void, EventRepositoryFetchResult> { input in
                let pipeline = Pipeline(
                    operation: fetchOperationKind,
                    context: EventPipelineContext(
                        eventSaveResult: EventSaveResult.empty
                    )
                ) {
                    PipelineStep<EventPipelineContext>.downloadEvents(remote: remote)
                    PipelineStep<EventPipelineContext>.saveEvents(local: eventLocal)
                    PipelineStep<EventPipelineContext>.saveTeams(local: teamLocal)
                    PipelineStep<EventPipelineContext>.saveForms(formImporter: formImporter)
                    PipelineStep<EventPipelineContext>.saveLayers(layerImporter: layerImporter)
                } output: {
                    return EventRepositoryFetchResult(
                        dto: $0.eventDTO,
                        eventSaveResult: $0.eventSaveResult,
                        layerSaveResult: $0.layerSaveResult,
                        formSaveResult: $0.eventFormSaveResult,
                        teamSaveResult: $0.teamSaveResult
                    )
                }
                
                return pipeline.execute()
            }
        )
    }
}
