//
//  DKNetworkRequest.h
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKNetworkEnum.h"

@interface DKNetworkRequest : NSObject

/** 请求地址 */
@property (nonatomic, copy) NSString *urlStr;

/** 请求方法 */
@property (nonatomic, assign) DKNetworkRequestMethod method;

/** 请求头 */
@property (nonatomic, strong) NSDictionary *header;

/** 请求参数 */
@property (nonatomic, strong) NSDictionary *params;

/** 缓存策略 */
@property (nonatomic, assign) DKNetworkCacheType cacheType;

/** 请求序列化格式 */
@property (nonatomic, assign) DKRequestSerializer requestSerializer;

/**
 创建一个网络请求对象

 @param urlStr 请求地址
 @param method 请求方法
 @param header 请求头
 @param params 请求参数
 @param cacheType 缓存策略
 @param requestSerializer 请求序列化格式
 @return 网络请求对象
 */
+ (instancetype)requestWithUrlStr:(NSString *)urlStr
                           method:(DKNetworkRequestMethod)method
                           params:(NSDictionary *)params
                           header:(NSDictionary *)header
                        cacheType:(DKNetworkCacheType)cacheType
                requestSerializer:(DKRequestSerializer)requestSerializer;

@end
