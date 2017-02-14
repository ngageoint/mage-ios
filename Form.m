//
//  Form.m
//  mage-ios-sdk
//
//

#import "Form.h"
#import <AFNetworking.h>
#import "MageSessionManager.h"
#import "zlib.h"
#import "Objective-Zip+NSError.h"
#import "ObservationFetchService.h"
#import "MageServer.h"
#import "Server.h"

@implementation Form

+ (NSURLSessionDownloadTask *) operationToPullFormForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/form/icons.zip", [MageServer baseURL], @"api/events", eventId];
    
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"/events/icons-%@.zip", eventId]];
    
    NSString *folderToUnzipTo = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@", eventId]];
    
    MageSessionManager *manager = [MageSessionManager manager];
    
    NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:stringPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if(!error){
            NSLog(@"event form icon request complete");
            
            NSString * fileString = [filePath path];
            
            NSError *error = nil;
            OZZipFile *unzipFile = [[OZZipFile alloc] initWithFileName:fileString mode:OZZipFileModeUnzip error:&error];
            
            NSArray *infos = [unzipFile listFileInZipInfosWithError:&error];
            for (OZFileInZipInfo *info in infos) {
                [unzipFile locateFileInZip:info.name error:&error];
                NSString *name = info.name;
                if (![name hasSuffix:@"/"]) {
                    NSString *filePath = [folderToUnzipTo stringByAppendingPathComponent:name];
                    NSString *basePath = [filePath stringByDeletingLastPathComponent];
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error]) {
                        [unzipFile closeWithError:nil];
                    }
                    
                    [[NSData data] writeToFile:filePath options:0 error:nil];
                    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                    OZZipReadStream *read = [unzipFile readCurrentFileInZipWithError:&error];
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
            
            [unzipFile closeWithError:nil];
            if ([[NSFileManager defaultManager] isDeletableFileAtPath:fileString]) {
                BOOL successfulRemoval = [[NSFileManager defaultManager] removeItemAtPath:fileString error:&error];
                if (!successfulRemoval) {
                    NSLog(@"Error removing file at path: %@", error.localizedDescription);
                }
            }
            if (success) {
                success();
            }
        }else{
            NSLog(@"Error: %@", error);
            if (failure) {
                failure(error);
            }
        }
    }];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:stringPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:[stringPath stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:&error];
    
    return task;
    
}

@end
