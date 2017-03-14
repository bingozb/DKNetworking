//
//  DKNetworking.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworking.h"
#import "AFNetworking.h"

#define DKHTTPRequest(Method) \
    if (_cacheType == DKNetworkCacheTypeCacheNetwork) \
        callback([DKNetworkCache httpCacheForURL:URL parameters:parameters], nil); \
NSURLSessionTask *sessionTask = [_sessionManager Method:URL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) { \
        [[self allSessionTask] removeObject:task]; \
        if (_isOpenLog) \
            DKLog(@"%@",[responseObject dk_jsonString]); \
        if (callback) \
                callback(responseObject, nil); \
        [DKNetworkCache setHttpCache:responseObject URL:URL parameters:parameters]; \
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) { \
        [[self allSessionTask] removeObject:task]; \
        if (_isOpenLog) \
            DKLog(@"%@",error); \
        if (callback) \
            callback(nil, error); \
    }]; \
    [[self allSessionTask] addObject:sessionTask]; \
return sessionTask;

@implementation DKNetworking

static BOOL _isOpenLog;
static DKNetworkCacheType _cacheType;
static NSMutableArray<NSURLSessionTask *> *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

static NSString *const kDefaultDownloadDir = @"Download";
static CGFloat const kDefaultTimeoutInterval = 10.f;

+ (void)setupCacheType:(DKNetworkCacheType)cacheType
{
    _cacheType = cacheType;
}

#pragma mark - Network Status

+ (void)networkStatusWithBlock:(DKNetworkStatusBlock)networkStatusBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusUnknown);
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusNotReachable);
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusReachableViaWWAN);
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusReachableViaWiFi);
                    break;
            }
        }];
    });
}

+ (BOOL)isNetworking
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

#pragma mark - Log

+ (void)openLog
{
    _isOpenLog = YES;
}

+ (void)closeLog
{
    _isOpenLog = NO;
}

#pragma mark - Request Method

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKHttpRequestBlock)callback
{
    DKHTTPRequest(GET)
}

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKHttpRequestBlock)callback
{
    DKHTTPRequest(POST)
}

#pragma mark - Upload

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progressBlock:(DKHttpProgressBlock)progressBlock callback:(DKHttpRequestBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        if (error && callback) {
            callback(nil, error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",[responseObject dk_jsonString]);
        if (callback)
            callback(responseObject, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",error);
        if (callback)
            callback(nil, error);
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progressBlock:(DKHttpProgressBlock)progressBlock callback:(DKHttpRequestBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            NSString *timeStampImageName = [NSString stringWithFormat:@"%ld%ld.%@",(long)[[NSDate date] timeIntervalSince1970], i, imageType ?: @"jpg"];
            NSString *fileName = fileNames ? [NSString stringWithFormat:@"%@.%@", fileNames[i], imageType ?: @"jpg"] : timeStampImageName;
            NSString *mimeType = [NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"];
            [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:mimeType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",[responseObject dk_jsonString]);
        if (callback)
            callback(responseObject, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",error);
        if (callback)
            callback(nil, error);
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - Download

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progressBlock:(DKHttpProgressBlock)progressBlock callback:(void (^)(NSString *, NSError *))callback
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : kDefaultDownloadDir];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (error && callback) {
            callback(nil, error);
            return;
        }
        if (callback)
            callback(filePath.absoluteString, nil);
    }];
    
    [downloadTask resume];
    [[self allSessionTask] addObject:downloadTask];
    
    return downloadTask;
}

#pragma mark - Cancel Request

+ (void)cancelAllRequest
{
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL
{
    if (!URL) return;
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - AFHTTPSessionManager

#pragma mark Init

+ (void)load
{
    // 开始监测网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize
{
    // 所有HTTP请求共享一个AFHTTPSessionManager
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = kDefaultTimeoutInterval;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
}

#pragma mark Reset

+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    _sessionManager.requestSerializer = requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    _sessionManager.responseSerializer = responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

#pragma mark - Getters && Setters

/**
 存储所有请求task的数组
 */
+ (NSMutableArray *)allSessionTask
{
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

@end
