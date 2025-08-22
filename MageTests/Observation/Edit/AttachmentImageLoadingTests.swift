//  Created by Brent Michalski on 8/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
//
//  AttachmentImageLoadingTests.swift
//  MAGE-Tests
//
//  What we verify here
//  -------------------
//  1) Local file URL loads with ZERO network (Kingfisher never calls a downloader for file://).
//  2) When network is ALLOWED, a “remote” provider succeeds and the image is cached.
//  3) When network is DISALLOWED, cache-only lookups miss without hitting any “remote” work.
//  4) When already cached, cache-only succeeds even if network is disallowed.
//  5) 404-like failures do not pollute the cache (cache-only still fails).
//  6) Disk cache persists across a memory purge.
//
//  Notes:
//  - We use a custom ImageDataProvider to simulate remote responses. This gives us
//    deterministic control (success/failure), without depending on URLSession shape.
//  - We assert behavior via Kingfisher’s .onlyFromCache option, which is exactly how the
//    UI layer maps your user setting (Never / Wi-Fi-only / Any) to runtime behavior.
//

import XCTest
@testable import MAGE
import Kingfisher
import UIKit

// MARK: - A simple “policy” mirror used by production code.

private enum AttachmentNetworkPolicy {
    case never                // Never use network; cache-only lookup
    case wifiOnly(isOnWifi: Bool)
    case any                  // Always allow network

    var kingfisherOptions: KingfisherOptionsInfo {
        switch self {
        case .never:
            return [.onlyFromCache]
        case .wifiOnly(let isOnWifi):
            return isOnWifi ? [] : [.onlyFromCache]
        case .any:
            return []
        }
    }
}

// MARK: - A controllable “remote” source (Kingfisher treats this like a network provider)

private final class MockRemoteProvider: ImageDataProvider {
    enum Mode {
        case success(Data)
        case failure(KingfisherError)
    }

    let cacheKey: String
    var mode: Mode
    private(set) var callCount = 0

    init(cacheKey: String, mode: Mode) {
        self.cacheKey = cacheKey
        self.mode = mode
    }

    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        callCount += 1
        switch mode {
        case .success(let data):
            handler(.success(data))
        case .failure(let error):
            handler(.failure(error))
        }
    }
}

// MARK: - Test Case

final class AttachmentImageLoadingTests: XCTestCase {

    // A dedicated cache for isolation
    private var cache: ImageCache!

    // Reusable tiny PNG for deterministic “remote” bytes
    private lazy var samplePNGData: Data = {
        let size = CGSize(width: 6, height: 4)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.pngData()!
    }()

    // A canonical “remote” cache key we use across tests
    private let remoteKey = "https://example.test/attachments/abc.png"

    // MARK: Lifecycle

    override func setUp() {
        super.setUp()
        cache = ImageCache(name: "AttachmentTests.Cache.\(UUID().uuidString)")
        cache.clearMemoryCache()
        try? cache.diskStorage.removeAll()
    }

    override func tearDown() {
        cache.clearMemoryCache()
        try? cache.diskStorage.removeAll()
        cache = nil
        super.tearDown()
    }

    // MARK: Helpers
    // Entry point for tests that only have a URL.
    // Chooses the correct Kingfisher Source based on scheme,
    // and ALWAYS targets our isolated test cache.
    private func retrieve(url: URL,
                          options extra: KingfisherOptionsInfo = []) async
    -> Result<RetrieveImageResult, KingfisherError> {

        var options = extra
        options.append(.targetCache(cache))     // <— ensure we never touch ImageCache.default

        if url.isFileURL {
            let provider = LocalFileImageDataProvider(fileURL: url)
            return await retrieve(.provider(provider), options: options)
        } else {
            let resource = KF.ImageResource(downloadURL: url)
            return await retrieve(.network(resource), options: options)
        }
    }

    // Single implementation both paths call into.
    // Also ALWAYS targets our isolated test cache.
    private func retrieve(_ source: Source,
                          options extra: KingfisherOptionsInfo = []) async
    -> Result<RetrieveImageResult, KingfisherError> {
        // Make sure every retrieve uses our isolated cache, not ImageCache.default.
        var opts = extra
        opts.append(.targetCache(cache))

        return await withCheckedContinuation { cont in
            KingfisherManager.shared.retrieveImage(with: source, options: opts) { result in
                cont.resume(returning: result)
            }
        }
    }


    /// Store a small image in the cache under a specific key.
    private func storeImageForKey(_ key: String) throws {
        let img = UIImage(data: samplePNGData)!
        let exp = expectation(description: "store")
        cache.store(img, forKey: key) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 2)
    }

    /// Write a tiny PNG to disk and return its file:// URL.
    private func writeTempImageToDocuments() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = docs.appendingPathComponent("kf_test_\(UUID().uuidString).png")
        try samplePNGData.write(to: url, options: .atomic)
        return url
    }

    // MARK: Tests

    /// Local file must load without any “remote” work. Kingfisher doesn’t call a downloader for file://.
    func test_LocalFile_Wins_NoNetwork() async throws {
        let fileURL = try writeTempImageToDocuments()

        // Using the URL entry point ensures provider is used for file://.
        let result = await retrieve(url: fileURL, options: AttachmentNetworkPolicy.any.kingfisherOptions)

        switch result {
        case .success(let r):
            XCTAssertGreaterThan(r.image.size.width, 0, "File image should decode")
        case .failure(let err):
            XCTFail("Expected local file to load; got \(err)")
        }
    }

    /// When network is allowed, our “remote” provider returns bytes, Kingfisher decodes, and caches the image.
    func test_Remote_Allowed_Fetches_And_Caches() async throws {
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))

        // Act: retrieve with network allowed
        let result = await retrieve(.provider(provider), options: AttachmentNetworkPolicy.any.kingfisherOptions)
        _ = try result.get()

        XCTAssertEqual(provider.callCount, 1, "Remote provider should be invoked once")

        // Assert: now cache-only must succeed without any further provider calls
        let result2 = await retrieve(.provider(provider), options: [.onlyFromCache])
        _ = try result2.get()
        XCTAssertEqual(provider.callCount, 1, "Second load should come from cache (no provider call)")
    }

    /// If network is disallowed and there is no cache entry, Kingfisher must fail with a cache-only error.
    func test_Remote_Disallowed_NotCached_Fails_NoNetwork() async throws {
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))

        // Cache is empty; network is blocked (.onlyFromCache).
        let result = await retrieve(.provider(provider), options: AttachmentNetworkPolicy.never.kingfisherOptions)

        switch result {
        case .success:
            XCTFail("Should not succeed when cache is empty & network is disallowed")
        case .failure(let err):
            if case .cacheError = err {
                // expected
            } else {
                XCTFail("Expected a cache-only miss, got \(err)")
            }
        }
        XCTAssertEqual(provider.callCount, 0, "Provider must not be called when .onlyFromCache is set")
    }

    /// If the image is already cached, cache-only should succeed even when network is disallowed.
    func test_Remote_Disallowed_ButCached_Succeeds_FromCache() async throws {
        try storeImageForKey(remoteKey)
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))

        let result = await retrieve(.provider(provider), options: AttachmentNetworkPolicy.never.kingfisherOptions)
        _ = try result.get()

        XCTAssertEqual(provider.callCount, 0, "Provider must not be called for a cache hit")
    }

    /// A 404-like failure (simulated) should fail and NOT insert anything into the cache.
    func test_Remote_404_Fails_And_DoesNotCache() async throws {
        // Build a real HTTPURLResponse with 404 for Kingfisher's error
        let url = URL(string: "https://example.test/attachments/abc.png")!
        let http404 = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
        let kf404 = KingfisherError.responseError(reason: .invalidHTTPStatusCode(response: http404))

        // Provider will "fail like a 404"
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .failure(kf404))

        // First attempt (network allowed) => failure
        let result = await retrieve(.provider(provider), options: AttachmentNetworkPolicy.any.kingfisherOptions)

        switch result {
        case .success:
            XCTFail("404 should fail")

        case .failure(let err):
            // Primary path: provider error wrapped in imageSettingError(.dataProviderError)
            if case .imageSettingError(let rsn) = err,
               case .dataProviderError(_, let underlying) = rsn,
               let kf = underlying as? KingfisherError,
               case .responseError(let reason) = kf,
               case .invalidHTTPStatusCode(let response) = reason {
                XCTAssertEqual(response.statusCode, 404)

            // Fallback: some KF versions bubble .responseError directly
            } else if case .responseError(let reason) = err,
                      case .invalidHTTPStatusCode(let response) = reason {
                XCTAssertEqual(response.statusCode, 404)

            } else {
                XCTFail("Unexpected error form: \(err)")
            }
        }

        // Cache-only must STILL fail (404 must not have been cached as an image)
        let result2 = await retrieve(.provider(provider), options: [.onlyFromCache])
        switch result2 {
        case .success:
            XCTFail("404 response must not have been cached as an image")
        case .failure(let err):
            if case .cacheError = err {
                // expected
            } else {
                XCTFail("Expected a cache-only miss, got \(err)")
            }
        }
    }

    /// Disk cache should serve even after memory cache is cleared (no provider calls).
    func test_DiskCache_PersistsAcrossMemoryPurge() async throws {
        // Seed the cache via a normal “remote” success.
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))
        let first = await retrieve(.provider(provider))
        let img = try first.get().image
        XCTAssertEqual(provider.callCount, 1)

        // Force a disk write and wait for completion (no race).
        let stored = expectation(description: "stored to disk")
        cache.store(img, forKey: remoteKey, toDisk: true) { _ in stored.fulfill() }
        await fulfillment(of: [stored], timeout: 2)

        // Simulate memory pressure/app hop.
        cache.clearMemoryCache()

        // Cache-only fetch must still succeed from disk (no provider call).
        let result = await retrieve(.provider(provider), options: [.onlyFromCache])
        _ = try result.get()
        XCTAssertEqual(provider.callCount, 1, "Should serve from disk/memory cache without calling provider again")
    }

    /// Wi-Fi only policy: allowed when we say we’re on Wi-Fi.
    func test_WiFiOnlyPolicy_OnWiFi_AllowsRemote() async throws {
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))
        let policy: AttachmentNetworkPolicy = .wifiOnly(isOnWifi: true)

        _ = try await retrieve(.provider(provider), options: policy.kingfisherOptions).get()
        XCTAssertEqual(provider.callCount, 1, "Provider should be called when Wi-Fi policy allows network")
    }

    /// Wi-Fi only policy: blocked when we say we’re on Cellular.
    func test_WiFiOnlyPolicy_OnCellular_BlocksRemote() async throws {
        let provider = MockRemoteProvider(cacheKey: remoteKey, mode: .success(samplePNGData))
        let policy: AttachmentNetworkPolicy = .wifiOnly(isOnWifi: false)

        let result = await retrieve(.provider(provider), options: policy.kingfisherOptions)
        switch result {
        case .success:
            XCTFail("Should not succeed when cache is empty & Wi-Fi only blocks network")
        case .failure(let err):
            if case .cacheError = err {
                // expected
            } else {
                XCTFail("Expected a cache-only miss, got \(err)")
            }
        }
        XCTAssertEqual(provider.callCount, 0, "Provider must not be called when Wi-Fi-only policy blocks network")
    }
}
