//
//  Form.m
//  mage-ios-sdk
//
//

#import "Form.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "zlib.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "ZipException.h"
#import "FileInZipInfo.h"
#import "ObservationFetchService.h"
#import "MageServer.h"
#import "Server+helper.h"

@implementation Form

+ (NSOperation *) operationToPullFormForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/form/icons.zip", [MageServer baseURL], @"api/events", eventId];
    
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"/events/icons-%@.zip", eventId]];
    
    NSString *folderToUnzipTo = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@", eventId]];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"event form icon request complete");
        
        NSError *error = nil;
    
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:stringPath mode:ZipFileModeUnzip];
        int totalNumberOfFiles = (int)[unzipFile numFilesInZip];
        [unzipFile goToFirstFileInZip];
        for (int i = 0; i < totalNumberOfFiles; i++) {
            FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];
            NSString *name = info.name;
            if (![name hasSuffix:@"/"]) {
                NSString *filePath = [folderToUnzipTo stringByAppendingPathComponent:name];
                NSString *basePath = [filePath stringByDeletingLastPathComponent];
                if (![[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error]) {
                    [unzipFile close];
                    
                    //return NO;
                }
                
                [[NSData data] writeToFile:filePath options:0 error:nil];
                
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                ZipReadStream *read = [unzipFile readCurrentFileInZip];
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
            
            [unzipFile goToNextFileInZip];
        }
        
        [unzipFile close];
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:stringPath]) {
            BOOL successfulRemoval = [[NSFileManager defaultManager] removeItemAtPath:stringPath error:&error];
            if (!successfulRemoval) {
                NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
        if (success) {
            success();
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:stringPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:[stringPath stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:&error];
    
    [[NSFileManager defaultManager] createFileAtPath:stringPath contents:nil attributes:nil];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:stringPath append:NO];
    return operation;
    
}

@end
