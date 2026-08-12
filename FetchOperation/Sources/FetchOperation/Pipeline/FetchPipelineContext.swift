//
//  FetchPipelineContext.swift
//  FetchOperation
//
//

import Foundation

public struct FetchPipelineContext<
    DTO: Decodable & Sendable,
    SaveResult: Sendable
>: Sendable, DTOContext, URLRequestContext, SaveResultContext {
    public var urlRequest: URLRequest?
    public var dto: [DTO] = []
    public var saveResult: SaveResult?
    
    public init(
        urlRequest: URLRequest? = nil
    ) {
        self.urlRequest = urlRequest
    }
}

public struct FetchPipelineDecodingContext<
    DTO: Decodable & Sendable,
    SaveResult: Sendable
>: Sendable, DTOContext, URLRequestContext, SaveResultContext, DataContext {
    public var urlRequest: URLRequest?
    public var dto: [DTO] = []
    public var saveResult: SaveResult?
    public var data: Data?
    
    public init(
        urlRequest: URLRequest? = nil
    ) {
        self.urlRequest = urlRequest
    }
}

