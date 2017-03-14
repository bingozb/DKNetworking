//
//  DKHttpResponse.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/9.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKHttpResponse : NSObject

/*
 Dankal API JSON 格式：
 {
    "state": "0001",
    "message": "success",
    "result": {
        "content": "1489028459"
    }
 }
 */

/** 状态码 */
@property (nonatomic, copy) NSString *state;
/** 说明 */
@property (nonatomic, copy) NSString *message;
/** 结果 */
@property (nonatomic, copy) NSDictionary *result;
/** 原数据 */
@property (nonatomic, strong) id rawData;
/** 异常 */
@property (nonatomic, strong) NSError *error;
@end
