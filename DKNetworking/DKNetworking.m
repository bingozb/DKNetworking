//
//  DKNetworking.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworking.h"
#import "AFNetworking.h"

#define KRequest(URL, Method, Params) [DKNetworkRequest requestWithUrlStr:URL method:Method params:Params]
#define KResponse(rawData, error) [DKNetworkResponse responseWithRawData:rawData error:error]

#define KNetworkSessionTask(Method) [[DKNetworking networkManager] Method:URL parameters:parameters callback:callback]
#define KNetworkSessionTaskInstance(Method) [self request:KRequest(URL, Method, parameters) callback:callback]

#define KCallRequest(Method) \
if (networkCacheType == DKNetworkCacheTypeCacheNetwork && callback) \
    callback(request, [DKNetworkResponse responseWithRawData:DKNCache(URL, parameters) error:nil]); \
NSURLSessionTask *sessionTask = [sessionManager Method:URL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) { \
    [[DKNetworking allSessionTask] removeObject:task]; \
    if (isOpenLog) \
        DKLog(@"%@",[responseObject dk_jsonString]); \
    if (callback) \
        callback(request, [DKNetworkResponse responseWithRawData:DKNCache(URL, parameters) error:nil]); \
    [DKNetworkCache setCache:responseObject URL:URL parameters:parameters]; \
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) { \
    [[DKNetworking allSessionTask] removeObject:task]; \
    if (isOpenLog) \
        DKLog(@"%@",error); \
    if (callback) \
        callback(request, [DKNetworkResponse responseWithRawData:nil error:error]); \
}]; \
[[DKNetworking allSessionTask] addObject:sessionTask]; \
return sessionTask;

@interface DKNetworking ()
@property (nonatomic, strong) DKNetworkRequest *request;
@end

@implementation DKNetworking

static BOOL isOpenLog;
static DKNetworkCacheType networkCacheType;
static DKNetworking *networkManager;
static NSMutableArray<NSURLSessionTask *> *allSessionTask;
static AFHTTPSessionManager *sessionManager;

static NSString *const kDefaultDownloadDir = @"Download";
static CGFloat const kDefaultTimeoutInterval = 10.f;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkManager = [super allocWithZone:zone];
    });
    return networkManager;
}

+ (instancetype)networkManager
{
    if (!networkManager) {
        networkManager = [[self alloc] init];
    }
    return networkManager;
}

+ (void)setupCacheType:(DKNetworkCacheType)cacheType
{
    networkCacheType = cacheType;
    
    [[DKNetworking networkManager] setupCacheType:cacheType];
}

- (void)setupCacheType:(DKNetworkCacheType)cacheType
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
    isOpenLog = YES;
}

+ (void)closeLog
{
    isOpenLog = NO;
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

- (DKNetworking *(^)(NSDictionary *))params
{
    return ^DKNetworking *(NSDictionary *params){
        self.request.params = params;
        return self;
    };
}

- (DKNetworking *(^)(NSDictionary *))header
{
    return ^DKNetworking *(NSDictionary *header){
        [self setNetworkHeader:header];
        return self;
    };
}

- (DKNetworking *(^)(DKNetworkCacheType))cacheType
{
    return ^DKNetworking *(DKNetworkCacheType cacheType){
        [self setupCacheType:cacheType];
        return self;
    };
}

- (DKNetworking *(^)(DKRequestSerializer requestSerializer))requestSerializer
{
    return ^DKNetworking *(DKRequestSerializer requestSerializer){
        [self setRequestSerializer:requestSerializer];
        return self;
    };
}

- (DKNetworking *(^)(DKResponseSerializer responseSerializer))responseSerializer
{
    return ^DKNetworking *(DKResponseSerializer responseSerializer){
        [self setResponseSerializer:responseSerializer];
        return self;
    };
}

- (DKNetworking *(^)(DKRequestTimeoutInterval requestTimeoutInterval))requestTimeoutInterval
{
    return ^DKNetworking *(DKRequestTimeoutInterval requestTimeoutInterval){
        [self setRequestTimeoutInterval:requestTimeoutInterval];
        return self;
    };
}

- (void (^)(DKNetworkBlock))callback
{
    return ^void(DKNetworkBlock block){
        [self request:self.request callback:^(DKNetworkRequest *request, DKNetworkResponse *response) {
            block(request, response);
            self.request = nil;
        }];
    };
}

#pragma mark 常规调用

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    NSAssert(request.urlStr.length, @"DKNetworking Error: URL can not be nil");
    
    // 请求头
    request.header = [DKNetworking networkManager].networkHeader;
    // 缓存方式
    request.cacheType = [DKNetworking networkManager].networkCacheType;
    // 请求格式
    request.requestSerializer = [DKNetworking networkManager].networkRequestSerializer;
    // 超时时间
    request.requestTimeoutInterval = [DKNetworking networkManager].networkRequestTimeoutInterval;
    
    NSString *URL = request.urlStr;
    NSDictionary *parameters = request.params;
    switch (request.method) {
        case DKNetworkRequestMethodGET:{
            KCallRequest(GET)
            break;
        }
        case DKNetworkRequestMethodPOST:{
            KCallRequest(POST)
            break;
        }
        case DKNetworkRequestMethodPUT:{
            KCallRequest(PUT)
            break;
        }
        case DKNetworkRequestMethodDELETE:{
            KCallRequest(DELETE)
            break;
        }
        case DKNetworkRequestMethodPATCH:{
            KCallRequest(PATCH)
            break;
        }
    }
}

- (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    return [DKNetworking request:request callback:callback];
}

#pragma clang diagnostic pop

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(GET);
}

- (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKNetworkRequestMethodGET);
}

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(POST);
}

- (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKNetworkRequestMethodPOST);
}

+ (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(PUT);
}

- (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKNetworkRequestMethodPUT);
}

+ (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(DELETE);
}

- (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKNetworkRequestMethodDELETE);
}

+ (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(PATCH);
}

- (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKNetworkRequestMethodPATCH);
}

#pragma mark - Upload

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(DKNetworkResponse *))callback
{
    NSURLSessionTask *sessionTask = [sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
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
        if (isOpenLog)
            DKLog(@"%@",[responseObject dk_jsonString]);
        if (callback)
            callback([DKNetworkResponse responseWithRawData:responseObject error:nil]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (isOpenLog)
            DKLog(@"%@",error);
        if (callback)
            callback(KResponse(nil, error));
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(DKNetworkResponse *))callback
{
    NSURLSessionTask *sessionTask = [sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
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
        if (isOpenLog)
            DKLog(@"%@",[responseObject dk_jsonString]);
        if (callback)
            callback([DKNetworkResponse responseWithRawData:responseObject error:nil]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        if (isOpenLog)
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
    NSURLSessionDownloadTask *downloadTask = [sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
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
    // 所有请求共享一个SessionManager
    sessionManager = [AFHTTPSessionManager manager];
    sessionManager.requestSerializer.timeoutInterval = kDefaultTimeoutInterval;
    sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
}

#pragma mark Reset

+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    [[DKNetworking networkManager] setRequestSerializer:requestSerializer];
}

- (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    sessionManager.requestSerializer = requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    
    _networkRequestSerializer = requestSerializer;
}

+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    [[DKNetworking networkManager] setResponseSerializer:responseSerializer];
}

- (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    sessionManager.responseSerializer = responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
    
    _networkResponseSerializer = responseSerializer;
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    [[DKNetworking networkManager] setRequestTimeoutInterval:time];
}

- (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    sessionManager.requestSerializer.timeoutInterval = time;
    
    _networkRequestTimeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [[DKNetworking networkManager] setValue:value forHTTPHeaderField:field];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
    
    if (!_networkHeader) {
        _networkHeader = [NSDictionary dictionaryWithObject:value forKey:field];
    } else {
        NSMutableDictionary *headerTemp = [NSMutableDictionary dictionaryWithDictionary:_networkHeader];
        headerTemp[field] = value;
        _networkHeader = [headerTemp copy];
    }
}

- (void)setNetworkHeader:(NSDictionary *)networkHeader
{
    if (networkHeader) {
        [networkHeader enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [self setValue:key forHTTPHeaderField:obj];
        }];
    }
}

#pragma mark - Getters && Setters

/**
 存储所有请求task的数组
 */
+ (NSMutableArray *)allSessionTask
{
    if (!allSessionTask) {
        allSessionTask = [[NSMutableArray alloc] init];
    }
    return allSessionTask;
}

- (DKNetworkRequest *)request
{
    if (!_request) {
        _request = [[DKNetworkRequest alloc] init];
    }
    return _request;
}

@end
