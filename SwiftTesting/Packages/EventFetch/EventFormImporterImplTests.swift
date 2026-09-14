// 
//     
//  EventFormImporterImplTests.swift
//  MAGE
//
// 


import Testing
import Persistence
import SendableExtensions
import FetchOperation
import Pipeline
import Layer
import LayerFetch
import TestUtilities
import CoreData
import CodableExtensions
import Event
import User
import Form

@testable import ServerDTO
@testable import EventFetch

extension CoreDataTests {
    struct EventFormImporterImplTests {
        let persistence: PersistenceProtocol
        let importer: EventFormImporterImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            importer = EventFormImporterImpl(persistence: persistence)
        }
        
        // MARK: - deleteForms
        
        @Test
        func `deleteForms deletes forms for event`() async throws {
            let eventID = EventID(1)
            
            _ = try await persistence.write { context in
                let form1 = Form(context: context)
                form1.eventId = eventID.rawValue
                
                let form2 = Form(context: context)
                form2.eventId = eventID.rawValue
                try? context.obtainPermanentIDs(for: [form1, form2])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Form.self, 2)
            
            let result = try await importer.deleteForms(eventID: eventID)
            
            #expect(result.deleted == 2)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Form.self, 0, predicate: NSPredicate(
                    format: "%K == %@",
                    FormKey.eventId.key,
                    eventID.rawValue
                ))
        }
        
        @Test
        func `deleteForms does not delete forms for another event`() async throws {
            let eventID = EventID(1)
            let otherEventID = EventID(2)
            
            _ = try await persistence.write { context in
                let form1 = Form(context: context)
                form1.eventId = eventID.rawValue
                
                let form2 = Form(context: context)
                form2.eventId = otherEventID.rawValue
                try? context.obtainPermanentIDs(for: [form1, form2])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Form.self, 2)

            let result = try await importer.deleteForms(eventID: eventID)
            
            #expect(result.deleted == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Form.self, 0, predicate: NSPredicate(
                    format: "%K == %@",
                    FormKey.eventId.key,
                    eventID.rawValue
                ))
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Form.self, 1, predicate: NSPredicate(
                    format: "%K == %@",
                    FormKey.eventId.key,
                    otherEventID.rawValue
                ))
        }
        
        @Test
        func `deleteForms returns zero when event has no forms`() async throws {
            let result = try await importer.deleteForms(eventID: EventID(1))
            
            #expect(result.deleted == 0)
        }
        
        // MARK: - saveForms
        
        @Test
        func `saveForms inserts forms`() async throws {
            let eventID = EventID(1)
            let dto = EventFormDTO(
                id: EventFormID(1),
                name: "Form 1"
            )
            
            let result = try await importer.saveForms(
                [dto],
                eventID: eventID,
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Form.self, 1, predicate: NSPredicate(
                    format: "%K == %@",
                    FormKey.eventId.key,
                    eventID.rawValue
                ))
        }
        
        @Test
        func `saveForms inserts forms in their input order`() async throws {
            let eventID = EventID(1)
            let firstDTO = EventFormDTO(
                id: EventFormID(1),
                name: "Form 1"
            )
            let secondDTO = EventFormDTO(
                id: EventFormID(2),
                name: "Form 2"
            )
            
            let result = try await importer.saveForms(
                [firstDTO, secondDTO],
                eventID: eventID,
                progress: { _ in }
            )
            
            #expect(result.inserted == 2)
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Form.self, 2)
            
            try await persistence.read { context in
                let forms = try? context.fetchObjects(Form.self)
                #expect(forms?.count == 2)
                #expect(forms?.contains { $0.order == 0 } == true)
                #expect(forms?.contains { $0.order == 1 } == true)
                #expect(forms?.allSatisfy { $0.eventId == eventID.rawValue } == true)
            }
        }
        
        @Test
        func `saveForms returns empty result when there are no forms`() async throws {
            var progressValues: [OperationProgress] = []
            
            let result = try await importer.saveForms(
                [],
                eventID: EventID(1),
                progress: { progressValues.append($0) }
            )
            
            #expect(result.inserted == 0)
            #expect(progressValues.count == 1)
            #expect(progressValues[0].completed == 0)
            #expect(progressValues[0].total == 0)
        }
        
        @Test
        func `saveForms reports final progress`() async throws {
            let eventID = EventID(1)
            let dto1 = EventFormDTO(
                id: EventFormID(1),
                name: "Form 1"
            )
            let dto2 = EventFormDTO(
                id: EventFormID(2),
                name: "Form 2"
            )
            
            var progressValues: [OperationProgress] = []
            
            _ = try await importer.saveForms(
                [dto1, dto2],
                eventID: eventID,
                progress: { progressValues.append($0) }
            )
            
            let finalProgress = try #require(progressValues.last)
            
            #expect(finalProgress.completed == 2)
            #expect(finalProgress.total == 2)
        }
        
        @Test
        func `saveForms reports progress every five forms`() async throws {
            let eventID = EventID(1)
            
            let dto = (1...6).map {
                EventFormDTO(
                    id: EventFormID($0),
                    name: "Form \($0)"
                )
            }
            
            var progressValues: [OperationProgress] = []
            
            _ = try await importer.saveForms(
                dto,
                eventID: eventID,
                progress: { progressValues.append($0) }
            )
            
            #expect(progressValues.count == 3)
            #expect(progressValues[0].completed == 0)
            #expect(progressValues[0].total == 6)
            #expect(progressValues[1].completed == 5)
            #expect(progressValues[1].total == 6)
            #expect(progressValues[2].completed == 6)
            #expect(progressValues[2].total == 6)
        }
    }
}

