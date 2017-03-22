//
//  MyHttpResponse.h
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/23.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKNetworkResponse.h"

@interface MyHttpResponse : DKNetworkResponse

/** 信息，成功的时候为success */
@property (nonatomic, copy) NSString *message;

/** 错误码 */
@property (nonatomic, copy) NSString *errorCode;

/** 结果 */
@property (nonatomic, strong) id result;

@end
