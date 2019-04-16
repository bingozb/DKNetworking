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
@property (nonatomic, strong) DKNetworkSessionManager *sessionManager;
@property (nonatomic, strong) DKNetworkRequest *request;
@end

@implementation DKNetworking

static DKNetworkStatusBlock _networkStatusBlock;

+ (instancetype)networkManager
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.sessionManager = [[DKNetworkSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[DKNetworkGlobalConfig defaultConfig].baseURL]];
        self.request = [[DKNetworkRequest alloc] init];
    }
    return self;
}

#pragma mark - Config

+ (void)setupResponseSignalWithFlattenMapBlock:(DKNetworkFlattenMapBlock)flattenMapBlock
{
    [DKNetworkGlobalConfig defaultConfig].flattenMapBlock = flattenMapBlock;
}

#pragma mark - Network Status

+ (void)setupNetworkStatusWithBlock:(DKNetworkStatusBlock)networkStatusBlock
{
    _networkStatusBlock = networkStatusBlock;
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
        if (self.request.header) { // had global headers.
            NSMutableDictionary *mergeHeader = [NSMutableDictionary dictionaryWithDictionary:self.request.header];
            [mergeHeader addEntriesFromDictionary:header];
            self.request.header = mergeHeader;
        } else {
            self.request.header = header;
        }
        [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [self.sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
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
        self.sessionManager.requestSerializer = requestSerializer == DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
        return self;
    };
}

- (DKNetworking *(^)(DKResponseSerializer responseSerializer))responseSerializer
{
    return ^DKNetworking *(DKResponseSerializer responseSerializer){
        self.request.responseSerializer = responseSerializer;
        self.sessionManager.responseSerializer = responseSerializer == DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
        return self;
    };
}

- (DKNetworking *(^)(NSTimeInterval requestTimeoutInterval))requestTimeoutInterval
{
    return ^DKNetworking *(NSTimeInterval requestTimeoutInterval){
        self.request.requestTimeoutInterval = requestTimeoutInterval;
        self.sessionManager.requestSerializer.timeoutInterval = requestTimeoutInterval;
        return self;
    };
}

- (RACSignal *)executeSignal
{
    RACSignal *resultSignal = [self rac_request:self.request];
    if ([DKNetworkGlobalConfig defaultConfig].flattenMapBlock)
        return [resultSignal flattenMap:[DKNetworkGlobalConfig defaultConfig].flattenMapBlock];

    return resultSignal;
}

#pragma mark - Global Config

- (DKNetworking *(^)(NSString *))setupBaseURL
{
    return ^DKNetworking *(NSString *baseURL){
        [DKNetworkGlobalConfig defaultConfig].baseURL = baseURL;
        return self;
    };
}

- (DKNetworking *(^)(NSDictionary *))setupGlobalHeaders
{
    return ^DKNetworking *(NSDictionary *headers){
        [[DKNetworkGlobalConfig defaultConfig] setupHeaders:headers];
        return self;
    };
}

- (DKNetworking *(^)(DKRequestSerializer))setupGlobalRequestSerializer
{
    return ^DKNetworking *(DKRequestSerializer requestSerializer){
        [DKNetworkGlobalConfig defaultConfig].requestSerializer = requestSerializer;
        return self;
    };
}

- (DKNetworking *(^)(DKResponseSerializer))setupGlobalResponseSerializer
{
    return ^DKNetworking *(DKResponseSerializer responseSerializer){
        [DKNetworkGlobalConfig defaultConfig].responseSerializer = responseSerializer;
        return self;
    };
}

- (DKNetworking *(^)(NSTimeInterval))setupGlobalRequestTimeoutInterval
{
    return ^DKNetworking *(NSTimeInterval requestTimeoutInterval){
        [DKNetworkGlobalConfig defaultConfig].requestTimeoutInterval = requestTimeoutInterval;
        return self;
    };
}

- (RACSignal *)rac_request:(DKNetworkRequest *)request
{
    NSAssert(request.urlStr.length, @"DKNetworking Error: URL can not be nil");
    NSAssert(request.method.length, @"DKNetworking Error: Method can not be nil");
    
    NSString *URL = request.urlStr;
    NSDictionary *parameters = request.params;
    NSString *method = request.method;
    
    RACSignal *requestSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.sessionManager requestWithMethod:method URLString:URL parameters:parameters completion:^(NSURLSessionDataTask *task, DKNetworkResponse *response) {
            
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

#pragma mark - Private

+ (void)load
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (_networkStatusBlock) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    _networkStatusBlock(DKNetworkStatusUnknown);
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    _networkStatusBlock(DKNetworkStatusNotReachable);
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    _networkStatusBlock(DKNetworkStatusReachableViaWWAN);
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    _networkStatusBlock(DKNetworkStatusReachableViaWiFi);
                    break;
            }
        }
    }];
}



@end
