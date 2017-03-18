//
//  DKNetworkSessionManager.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkSessionManager.h"

@interface DKNetworkSessionManager () <DKNetWorkSessionManagerProtocol>

@end

@implementation DKNetworkSessionManager

- (NSURLSessionDataTask *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters completion:(DKNetworkTaskBlock)completion
{
    __block DKNetworkResponse *response;
    
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:method URLString:URLString parameters:parameters uploadProgress:nil downloadProgress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        response = [DKNetworkResponse responseWithRawData:responseObject error:nil];
        if (completion) {
            completion(task, response);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        response = [DKNetworkResponse responseWithRawData:nil error:error];
        if (completion) {
            completion(task, response);
        }
    }];
    
    [dataTask resume];
    
    return dataTask;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    }
    return self;
}

@end
