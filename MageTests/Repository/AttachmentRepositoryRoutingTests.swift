//
//  AttachmentRepositoryRoutingTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Kingfisher
@testable import MAGE

final class AttachmentRepositoryRoutingTests: XCTestCase {

    var repo: AttachmentRepository!
    var router: MageRouter!

    override func setUp() {
        super.setUp()
        CoreDataTestStack.setUp()
        repo = AttachmentRepositoryImpl()
        router = MageRouter()

        // Deterministic environment defaults
        AttachmentRepoEnv.fetchPolicy = { true }
        AttachmentRepoEnv.isCached    = { _ in false }
        AttachmentRepoEnv.preferStreamingVideo = { false }
        AttachmentRepoEnv.preferStreamingAudio = { false }
    }

    override func tearDown() {
        // Restore production behavior
        AttachmentRepoEnv.fetchPolicy = { DataConnectionUtilities.shouldFetchAttachments() }
        AttachmentRepoEnv.isCached    = { key in ImageCache.default.isCached(forKey: key) }
        AttachmentRepoEnv.preferStreamingVideo = { false }
        AttachmentRepoEnv.preferStreamingAudio = { false }
        CoreDataTestStack.tearDown()
        super.tearDown()
    }

    // MARK: - Image

    func test_image_local_routesToShowFileImage() throws {
        let local = try Tmp.writeTempFile(name: "local.jpg")
        let m = makeAttachmentModel(name: "local.jpg", contentType: "image/jpeg", localFile: local)

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showFileImage(let path) = r {
            XCTAssertEqual(path, local.path)
        } else { XCTFail("expected .showFileImage, got \(r)") }
    }

    func test_image_remote_isCached_routesToShowCachedImage() {
        let remote = URL(string: "https://example.com/pic.jpg")!
        let m = makeAttachmentModel(name: "pic.jpg", contentType: "image/jpeg", remote: remote)
        AttachmentRepoEnv.isCached = { $0 == remote.absoluteString }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showCachedImage(let key) = r {
            XCTAssertEqual(key, remote.absoluteString)
        } else { XCTFail("expected .showCachedImage, got \(r)") }
    }

    func test_image_remote_notCached_fetchAllowed_routesToCacheImage() {
        let remote = URL(string: "https://example.com/pic.jpg")!
        let m = makeAttachmentModel(name: "pic.jpg", contentType: "image/jpeg", remote: remote)
        AttachmentRepoEnv.isCached = { _ in false }
        AttachmentRepoEnv.fetchPolicy = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .cacheImage(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .cacheImage, got \(r)") }
    }

    func test_image_remote_notCached_fetchDisallowed_routesToAskToCache() {
        let remote = URL(string: "https://example.com/pic.jpg")!
        let m = makeAttachmentModel(name: "pic.jpg", contentType: "image/jpeg", remote: remote)
        AttachmentRepoEnv.isCached = { _ in false }
        AttachmentRepoEnv.fetchPolicy = { false }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .askToCache(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .askToCache, got \(r)") }
    }

    // MARK: - Video

    func test_video_local_routesToShowDownloadedFile() throws {
        let local = try Tmp.writeTempFile(name: "clip.mp4")
        let m = makeAttachmentModel(name: "clip.mp4", contentType: "video/mp4", localFile: local)

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showDownloadedFile(let fileUrl, let url) = r {
            XCTAssertEqual(fileUrl, local)
            XCTAssertEqual(url, local)
        } else { XCTFail("expected .showDownloadedFile, got \(r)") }
    }

    func test_video_remote_preferStreaming_routesToShowRemoteVideo() {
        let remote = URL(string: "https://example.com/clip.mp4")!
        let m = makeAttachmentModel(name: "clip.mp4", contentType: "video/mp4", remote: remote)
        AttachmentRepoEnv.preferStreamingVideo = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showRemoteVideo(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .showRemoteVideo, got \(r)") }
    }

    func test_video_remote_fetchAllowed_noStreaming_routesToDownloadFile() {
        let remote = URL(string: "https://example.com/clip.mp4")!
        let m = makeAttachmentModel(name: "clip.mp4", contentType: "video/mp4", remote: remote)
        AttachmentRepoEnv.preferStreamingVideo = { false }
        AttachmentRepoEnv.fetchPolicy = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .downloadFile(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .downloadFile, got \(r)") }
    }

    func test_video_remote_fetchDisallowed_noStreaming_routesToAskToDownload() {
        let remote = URL(string: "https://example.com/clip.mp4")!
        let m = makeAttachmentModel(name: "clip.mp4", contentType: "video/mp4", remote: remote)
        AttachmentRepoEnv.preferStreamingVideo = { false }
        AttachmentRepoEnv.fetchPolicy = { false }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .askToDownload(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .askToDownload, got \(r)") }
    }

    // MARK: - Audio

    func test_audio_local_routesToShowDownloadedFile() throws {
        let local = try Tmp.writeTempFile(name: "sound.m4a")
        let m = makeAttachmentModel(name: "sound.m4a", contentType: "audio/aac", localFile: local)

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showDownloadedFile(let fileUrl, let url) = r {
            XCTAssertEqual(fileUrl, local)
            XCTAssertEqual(url, local)
        } else { XCTFail("expected .showDownloadedFile, got \(r)") }
    }

    func test_audio_remote_preferStreaming_routesToShowRemoteAudio() {
        let remote = URL(string: "https://example.com/sound.m4a")!
        let m = makeAttachmentModel(name: "sound.m4a", contentType: "audio/aac", remote: remote)
        AttachmentRepoEnv.preferStreamingAudio = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showRemoteAudio(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .showRemoteAudio, got \(r)") }
    }

    func test_audio_remote_fetchAllowed_noStreaming_routesToDownloadFile() {
        let remote = URL(string: "https://example.com/sound.m4a")!
        let m = makeAttachmentModel(name: "sound.m4a", contentType: "audio/aac", remote: remote)
        AttachmentRepoEnv.preferStreamingAudio = { false }
        AttachmentRepoEnv.fetchPolicy = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .downloadFile(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .downloadFile, got \(r)") }
    }

    func test_audio_remote_fetchDisallowed_noStreaming_routesToAskToDownload() {
        let remote = URL(string: "https://example.com/sound.m4a")!
        let m = makeAttachmentModel(name: "sound.m4a", contentType: "audio/aac", remote: remote)
        AttachmentRepoEnv.preferStreamingAudio = { false }
        AttachmentRepoEnv.fetchPolicy = { false }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .askToDownload(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .askToDownload, got \(r)") }
    }

    // MARK: - Other

    func test_other_local_routesToShowDownloadedFile() throws {
        let local = try Tmp.writeTempFile(name: "doc.pdf")
        let m = makeAttachmentModel(name: "doc.pdf", contentType: "application/pdf", localFile: local)

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .showDownloadedFile(let fileUrl, let url) = r {
            XCTAssertEqual(fileUrl, local)
            XCTAssertEqual(url, local)
        } else { XCTFail("expected .showDownloadedFile, got \(r)") }
    }

    func test_other_remote_fetchAllowed_routesToDownloadFile() {
        let remote = URL(string: "https://example.com/doc.pdf")!
        let m = makeAttachmentModel(name: "doc.pdf", contentType: "application/pdf", remote: remote)
        AttachmentRepoEnv.fetchPolicy = { true }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .downloadFile(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .downloadFile, got \(r)") }
    }

    func test_other_remote_fetchDisallowed_routesToAskToDownload() {
        let remote = URL(string: "https://example.com/doc.pdf")!
        let m = makeAttachmentModel(name: "doc.pdf", contentType: "application/pdf", remote: remote)
        AttachmentRepoEnv.fetchPolicy = { false }

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 1)
        guard let r = router.path.first as? FileRoute else { return XCTFail("not FileRoute") }
        if case .askToDownload(let url) = r {
            XCTAssertEqual(url, remote)
        } else { XCTFail("expected .askToDownload, got \(r)") }
    }

    // MARK: - Edge

    func test_missingLocalAndRemote_addsNoRoute() {
        let m = makeAttachmentModel(name: "mystery", contentType: "image/jpeg", remote: nil, localFile: nil)

        repo.appendAttachmentViewRoute(router: router, attachment: m)

        XCTAssertEqual(router.path.count, 0, "No valid route should be appended when neither local nor remote is available")
    }
}
