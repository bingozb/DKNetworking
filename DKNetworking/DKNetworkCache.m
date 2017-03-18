//
//  DKNetworkCache.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkCache.h"
#import "YYCache.h"
#import <CommonCrypto/CommonDigest.h>

#define KCacheKey [self cacheKeyWithURL:URL parameters:parameters]

@implementation DKNetworkCache

static NSString *const kNetworkResponseCacheKey = @"DKNetworkResponseCache";
static YYCache *_cacheManager;

+ (void)initialize
{
    _cacheManager = [YYCache cacheWithName:kNetworkResponseCacheKey];
}

+ (void)setCache:(NSDictionary *)responseObject URL:(NSString *)URL parameters:(NSDictionary *)parameters
{
    [_cacheManager setObject:responseObject forKey:KCacheKey withBlock:nil];
}

+ (NSDictionary *)cacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters
{
    return (NSDictionary *)[_cacheManager objectForKey:KCacheKey];
}

+ (void)cacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters withBlock:(void(^)(id<NSCoding> object))block
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
    if (!parameters) return URL;
    
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *paramString = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",URL,paramString];
    
    return [self dk_md5:cacheKey];
}

/**
 MD5加密

 @param input 待加密字符串
 @return MD5加密后的字符串
 */
+ (NSString *)dk_md5:(NSString *)input
{
    const char *cStr = [[input dataUsingEncoding:NSUTF8StringEncoding] bytes];
    unsigned char digest[16];
    CC_MD5(cStr, (uint32_t)[[input dataUsingEncoding:NSUTF8StringEncoding] length], digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end
