//
//  DKNetworkRequest.h
//  DKNetworking
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
@property (nonatomic, assign) DKRequestMethod method;

/** 请求参数 */
@property (nonatomic, strong) NSDictionary *params;

/** 请求头 */
@property (nonatomic, strong) NSDictionary *header;

/** 缓存方式 */
@property (nonatomic, assign) DKNetworkCacheType cacheType;

/** 请求序列化格式 */
@property (nonatomic, assign) DKRequestSerializer requestSerializer;

/** 请求超时时间 */
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;


/**
 创建一个网络请求对象

 @param urlStr 请求地址
 @param method 请求方法
 @param params 请求参数
 @return 网络请求对象
 */
+ (instancetype)requestWithUrlStr:(NSString *)urlStr method:(DKRequestMethod)method params:(NSDictionary *)params;

@end
