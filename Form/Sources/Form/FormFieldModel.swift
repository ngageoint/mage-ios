import SendableExtensions
import ServerDTO

public struct FormFieldModel: Sendable {
    public init(
        id: Int? = nil,
        title: String? = nil,
        type: String? = nil,
        required: Bool? = nil,
        name: String? = nil,
        value: AnyHashable? = nil,
        choices: [FieldOptionsModel]? = nil,
        maxRecent: Int? = 5,
        archived: Bool? = nil,
        min: Int? = nil,
        max: Int? = nil,
        hidden: Bool? = nil,
        allowedAttachmentTypes: [String]? = nil,
        eventId: EventID? = nil,
        eventFormId: EventFormID? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.required = required
        self.name = name
        self.sendableValue = SendableValue.makeSendableValue(value)
        self.choices = choices
        self.maxRecent = maxRecent
        self.archived = archived
        self.min = min
        self.max = max
        self.hidden = hidden
        self.allowedAttachmentTypes = allowedAttachmentTypes
        self.eventId = eventId
        self.eventFormId = eventFormId
    }
    
    public var id: Int?
    public var title: String?
    public var type: String?
    public var required: Bool?
    public var name: String?
    public var value: AnyHashable? {
        sendableValue?.anyHashableValue()
    }
    let sendableValue: SendableValue?
    public var choices: [FieldOptionsModel]?
    public var maxRecent: Int? = 5
    public var archived: Bool?
    public var min: Int?
    public var max: Int?
    public var hidden: Bool?
    public var allowedAttachmentTypes: [String]?
    public var eventId: EventID?
    public var eventFormId: EventFormID?
}
