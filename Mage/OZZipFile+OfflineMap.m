//
//  ZipFile+Expand.m
//  MAGE
//
//

#import "OZZipFile+OfflineMap.h"

@implementation OZZipFile (OfflineMap)

- (NSArray *) expandToPath:(NSString *) path  error:(NSError **) error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *caches = [[NSMutableArray alloc] init];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[^\\/]*/$" options:NSRegularExpressionCaseInsensitive error:error];
    if (*error) return caches;
    
    NSArray *infos = [self listFileInZipInfosWithError:nil];
    for (OZFileInZipInfo *info in infos) {
        [self locateFileInZip:info.name error:nil];

        if([[[info.name pathComponents] firstObject] caseInsensitiveCompare:@"__MACOSX"] != NSOrderedSame){
        
            BOOL isDirectory = NO;
            [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
            if(isDirectory && [regex numberOfMatchesInString:info.name options:0 range:NSMakeRange(0, [info.name length])] == 1) {
                [caches addObject:[[info.name pathComponents] firstObject]];
            };
            
            NSLog(@"name %@", info.name);
            
            if (![info.name hasSuffix:@"/"]) {
                NSString *filePath = [path stringByAppendingPathComponent:info.name];
                [fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:error];
                if (*error) return caches;
                
                [[NSData data] writeToFile:filePath options:0 error:nil];
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                OZZipReadStream *read = [self readCurrentFileInZipWithError:nil];
                NSMutableData *buffer = [NSMutableData dataWithLength:2048];
                do {
                    long bytesRead = [read readDataWithBuffer:buffer error:nil];
                    if (bytesRead <= 0) {
                        break;
                    }
                    
                    [buffer setLength:bytesRead];
                    
                    [handle writeData:buffer];
                } while(YES);
                
                [read finishedReadingWithError:nil];
                [handle closeFile];
            }
        }
    }
        
    return caches;
}

@end
