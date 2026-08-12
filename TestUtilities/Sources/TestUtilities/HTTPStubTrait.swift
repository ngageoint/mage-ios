//
//  HTTPStubTrait.swift
//  MAGE
//
//


import Testing
import OHHTTPStubsSwift
import OHHTTPStubs
import Alamofire
import Foundation

// adapted from https://jano.dev/wwdc24/apple/2024/06/12/Testing-Framework.html#tests-traits
public struct HTTPStubTrait: TestTrait, TestScoping, @unchecked Sendable {
    public static let HeaderKey: String = "X-Test-Stub-ID"
    var method: HTTPMethod
    var scheme: String
    var host: String
    var path: String? = nil
    var pathRegularExpression: NSRegularExpression? = nil
    var expectedHeaders: [String: String]? = nil
    var expectedJSONBody: [AnyHashable: Any]? = nil
    var expectedPartialBody: [AnyHashable: AnyHashable]? = nil
    var expectedQueryParameters: [String: String?]? = nil
    var responseZip: String? = nil
    var responseFile: String? = nil
    var responseJSON: [AnyHashable: Any]? = nil
    var responseArray: [[AnyHashable: Any]]? = nil
    var responseString: String? = nil
    var responseData: Data? = nil
    var responseError: NSError? = nil
    var responseHeaders: [String: String]? = nil
    var statusCode: Int32
    var callCount: Int = 1
    var waitTime: TimeInterval = 0
    var file: String
    var fileFunction: String
    
    public init(
        method: HTTPMethod,
        scheme: String,
        host: String,
        path: String? = nil,
        pathRegularExpression: NSRegularExpression? = nil,
        expectedHeaders: [String: String]? = nil,
        expectedJSONBody: [AnyHashable: Any]? = nil,
        expectedPartialBody: [AnyHashable: AnyHashable]? = nil,
        expectedQueryParameters: [String: String?]? = nil,
        responseZip: String? = nil,
        responseFile: String? = nil,
        responseJSON: [AnyHashable: Any]? = nil,
        responseArray: [[AnyHashable: Any]]? = nil,
        responseString: String? = nil,
        responseError: NSError? = nil,
        responseData: Data? = nil,
        responseHeaders: [String: String]? = nil,
        statusCode: Int32 = 200,
        callCount: Int = 1,
        waitTime: TimeInterval = 1,
        file: String = #file,
        function: String = #function
    ) {
        self.method = method
        self.scheme = scheme
        self.host = host
        self.path = path
        self.pathRegularExpression = pathRegularExpression
        self.expectedHeaders = expectedHeaders
        self.expectedJSONBody = expectedJSONBody
        self.expectedPartialBody = expectedPartialBody
        self.expectedQueryParameters = expectedQueryParameters
        self.responseZip = responseZip
        self.responseFile = responseFile
        self.responseJSON = responseJSON
        self.responseArray = responseArray
        self.responseString = responseString
        self.responseData = responseData
        self.responseError = responseError
        self.responseHeaders = responseHeaders
        self.statusCode = statusCode
        self.callCount = callCount
        self.waitTime = waitTime
        self.file = file
        self.fileFunction = function
    }
    
    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        // this is necessary due to a bug in the compiler
        // https://forums.swift.org/t/unexpected-compilation-error-with-testscoping-and-nonisolatednonsendingbydefault/81883
        performing function: @isolated(any) () async throws -> Void
//        performing function: @Sendable () async throws -> Void
    ) async throws {
        let methodTestBlock = {
            switch self.method {
            case .get: return isMethodGET()
            case .post: return isMethodPOST()
            case .put: return isMethodPUT()
            case .patch: return isMethodPATCH()
            case .delete: return isMethodDELETE()
            default: fatalError("Unsupported HTTP method: \(self.method)")
            }
        }
        var called = 0
        var testBlock = methodTestBlock() &&
            isScheme(scheme) &&
            isHost(host)
        
        if let path {
            testBlock = testBlock && isPath(path)
        }
        
        if let pathRegularExpression {
            testBlock = testBlock && pathMatches(pathRegularExpression)
        }
        if let expectedJSONBody {
            testBlock = testBlock && hasJsonBody(expectedJSONBody)
        }
        
        if let expectedQueryParameters {
            testBlock = testBlock && containsQueryParams(expectedQueryParameters)
        }
        
        if let expectedPartialBody {
            testBlock = testBlock && hasPartialJsonBody(expectedPartialBody)
        }
        
        if let expectedHeaders {
            for (headerName, headerValue) in expectedHeaders {
                testBlock = testBlock && hasHeaderNamed(headerName, value: headerValue)
            }
        }

        testBlock = testBlock && hasHttpStubTraitHeaderKey(test.id.description)
        
        let descriptor = stub(condition: testBlock
        ) { (request) -> HTTPStubsResponse in
            called = called + 1
            if let responseFile {
                let stubPath = TestUtilities.pathForFile(responseFile);
                if stubPath == nil {
                    print("XXXXX WHAT IS THIS FILE \(responseFile)")
                }
                return HTTPStubsResponse(
                    fileAtPath: stubPath!,
                    statusCode: statusCode,
                    headers: responseHeaders ?? ["Content-Type": "application/json"]
                );
            }
            else if let responseJSON {
                return HTTPStubsResponse(jsonObject: responseJSON, statusCode: statusCode, headers: responseHeaders ?? ["Content-Type": "application/json"]);
            }
            else if let responseArray {
                return HTTPStubsResponse(jsonObject: responseArray, statusCode: statusCode, headers: responseHeaders ?? ["Content-Type": "application/json"]);
            }
            else if let responseString {
                return HTTPStubsResponse(data: responseString.data(using: .utf8) ?? Data(), statusCode: statusCode, headers: responseHeaders ?? ["Content-Type": "application/octet-stream"]);
            }
            else if let responseData {
                print("Response data")
                return HTTPStubsResponse(
                    data: responseData,
                    statusCode: statusCode,
                    headers: responseHeaders ?? ["Content-Type": "application/json"]
                )
            }
            else if let responseZip {
                let stubPath = TestUtilities.pathForFile(responseZip);
                return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: statusCode, headers: responseHeaders ?? ["Content-Type": "application/octet-stream"]);
            }
            else if let responseError {
                let response = HTTPStubsResponse(error: responseError)
                response.statusCode = statusCode
                print("Returning response with error: \(response)")
                print("response status code \(response.statusCode)")
                return response
            }
            let response = HTTPStubsResponse()
            response.statusCode = statusCode
            return response
        }
        
        print("Created stub \(descriptor)")
        
        try await function()
        let startTime = Date()
        var checkCount = 0
        
        while called != callCount {
            checkCount += 1
            print("Call count is \(called) waiting for \(callCount) checked \(checkCount) times")
            if Date().timeIntervalSince(startTime) > waitTime {
                Issue.record(Comment(rawValue: "HTTP Stub \(path) was called \(called) times, expected \(callCount) from file \(file) function: \(fileFunction)"))
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        }
        print("Removing stub \(descriptor)")
        HTTPStubs.removeStub(descriptor)
    }
    
    public func hasPartialJsonBody(_ jsonObject: [AnyHashable : AnyHashable]) -> HTTPStubsTestBlock {
      return { req in
        guard
          let httpBody = req.ohhttpStubs_httpBody,
          let jsonBody = (try? JSONSerialization.jsonObject(with: httpBody, options: [])) as? [AnyHashable : Any]
        else {
          return false
        }
          var hasValues: Bool = true
          for (key, value) in jsonObject {
              if let bodyValue = jsonBody[key] as? AnyHashable {
                  hasValues = hasValues && (bodyValue == value)
              } else {
                  hasValues = false
              }
          }
          
        return hasValues
      }
    }
}

public func hasHttpStubTraitHeaderKey(_ value: String) -> HTTPStubsTestBlock {
    return { (req: URLRequest) -> Bool in
        let has = req.value(forHTTPHeaderField: HTTPStubTrait.HeaderKey) == value
        if !has && req.value(forHTTPHeaderField: HTTPStubTrait.HeaderKey) == nil {
            print("---------------------ALERT ALERT ALERT ALERT ------------------------------------------")
            print("----- HTTPStubTrait.HeaderKey is not in headers, this is causing the stub to fail -----")
            print("------ URL is \(req.url?.absoluteString ?? "")")
            print("---------------------ALERT ALERT ALERT ALERT ------------------------------------------")
        }
        return has
    }
}

// Make the trait available as a static property
public extension Trait where Self == HTTPStubTrait {
    static func httpStub(
        method: HTTPMethod,
        scheme: String,
        host: String,
        path: String? = nil,
        pathRegularExpression: NSRegularExpression? = nil,
        expectedHeaders: [String: String]? = nil,
        expectedJSONBody: [AnyHashable: Any]? = nil,
        expectedPartialBody: [AnyHashable: AnyHashable]? = nil,
        expectedQueryParameters: [String: String?]? = nil,
        responseZip: String? = nil,
        responseFile: String? = nil,
        responseJSON: [AnyHashable: Any]? = nil,
        responseArray: [[AnyHashable: Any]]? = nil,
        responseString: String? = nil,
        responseData: Data? = nil,
        responseError: NSError? = nil,
        responseHeaders: [String: String]? = nil,
        statusCode: Int32 = 200,
        callCount: Int = 1,
        waitTime: TimeInterval = 0,
        file: String = #file,
        function: String = #function
    ) -> Self { Self(
        method: method,
        scheme: scheme,
        host: host,
        path: path,
        pathRegularExpression: pathRegularExpression,
        expectedHeaders: expectedHeaders,
        expectedJSONBody: expectedJSONBody,
        expectedPartialBody: expectedPartialBody,
        expectedQueryParameters: expectedQueryParameters,
        responseZip: responseZip,
        responseFile: responseFile,
        responseJSON: responseJSON,
        responseArray: responseArray,
        responseString: responseString,
        responseError: responseError,
        responseData: responseData,
        responseHeaders: responseHeaders,
        statusCode: statusCode,
        callCount: callCount,
        waitTime: waitTime,
        file: file,
        function: function
    ) }
}
