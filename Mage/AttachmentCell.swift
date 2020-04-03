//
//  AttachmentCell.m
//  Mage
//
//
import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView?;
    
    override func prepareForReuse() {
        // this isn't quite right, i think this should go wherever this collection is initiated
        /**
         func collectionView(
         _ collectionView: UICollectionView,
         didEndDisplaying cell: UICollectionViewCell,
         forItemAt indexPath: IndexPath)
         {
         // This will cancel the unfinished downloading task when the cell disappearing.
         cell.imageView.kf.cancelDownloadTask()
         }
         */
        self.imageView?.kf.cancelDownloadTask();
        for view in (self.imageView)!.subviews{
            view.removeFromSuperview()
        }
//        self.imageView.image = [UIImage imageNamed:@"download_thumbnail"];
    }

    func getAttachmentUrl(size: Int, attachment: Attachment) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", attachment.url!, size))!;
        }
    }
    
    @objc public func setImage(attachment: Attachment, formatName:NSString) {
        self.imageView?.kf.indicatorType = .activity;
        let imageSize: Int = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
        if (attachment.contentType?.hasPrefix("image") ?? false) {
            let url = self.getAttachmentUrl(size: imageSize, attachment: attachment);
            let resource = ImageResource(downloadURL: url, cacheKey: String(format: "%@_thumbnail", attachment.url!))
            self.imageView?.kf.setImage(with: resource, placeholder: UIImage.init(named: "download_thumbnail"), options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .transition(.fade(0.3)),
                .scaleFactor(UIScreen.main.scale),
                .processor(DownsamplingImageProcessor(size: (self.imageView?.frame.size)!)),
                .cacheOriginalImage,
                .onlyFromCache
            ]){ result in
                switch result {
                case .success(let value):
                    // handle the case where if the downloaded image is the actual full size one (image thumbnailing is off) we should store the image in the cache
                    // with the base url as the key
                    print("value", value);
//                    let image: UIImage = value.image;
//                    ImageCache.default.store(image, forKey: attachment.url!);
                    print("Image size now", max(self.imageView?.frame.size.height ?? 0, self.imageView?.frame.size.width ?? 0) * UIScreen.main.scale);
                case .failure(_):
                    // this can happen if we searched for the image in the cache and it wasn't there, if .onlyFromCache is on
                    print("Error Image size now", max(self.imageView?.frame.size.height ?? 0, self.imageView?.frame.size.width ?? 0) * UIScreen.main.scale);
                }
            }
        } else if (attachment.contentType?.hasPrefix("video") ?? false) {
            let url = self.getAttachmentUrl(size: imageSize, attachment: attachment);
            let provider: VideoImageProvider = VideoImageProvider(url: url);
            self.imageView?.kf.setImage(with: provider, placeholder: UIImage.init(named: "download_thumbnail"), options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .transition(.fade(0.2)),
                .scaleFactor(UIScreen.main.scale),
                .processor(DownsamplingImageProcessor(size: (self.imageView?.frame.size)!)),
                .cacheOriginalImage
            ])
            { result in
                switch result {
                case .success(_):
                    let overlay: UIImageView = UIImageView(image: UIImage.init(named: "play_overlay"));
                    self.imageView?.addSubview(overlay);
//                    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, myImageView.frame.size.width, myImageView.frame.size.height / 2)];
//                    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
//                    [myImageView addSubview:overlay];
                case .failure(let error):
                    print(error);
                    let overlay: UIImageView = UIImageView(image: UIImage.init(named: "error"));
                    self.imageView?.addSubview(overlay);
                }
            };
            
//            self.imageView?.image = UIImage.init(named: "play_overlay");
        } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
            self.imageView?.image = UIImage.init(named: "audio_thumbnail");
        } else {
            self.imageView?.image = UIImage.init(named: "paperclip_thumbnail");
        }
    
    
    //    __weak typeof(self) weakSelf = self;
    //    BOOL imageExists = [[FICImageCache sharedImageCache] retrieveImageForEntity:attachment withFormatName:formatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
    //        // This completion block may be called much later, check to make sure this cell hasn't been reused for a different attachment before displaying the image that has loaded.
    //        if (attachment == [self attachment] && image) {
    //            weakSelf.imageView.image = image;
    //            weakSelf.imageView.layer.cornerRadius = 5;
    //            weakSelf.imageView.clipsToBounds = YES;
    //        }
    //    }];
    //
    //    if (imageExists == NO) {
    //        self.imageView.image = [UIImage imageNamed:@"download_thumbnail"];
    //    }
    }
}
