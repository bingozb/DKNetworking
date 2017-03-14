//
//  DKHttpService.h
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/9.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DKHttpResponse;

#define DKCallback(...) if (callback) { callback(__VA_ARGS__); }

typedef void(^DKHttpResponseBlock)(DKHttpResponse * _Nullable response);

@interface DKHttpService : NSObject

#pragma mark - Request Method

+ (void)POST:(nonnull NSString *)URLString parameters:(nullable id)parameters responseBlock:(nullable DKHttpResponseBlock)block;
+ (void)POST:(nonnull NSString *)URLString header:(nullable NSDictionary *)header parameters:(nullable id)parameters responseBlock:(nullable DKHttpResponseBlock)block;

+ (void)GET:(nonnull NSString *)URLString parameters:(nullable id)parameters responseBlock:(nullable DKHttpResponseBlock)block;
+ (void)GET:(nonnull NSString *)URLString header:(nullable NSDictionary *)header parameters:(nullable id)parameters responseBlock:(nullable DKHttpResponseBlock)block;

@end
