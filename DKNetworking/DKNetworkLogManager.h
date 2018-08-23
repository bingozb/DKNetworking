//
//  DKNetworkLogManager.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define DKLog(...) \
printf("%s\n", [[NSString stringWithFormat:@"%@ %s 第%d行: %@", [[DKNetworkLogManager defaultManager] logDateTime], __func__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]] UTF8String]);
#else
#define DKLog(...)
#endif

@class DKNetworkRequest, DKNetworkResponse;

@interface DKNetworkLogManager : NSObject

/** 单例对象 */
+ (instancetype)defaultManager;

/** 开启打印 */
- (void)openLog;
/** 关闭打印 */
- (void)closeLog;

/** 返回日志打印的日期时间 */
- (NSString *)logDateTime;

/**
 设置日期格式

 @param formatStr 日期格式，默认为@"yyyy-MM-dd hh:mm:ss.SSS"
 */
- (void)setupDateFormat:(NSString *)formatStr;

/** 打印请求 */
- (void)logRequest:(DKNetworkRequest *)request;

/** 打印响应 */
- (void)logResponse:(DKNetworkResponse *)response;

@end
