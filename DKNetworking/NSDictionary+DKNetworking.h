//
//  NSDictionary+DKNetworking.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/26.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (DKNetworking)

/**
 字典转成标准Json格式的字符串

 @return Json字符串
 */
- (NSString *)dk_jsonString;

@end
