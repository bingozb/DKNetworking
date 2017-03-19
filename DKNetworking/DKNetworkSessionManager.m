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

static NSString *const kDefaultDownloadDir = @"DKNetworkDownload";

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

- (NSURLSessionDataTask *)uploadWithURLString:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<DKMultipartFormData>))block progress:(void (^)(NSProgress *))uploadProgress completion:(DKNetworkTaskBlock)completion
{
    __block DKNetworkResponse *response;
    
    return [self POST:URLString parameters:parameters constructingBodyWithBlock:block progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        response = [DKNetworkResponse responseWithRawData:responseObject error:nil];
        if (completion) {
            completion(task, response);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        response = [DKNetworkResponse responseWithRawData:nil error:error];
        if (completion) {
            completion(task, response);
        }
    }];
}

- (NSURLSessionDownloadTask *)downloadWithURLString:(NSString *)URLString fileDir:(NSString *)fileDir progress:(void (^)(NSProgress *))downloadProgressBlock completion:(void (^)(NSString *, NSError *))completion
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // 获取本机保存目录 = 沙盒地址 + 下载目录(暂未提供自定义默认保存文件夹名)
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : kDefaultDownloadDir];
        // 如果文件夹不存在则先创建
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        // 文件保存全路径 = 本机保存地址 + NSURLResponse对象的建议文件名(其实就是原文件名)
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (completion) {
            if (error) {
                completion(nil, error);
            } else {
                completion(filePath.absoluteString, nil);
            }
        }
    }];
    
    [downloadTask resume];
    
    return downloadTask;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    }
    return self;
}

@end
