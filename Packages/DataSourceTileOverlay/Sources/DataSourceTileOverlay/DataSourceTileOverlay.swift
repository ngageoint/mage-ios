import MapKit
import Kingfisher

public protocol DataSourceOverlay {
    var key: String? { get set }
}

public class DataSourceTileOverlay: MKTileOverlay, DataSourceOverlay {
    public var key: String?
    let tileRepository: TileRepository

    public init(tileRepository: TileRepository, key: String) {
        self.tileRepository = tileRepository
        self.key = key
        super.init(urlTemplate: nil)
    }

    public override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let options: KingfisherOptionsInfo? =
        (tileRepository.cacheSourceKey != nil && tileRepository.imageCache != nil) ?
        [.targetCache(tileRepository.imageCache!)] : [.forceRefresh]

        KingfisherManager.shared.retrieveImage(
            with: .provider(
                DataSourceTileProvider(
                    tileRepository: tileRepository,
                    path: path
                )
            ),
            options: options
        ) { imageResult in
            switch imageResult {
            case .success(let value):
                result(value.image.pngData(), nil)

            case .failure:
                break
            }
        }
    }
}
