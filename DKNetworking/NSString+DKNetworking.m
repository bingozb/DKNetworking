//
//  NSString+DKNetworking.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "NSString+DKNetworking.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (DKNetworking)

- (instancetype)dk_md5
{
    const char *cStr = [[self dataUsingEncoding:NSUTF8StringEncoding] bytes];
    unsigned char digest[16];
    CC_MD5(cStr, (uint32_t)[[self dataUsingEncoding:NSUTF8StringEncoding] length], digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end
