//
//  DKNetworkResponse.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKNetworkResponse : NSObject<NSCoding>

/** HTTP状态码 */
@property (nonatomic, assign) NSUInteger httpStatusCode;

/** 原始数据 */
@property (nonatomic, strong) id rawData;

/** 错误 */
@property (nonatomic, strong) NSError *error;


+ (instancetype)responseWithRawData:(id)rawData httpStatusCode:(NSUInteger)httpStatusCode error:(NSError *)error;

@end
