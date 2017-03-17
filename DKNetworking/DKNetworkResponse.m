//
//  DKNetworkResponse.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkResponse.h"
#import "MJExtension.h"

@implementation DKNetworkResponse
MJCodingImplementation

+ (instancetype)responseWithRawData:(id)rawData error:(NSError *)error
{
    DKNetworkResponse *response = [[self alloc] init];
    response.rawData = rawData;
    response.error = error;
    
    return response;
}

@end
