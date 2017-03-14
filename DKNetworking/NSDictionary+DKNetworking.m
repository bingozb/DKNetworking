//
//  NSDictionary+DKNetworking.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/26.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "NSDictionary+DKNetworking.h"

@implementation NSDictionary (DKNetworking)

- (NSString *)dk_jsonString
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

@end
