//
//  Form.m
//  mage-ios-sdk
//
//

@import AFNetworking;

#import "Form.h"
#import "MageSessionManager.h"
#import "ObservationFetchService.h"
#import "MageServer.h"
#import "MAGE-Swift.h"
#import <SSZipArchive/SSZipArchive.h>

NSString * const MAGEFormFetched = @"mil.nga.giat.mage.form.fetched";

@implementation Form

+ (NSURLSessionDownloadTask *) operationToPullFormForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/form/icons.zip", [MageServer baseURL], @"api/events", eventId];
    
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"/events/icons-%@.zip", eventId]];
    
    NSString *folderToUnzipTo = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@", eventId]];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:stringPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if(!error){
            NSLog(@"event form icon request complete");
            
            NSString * fileString = [filePath path];
            
            NSError *error = nil;
            [SSZipArchive unzipFileAtPath:fileString toDestination:folderToUnzipTo];
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
