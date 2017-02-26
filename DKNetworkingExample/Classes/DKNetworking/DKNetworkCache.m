//
//  DKNetworkCache.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkCache.h"
#import "YYCache.h"

#define KCacheKey [self cacheKeyWithURL:URL parameters:parameters]

@implementation DKNetworkCache
static NSString *const DKNetworkResponseCacheKey = @"DKNetworkResponseCache";
static YYCache *_cacheManager;

+ (void)initialize
{
    _cacheManager = [YYCache cacheWithName:DKNetworkResponseCacheKey];
}

+ (void)setHttpCache:(NSDictionary *)responseObject URL:(NSString *)URL parameters:(NSDictionary *)parameters
{
    [_cacheManager setObject:responseObject forKey:KCacheKey withBlock:nil];
}

+ (NSDictionary *)httpCacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters
{
    return (NSDictionary *)[_cacheManager objectForKey:KCacheKey];
}

+ (void)httpCacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters withBlock:(void(^)(id<NSCoding> object))block
{
    [_cacheManager objectForKey:KCacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(object);
        });
    }];
}

+ (NSString *)cacheSize
{
    NSInteger cacheSize = [_cacheManager.diskCache totalCost];
    if (cacheSize < 1024) {
        return [NSString stringWithFormat:@"%ldB",(long)cacheSize];
    } else if (cacheSize < powf(1024.f, 2)) {
        return [NSString stringWithFormat:@"%.2fKB",cacheSize / 1024.f];
    } else if (cacheSize < powf(1024.f, 3)) {
        return [NSString stringWithFormat:@"%.2fMB",cacheSize / powf(1024.f, 2)];
    } else {
        return [NSString stringWithFormat:@"%.2fGB",cacheSize / powf(1024.f, 3)];
    }
}

+ (void)clearCache
{
    [_cacheManager.diskCache removeAllObjects];
}

+ (NSString *)cacheKeyWithURL:(NSString *)URL parameters:(NSDictionary *)parameters
{
    if(!parameters) return URL;
    
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *paramString = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"%@%@",URL,paramString];
}

@end
