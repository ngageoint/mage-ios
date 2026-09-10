import FetchOperation
import ServerDTO
import LayerFetch
import Foundation

struct EventPipelineContext:
    EventDTOContext,
    EventSaveResultContext,
    URLRequestContext,
    TeamContext,
    TeamSaveResultContext,
    EventToEventFormDTOContext,
    EventFormSaveResultContext,
    EventToLayerContext,
    LayerSaveResultContext
{
    var urlRequest: URLRequest?
    var eventDTO: [EventDTO] = []
    var eventSaveResult: EventSaveResult?
    var teamDTO: [EventTeamDTO] = []
    var teamSaveResult: TeamSaveResult?
    var eventToEventFormDTO: [EventToEventFormDTO] = []
    var eventFormSaveResult: DefaultSaveResult?
    var eventToLayerDTO: [EventToLayerDTO] = []
    var layerSaveResult: LayerSaveResult?
}

