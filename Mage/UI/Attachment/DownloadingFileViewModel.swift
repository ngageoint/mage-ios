//
//  DownloadingFileViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

class DownloadingFileViewModel: ObservableObject {
    @Published
    var error: String?
    
    @Published
    var fileUrl: URL?
    
    @Published
    var fileDate: Date = Date()
    
    @Published
    var receivedSize: Int64 = 0
    
    @Published
    var totalSize: Int64 = 0
    
    var url: URL
    var router: MageRouter
    
    init(url: URL, router: MageRouter) {
        self.url = url
        self.router = router
        
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory, options: [.createIntermediateDirectories, .removePreviousFile])

        MageSession.shared.session.download(
            url,
            method: .get,
            to: destination
        ).downloadProgress(closure: { (progress) in
                self.receivedSize = progress.completedUnitCount
                self.totalSize = progress.totalUnitCount
            }).response(completionHandler: { (response) in
                // TODO: if this was an attachment, set the local path on the entity
                // but this does not seem like the right place to do that
                if let fileUrl = response.fileURL {
                    self.router.path.append(FileRoute.showDownloadedFile(fileUrl: fileUrl, url: url))
                }
            })
    }
}
