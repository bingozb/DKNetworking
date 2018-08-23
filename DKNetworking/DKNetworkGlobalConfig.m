//
//  DKNetworkGlobalConfig.m
//  DKNetworkingExample
//
//  Created by Binhao Zhuang on 2018/8/23.
//  Copyright © 2018 cn.dankal. All rights reserved.
//

#import "DKNetworkGlobalConfig.h"

@interface DKNetworkGlobalConfig ()
@property (nonatomic, strong) NSDictionary *headers;
@end

@implementation DKNetworkGlobalConfig

static DKNetworkGlobalConfig *_config;
static CGFloat const kDefaultTimeoutInterval = 10.f;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _config = [super allocWithZone:zone];
    });
    return _config;
}

+ (instancetype)defaultConfig
{
    if (_config == nil) {
        _config = [[self alloc] init];
    }
    return _config;
}

- (void)setupHeaders:(NSDictionary *)headers
{
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id obj, BOOL * _Nonnull stop) {
            [self setValue:obj forHTTPHeaderField:key];
        }];
    } else {
        _headers = nil;
    }
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    if (!_headers) {
        _headers = [NSDictionary dictionaryWithObject:value forKey:field];
    } else {
        NSMutableDictionary *headersTemp = [NSMutableDictionary dictionaryWithDictionary:_headers];
        headersTemp[field] = value;
        _headers = [headersTemp copy];
    }
}

# pragma mark - Getters && Setters

- (NSTimeInterval)requestTimeoutInterval
{
    return _requestTimeoutInterval ? _requestTimeoutInterval : kDefaultTimeoutInterval;
}

@end
