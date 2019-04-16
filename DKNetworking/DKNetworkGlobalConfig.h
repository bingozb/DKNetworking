//
//  DKNetworkGlobalConfig.h
//  DKNetworkingExample
//
//  Created by Binhao Zhuang on 2018/8/23.
//  Copyright © 2018 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKNetworkEnum.h"
#import "ReactiveCocoa.h"

typedef RACStream *(^DKNetworkFlattenMapBlock)(RACTuple *tuple);

@interface DKNetworkGlobalConfig : NSObject

/** baseURL */
@property (nonatomic, copy) NSString *baseURL;

/** 请求头 */
@property (nonatomic, strong, readonly) NSDictionary *headers;

/** 请求序列化格式 */
@property (nonatomic, assign) DKRequestSerializer requestSerializer;

/** 响应序列化格式 */
@property (nonatomic, assign) DKResponseSerializer responseSerializer;

/** 请求超时时间 */
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/** 信号结果回调 */
@property (nonatomic, copy) DKNetworkFlattenMapBlock flattenMapBlock;

/** 单例对象 */
+ (instancetype)defaultConfig;

/** 设置请求头 */
- (void)setupHeaders:(NSDictionary *)headers;

@end
