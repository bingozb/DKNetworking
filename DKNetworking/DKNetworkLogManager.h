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

@interface DKNetworkLogManager : NSObject

/**
 单例对象
 */
+ (instancetype)defaultManager;

/**
 返回日志打印的日期时间
 */
- (NSString *)logDateTime;

/**
 设置日期格式

 @param formatStr 日期格式，默认为@"yyyy-MM-dd hh:mm:ss.SSS"
 */
- (void)setupDateFormat:(NSString *)formatStr;

@end
