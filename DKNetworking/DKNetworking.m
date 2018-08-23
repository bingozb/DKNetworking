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
#import "DKNetworkLogManager.h"
#import "DKNetworkGlobalConfig.h"

@interface DKNetworking ()
@property (nonatomic, strong) DKNetworkRequest *request;
@end

@implementation DKNetworking

static DKNetworkSessionManager *_sessionManager;
static DKNetworkGlobalConfig *_globalConfig;

+ (instancetype)networkManager
{
    return [[self alloc] init];
}

+ (void)setupBaseURL:(NSString *)baseURL
{
    _sessionManager = [[DKNetworkSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    
    [self initSessionManager];
}

#pragma mark - Network Status

+ (void)networkStatusWithBlock:(void (^)(DKNetworkStatus))networkStatusBlock
{
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
    [[DKNetworkLogManager defaultManager] openLog];
}

+ (void)closeLog
{
    [[DKNetworkLogManager defaultManager] closeLog];
}

#pragma mark - Request Method

- (DKNetworking *(^)(NSString *))get
{
    return ^DKNetworking *(NSString *url){
        self.request.method = @"GET";
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))post
{
    return ^DKNetworking *(NSString *url){
        self.request.method = @"POST";
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))put
{
    return ^DKNetworking *(NSString *url){
        self.request.method = @"PUT";
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))patch
{
    return ^DKNetworking *(NSString *url){
        self.request.method = @"PATCH";
        self.request.urlStr = url;
        return self;
    };
}

- (DKNetworking *(^)(NSString *))delete
{
    return ^DKNetworking *(NSString *url){
        self.request.method = @"DELETE";
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
        self.request.header = header;
        return self;
    };
}

- (DKNetworking *(^)(DKNetworkCacheType))cacheType
{
    return ^DKNetworking *(DKNetworkCacheType cacheType){
        self.request.cacheType = cacheType;
        return self;
    };
}

- (DKNetworking *(^)(DKRequestSerializer requestSerializer))requestSerializer
{
    return ^DKNetworking *(DKRequestSerializer requestSerializer){
        self.request.requestSerializer = requestSerializer;
        _sessionManager.requestSerializer = requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
        return self;
    };
}

- (DKNetworking *(^)(DKResponseSerializer responseSerializer))responseSerializer
{
    return ^DKNetworking *(DKResponseSerializer responseSerializer){
        self.request.responseSerializer = responseSerializer;
        _sessionManager.responseSerializer = responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
        return self;
    };
}

- (DKNetworking *(^)(NSTimeInterval requestTimeoutInterval))requestTimeoutInterval
{
    return ^DKNetworking *(NSTimeInterval requestTimeoutInterval){
        self.request.requestTimeoutInterval = requestTimeoutInterval;
        _sessionManager.requestSerializer.timeoutInterval = requestTimeoutInterval;
        return self;
    };
}

- (RACSignal *)executeSignal
{
    RACSignal *resultSignal = [self rac_request:self.request];
    if (_globalConfig.flattenMapBlock)
        return [resultSignal flattenMap:_globalConfig.flattenMapBlock];

    return resultSignal;
}

#pragma mark - Global Config

- (DKNetworking *(^)(NSDictionary *))setupGlobalHeaders
{
    return ^DKNetworking *(NSDictionary *headers){
        [_globalConfig setupHeaders:headers];
        return self;
    };
}

- (DKNetworking *(^)(DKRequestSerializer))setupGlobalRequestSerializer
{
    return ^DKNetworking *(DKRequestSerializer requestSerializer){
        _globalConfig.requestSerializer = requestSerializer;
        return self;
    };
}

- (DKNetworking *(^)(DKResponseSerializer))setupGlobalResponseSerializer
{
    return ^DKNetworking *(DKResponseSerializer responseSerializer){
        _globalConfig.responseSerializer = responseSerializer;
        return self;
    };
}

- (DKNetworking *(^)(NSTimeInterval))setupGlobalRequestTimeoutInterval
{
    return ^DKNetworking *(NSTimeInterval requestTimeoutInterval){
        _globalConfig.requestTimeoutInterval = requestTimeoutInterval;
        return self;
    };
}

- (RACSignal *)rac_request:(DKNetworkRequest *)request
{
    NSAssert(request.urlStr.length, @"DKNetworking Error: URL can not be nil");
    
    NSString *URL = request.urlStr;
    NSDictionary *parameters = request.params;
    NSString *method = request.method;
    
    RACSignal *requestSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [_sessionManager requestWithMethod:method URLString:URL parameters:parameters completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
            
            if (response.rawData)
                [DKNetworkCache setCache:response.rawData URL:URL parameters:parameters];
            
            [[DKNetworkLogManager defaultManager] logRequest:request];
            [[DKNetworkLogManager defaultManager] logResponse:response];
            
            [subscriber sendNext:RACTuplePack(request,response)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
    
    if (request.cacheType == DKNetworkCacheTypeCacheNetwork) {
        RACSignal *cacheSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            DKNetworkResponse *cacheResponse = [DKNetworkResponse responseWithRawData:DKCache(URL, parameters) httpStatusCode:200 error:nil];
            [subscriber sendNext:RACTuplePack(request,cacheResponse)];
            [subscriber sendCompleted];
            return nil;
        }];
        return [cacheSignal merge:requestSignal];
    }
    
    return requestSignal;
}

#pragma mark - DKNetworkSessionManager

#pragma mark Init

+ (void)load
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize
{
    _sessionManager = [DKNetworkSessionManager manager];
    _globalConfig = [DKNetworkGlobalConfig defaultConfig];
    
    [self initSessionManager];
}

+ (void)initSessionManager
{
    _sessionManager.requestSerializer = _globalConfig.requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer = _globalConfig.responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
    _sessionManager.requestSerializer.timeoutInterval = _globalConfig.requestTimeoutInterval;
    
    if (_globalConfig.headers) {
        [_globalConfig.headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [_sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
}

+ (void)setupResponseSignalWithFlattenMapBlock:(DKNetworkFlattenMapBlock)flattenMapBlock
{
    _globalConfig.flattenMapBlock = flattenMapBlock;
}

+ (void)setupSessionManager:(void (^)(DKNetworkSessionManager *))sessionManagerBlock
{
    if (sessionManagerBlock) {
        sessionManagerBlock(_sessionManager);
    }
}

#pragma mark - Getters && Setters

- (DKNetworkRequest *)request
{
    if (!_request) {
        _request = [[DKNetworkRequest alloc] init];
        _request.header = _globalConfig.headers;
        _request.requestSerializer = _globalConfig.requestSerializer;
        _request.responseSerializer = _globalConfig.responseSerializer;
        _request.requestTimeoutInterval = _globalConfig.requestTimeoutInterval;
    }
    return _request;
}

@end
