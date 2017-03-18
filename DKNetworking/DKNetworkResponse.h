//
//  DKNetworkResponse.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKNetworkResponse : NSObject<NSCoding>

/** 原始数据 */
@property (nonatomic, strong) id rawData;

/** 错误 */
@property (nonatomic, strong) NSError *error;

/**
 创建一个响应对象

 @param rawData 原始数据
 @param error 错误
 @return 响应对象
 */
+ (instancetype)responseWithRawData:(id)rawData error:(NSError *)error;

@end
