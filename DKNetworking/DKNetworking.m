//
//  DKNetworking.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworking.h"
#import "AFNetworking.h"
#import "DKNetworkSessionManager.h"

#define KNetworkSessionTask(Method) [DKNetworkManager Method:URL parameters:parameters callback:callback]
#define KNetworkSessionTaskInstance(Method) [self request:[DKNetworkRequest requestWithUrlStr:URL method:Method params:parameters] callback:callback]

@interface DKNetworking ()
@property (nonatomic, strong) DKNetworkRequest *request;
@property (nonatomic, strong) NSArray<NSString *> *methods;
#ifdef RAC
@property (nonatomic, copy) DKNetworkFlattenMapBlock flattenMapBlock;
#endif
@end

@implementation DKNetworking

static BOOL isOpenLog;
static DKNetworking *networkManager;
static DKNetworkCacheType networkCacheType;
static DKNetworkSessionManager *sessionManager;
static NSMutableArray<NSURLSessionTask *> *allSessionTask;

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
    
    [DKNetworkManager setupCacheType:cacheType];
}

+ (void)setupBaseURL:(NSString *)baseURL
{
    sessionManager = [[DKNetworkSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    
    [self initSessionManager];
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
        self.request.method = DKRequestMethodGET;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))post
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKRequestMethodPOST;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))put
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKRequestMethodPUT;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))delete
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKRequestMethodDELETE;
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))patch
{
    return ^DKNetworking *(NSString *url){
        self.request.method = DKRequestMethodPATCH;
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
        [DKNetworking setNetworkHeader:header];
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

#ifdef RAC
- (RACSignal *)executeSignal
{
    RACSignal *resultSignal = [self rac_request:self.request];
    if (self.flattenMapBlock)
        return [resultSignal flattenMap:self.flattenMapBlock];

    return resultSignal;
}

- (RACSignal *)rac_request:(DKNetworkRequest *)request
{
    NSAssert(request.urlStr.length, @"DKNetworking Error: URL can not be nil");
    
    request.header = DKNetworkManager.networkHeader;
    request.cacheType = DKNetworkManager.networkCacheType;
    request.requestSerializer = DKNetworkManager.networkRequestSerializer;
    request.requestTimeoutInterval = DKNetworkManager.networkRequestTimeoutInterval;
    NSString *URL = request.urlStr;
    NSDictionary *parameters = request.params;
    NSString *method = self.methods[request.method];
    
    RACSignal *requestSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLSessionTask *sessionTask = [sessionManager requestWithMethod:method URLString:URL parameters:parameters completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
            [[DKNetworking allSessionTask] removeObject:task];
            if (response.rawData)
                [DKNetworkCache setCache:response.rawData URL:URL parameters:parameters];
            if (isOpenLog)
                DKLog(@"%@",response.error ? response.error : [response.rawData dk_jsonString]);
            if (!response.error) {
                [subscriber sendNext:RACTuplePack(request,response)];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:response.error];
            }
        }];
        [[DKNetworking allSessionTask] addObject:sessionTask];
        return nil;
    }];
    
    if (networkCacheType == DKNetworkCacheTypeCacheNetwork) {
        RACSignal *cacheSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            DKNetworkResponse *cacheResponse = [DKNetworkResponse responseWithRawData:DKCache(URL, parameters) error:nil];
            [subscriber sendNext:RACTuplePack(request,cacheResponse)];
            [subscriber sendCompleted];
            return nil;
        }];
        return [cacheSignal merge:requestSignal];
    }
    
    return requestSignal;
}
#endif

#pragma mark 常规调用

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    return [DKNetworkManager request:request callback:callback];
}

- (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback
{
    NSAssert(request.urlStr.length, @"DKNetworking Error: URL can not be nil");
    
    request.header = DKNetworkManager.networkHeader;
    request.cacheType = DKNetworkManager.networkCacheType;
    request.requestSerializer = DKNetworkManager.networkRequestSerializer;
    request.requestTimeoutInterval = DKNetworkManager.networkRequestTimeoutInterval;
    
    NSString *URL = request.urlStr;
    NSDictionary *parameters = request.params;
    NSString *method = self.methods[request.method];
    
    if (networkCacheType == DKNetworkCacheTypeCacheNetwork && callback)
        callback(request, [DKNetworkResponse responseWithRawData:DKCache(URL, parameters) error:nil]);
    
    NSURLSessionTask *sessionTask = [sessionManager requestWithMethod:method URLString:URL parameters:parameters completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
        [[DKNetworking allSessionTask] removeObject:task];
        if (response.rawData)
            [DKNetworkCache setCache:response.rawData URL:URL parameters:parameters];
        if (isOpenLog)
            DKLog(@"%@",response.error ? response.error : [response.rawData dk_jsonString]);
        if (callback)
            callback(request,response);
    }];
    
    [[DKNetworking allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma clang diagnostic pop

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(GET);
}

- (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKRequestMethodGET);
}

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(POST);
}

- (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKRequestMethodPOST);
}

+ (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(PUT);
}

- (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKRequestMethodPUT);
}

+ (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(DELETE);
}

- (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKRequestMethodDELETE);
}

+ (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTask(PATCH);
}

- (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback
{
    return KNetworkSessionTaskInstance(DKRequestMethodPATCH);
}

#pragma mark - Upload

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(DKNetworkResponse *))callback
{
    NSURLSessionTask *sessionTask = [sessionManager uploadWithURLString:URL parameters:parameters constructingBodyWithBlock:^(id<DKMultipartFormData> formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        if (error && callback) {
            callback([DKNetworkResponse responseWithRawData:nil error:error]);
        }
    } progress:^(NSProgress *uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
        [[self allSessionTask] removeObject:task];
        if (isOpenLog)
            DKLog(@"%@",response.error ? response.error : [response.rawData dk_jsonString]);
        if (callback)
            callback(response);
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(DKNetworkResponse *))callback
{
    NSURLSessionTask *sessionTask = [sessionManager uploadWithURLString:URL parameters:parameters constructingBodyWithBlock:^(id<DKMultipartFormData> formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            // 压缩图片
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 图片名
            NSString *fileName = fileNames ? [NSString stringWithFormat:@"%@.%@", fileNames[i], imageType ?: @"jpg"] : [NSString stringWithFormat:@"%f%ld.%@",[[NSDate date] timeIntervalSince1970], (unsigned long)i, imageType ?: @"jpg"];
            // MIME类型
            NSString *mimeType = [NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"];
            // 添加表单数据
            [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:mimeType];
        }
    } progress:^(NSProgress *uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
        [[self allSessionTask] removeObject:task];
        if (isOpenLog)
            DKLog(@"%@",response.error ? response.error : [response.rawData dk_jsonString]);
        if (callback)
            callback(response);
    }];
    
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - Download

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progressBlock:(DKNetworkProgressBlock)progressBlock callback:(void (^)(NSString *, NSError *))callback
{
    NSURLSessionDownloadTask *downloadTask = [sessionManager downloadWithURLString:URL fileDir:fileDir progress:^(NSProgress *downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(downloadProgress);
        });
    } completion:^(NSString *filePath, NSError *error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (isOpenLog)
            DKLog(@"%@",error ? error : filePath);
        if (callback)
            callback(filePath, error);
    }];
    
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

#pragma mark - DKNetworkSessionManager

#pragma mark Init

+ (void)load
{
    // 开始监测网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize
{
    // 所有请求共用一个SessionManager
    sessionManager = [DKNetworkSessionManager manager];
    
    [self initSessionManager];
}

+ (void)initSessionManager
{
    sessionManager.requestSerializer = DKNetworkManager.networkRequestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = DKNetworkManager.networkResponseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
    sessionManager.requestSerializer.timeoutInterval = DKNetworkManager.networkRequestTimeoutInterval ?: kDefaultTimeoutInterval;
    
    if (DKNetworkManager.networkHeader)
        [DKNetworkManager.networkHeader enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
}

#pragma mark - Result Config
#ifdef RAC
+ (void)setupResponseSignalWithFlattenMapBlock:(DKNetworkFlattenMapBlock)flattenMapBlock
{
    DKNetworkManager.flattenMapBlock = flattenMapBlock;
}
#endif

#pragma mark Reset

+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    [DKNetworkManager setRequestSerializer:requestSerializer];
}

- (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    sessionManager.requestSerializer = requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    
    _networkRequestSerializer = requestSerializer;
}

+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    [DKNetworkManager setResponseSerializer:responseSerializer];
}

- (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    sessionManager.responseSerializer = responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
    
    _networkResponseSerializer = responseSerializer;
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    [DKNetworkManager setRequestTimeoutInterval:time];
}

- (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    sessionManager.requestSerializer.timeoutInterval = time;
    
    _networkRequestTimeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [DKNetworkManager setValue:value forHTTPHeaderField:field];
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

+ (void)setNetworkHeader:(NSDictionary *)networkHeader
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

/**
 链式调用时候保存每一步的request配置信息

 @return 链式调用的请求对象
 */
- (DKNetworkRequest *)request
{
    if (!_request) {
        _request = [[DKNetworkRequest alloc] init];
    }
    return _request;
}

- (NSArray<NSString *> *)methods
{
    if (!_methods) {
        _methods = @[@"GET", @"POST", @"PUT", @"DELETE", @"PATCH"];
    }
    return _methods;
}

@end
