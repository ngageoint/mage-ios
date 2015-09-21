//
//  ZipFile+Expand.m
//  MAGE
//
//

#import "ZipFile+OfflineMap.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"

@implementation ZipFile (OfflineMap)

- (NSArray *) expandToPath:(NSString *) path  error:(NSError **) error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUInteger totalNumberOfFiles = [self numFilesInZip];
    NSMutableArray *caches = [[NSMutableArray alloc] init];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[^\\/]*/$" options:NSRegularExpressionCaseInsensitive error:error];
    if (*error) return caches;
    
    for (int i = 0; i < totalNumberOfFiles; i++) {
        FileInZipInfo *info = [self getCurrentFileInZipInfo];

        
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
            ZipReadStream *read = [self readCurrentFileInZip];
            NSUInteger count;
            NSMutableData *data = [NSMutableData dataWithLength:2048];
            while ((count = [read readDataWithBuffer:data])) {
                data.length = count;
                [handle writeData:data];
                data.length = 2048;
            }
            [read finishedReading];
            [handle closeFile];
        }
        
        [self goToNextFileInZip];
    }
        
    return caches;
}

@end
