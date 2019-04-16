//
//  DKNetworkSessionManager.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkSessionManager.h"
#import "DKNetworkGlobalConfig.h"

@interface DKNetworkSessionManager () <DKNetWorkSessionManagerProtocol>

@end

@implementation DKNetworkSessionManager

- (instancetype)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        self.requestSerializer = [DKNetworkGlobalConfig defaultConfig].requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
        self.responseSerializer = [DKNetworkGlobalConfig defaultConfig].responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
    }
    return self;
}

- (void)setRequestSerializer:(AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer
{
    [super setRequestSerializer:requestSerializer];
    
    self.requestSerializer.timeoutInterval = [DKNetworkGlobalConfig defaultConfig].requestTimeoutInterval;
    if ([DKNetworkGlobalConfig defaultConfig].headers) {
        [[DKNetworkGlobalConfig defaultConfig].headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [self.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    // fix `DELETE method not post parameters in body, but in URI.`
    self.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer<AFURLResponseSerialization> *)responseSerializer
{
    [super setResponseSerializer:responseSerializer];
    
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
}

- (NSURLSessionDataTask *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters completion:(DKNetworkTaskBlock)completion
{
    __block DKNetworkResponse *response;
    
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:method URLString:URLString parameters:parameters uploadProgress:nil downloadProgress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        response = [DKNetworkResponse responseWithRawData:responseObject httpStatusCode:((NSHTTPURLResponse *)task.response).statusCode error:nil];
        if (completion) {
            completion(task, response);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSInteger httpStatusCode = ((NSHTTPURLResponse *)task.response).statusCode;
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *rawData = errorData ? [NSJSONSerialization JSONObjectWithData:errorData options:NSJSONReadingAllowFragments error:nil] : nil;
        response = [DKNetworkResponse responseWithRawData:rawData httpStatusCode:httpStatusCode error:error];
        if (completion) {
            completion(task, response);
        }
    }];
    
    [dataTask resume];
    
    return dataTask;
}

@end
