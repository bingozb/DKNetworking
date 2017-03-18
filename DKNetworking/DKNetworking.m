//
//  DKNetworking.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworking.h"
#import "AFNetworking.h"
#import "DKNetworkRequest.h"

#define KResponse(rawData, error) [DKNetworkResponse responseWithRawData:rawData error:error]

#define KCallRequest(Method) \
if (_networkCacheType == DKNetworkCacheTypeCacheNetwork && callback) \
    callback([DKNetworkResponse responseWithRawData:DKNCache(URL, parameters) error:nil]); \
NSURLSessionTask *sessionTask = [_sessionManager Method:URL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) { \
    [[DKNetworking allSessionTask] removeObject:task]; \
    if (_isOpenLog) \
        DKLog(@"%@",[responseObject dk_jsonString]); \
    if (callback) \
        callback([DKNetworkResponse responseWithRawData:DKNCache(URL, parameters) error:nil]); \
    [DKNetworkCache setCache:responseObject URL:URL parameters:parameters]; \
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) { \
    [[DKNetworking allSessionTask] removeObject:task]; \
    if (_isOpenLog) \
        DKLog(@"%@",error); \
    if (callback) \
        callback([DKNetworkResponse responseWithRawData:nil error:error]); \
}]; \
[[DKNetworking allSessionTask] addObject:sessionTask]; \
return sessionTask;

@interface DKNetworking ()
@property (nonatomic, strong) DKNetworkRequest *request;
@end

@implementation DKNetworking

static BOOL _isOpenLog;
static DKNetworkCacheType _networkCacheType;
static DKNetworking *_networkManager;
static NSMutableArray<NSURLSessionTask *> *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

static NSString *const kDefaultDownloadDir = @"Download";
static CGFloat const kDefaultTimeoutInterval = 10.f;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _networkManager = [super allocWithZone:zone];
    });
    return _networkManager;
}

+ (instancetype)networkManager
{
    if (_networkManager == nil) {
        _networkManager = [[self alloc] init];
    }
    return _networkManager;
}

+ (void)setupCacheType:(DKNetworkCacheType)cacheType
{
    _networkCacheType = cacheType;
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

#pragma mark 链式调用

- (DKNetworking *(^)(NSString *))get
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKNetworkRequestMethodGET;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))post
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKNetworkRequestMethodPOST;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))put
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKNetworkRequestMethodPUT;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))delete
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKNetworkRequestMethodDELETE;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))patch
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKNetworkRequestMethodPATCH;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking * (^)(NSDictionary *))params
{
    return ^DKNetworking *(NSDictionary *params){
        self.request.params = params;
        return self;
    };
}

- (DKNetworking * (^)(NSDictionary *))header
{
    return ^DKNetworking *(NSDictionary *header){
        self.request.header = header;
        return self;
    };
}

- (DKNetworking * (^)(DKNetworkCacheType))cacheType
{
    return ^DKNetworking *(DKNetworkCacheType cacheType){
        self.request.cacheType = cacheType;
        return self;
    };
}

- (DKNetworking * (^)(DKRequestSerializer requestSerializer))requestSerializer
{
    return ^DKNetworking *(DKRequestSerializer requestSerializer){
        self.request.requestSerializer = requestSerializer;
        return self;
    };
}

- (void (^)(DKNetworkBlock))callback
{
    return ^void(DKNetworkBlock block){
        [self request:self.request callback:^(DKNetworkResponse *response) {
            self.request = nil;
            block(response);
        }];
    };
}

#pragma mark 常规调用

+ (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    switch (request.method) {
        case DKNetworkRequestMethodGET:
            return [self GET:request.urlStr parameters:request.params callback:callback];
            break;
        case DKNetworkRequestMethodPOST:
            return [self POST:request.urlStr parameters:request.params callback:callback];
            break;
        case DKNetworkRequestMethodPUT:
            return [self PUT:request.urlStr parameters:request.params callback:callback];
            break;
        case DKNetworkRequestMethodDELETE:
            return [self DELETE:request.urlStr parameters:request.params callback:callback];
            break;
        case DKNetworkRequestMethodPATCH:
            return [self PATCH:request.urlStr parameters:request.params callback:callback];
            break;
    }
    
    return nil;
}

- (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    return [DKNetworking request:request callback:callback];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    KCallRequest(GET)
}

- (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return [DKNetworking GET:URL parameters:parameters callback:callback];
}

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    KCallRequest(POST)
}

- (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return [DKNetworking POST:URL parameters:parameters callback:callback];
}

#pragma clang diagnostic pop

+ (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    KCallRequest(PUT)
}

- (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return [DKNetworking PUT:URL parameters:parameters callback:callback];
}

+ (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    KCallRequest(DELETE)
}

- (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return [DKNetworking DELETE:URL parameters:parameters callback:callback];
}

+ (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    KCallRequest(PATCH)
}

- (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return [DKNetworking PATCH:URL parameters:parameters callback:callback];
}

#pragma mark - Upload

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progressBlock:(DKNetworkProgressBlock)progressBlock callback:(DKNetworkBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        if (error && callback) {
            callback(KResponse(nil, error));
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
            callback([DKNetworkResponse responseWithRawData:responseObject error:nil]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",error);
        if (callback)
            callback(KResponse(nil, error));
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progressBlock:(DKNetworkProgressBlock)progressBlock callback:(DKNetworkBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            NSString *timeStampImageName = [NSString stringWithFormat:@"%f%ld.%@",[[NSDate date] timeIntervalSince1970], i, imageType ?: @"jpg"];
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
            callback([DKNetworkResponse responseWithRawData:responseObject error:nil]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (_isOpenLog)
            DKLog(@"%@",error);
        if (callback)
            callback(KResponse(nil, error));
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - Download

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(NSString *, NSError *))callback
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

- (DKNetworkRequest *)request
{
    if (!_request) {
        _request = [[DKNetworkRequest alloc] init];
    }
    return _request;
}

@end
