//
//  DKNetworkRequest.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkRequest.h"
#import "DKNetworkGlobalConfig.h"

@implementation DKNetworkRequest

- (instancetype)init
{
    if (self = [super init]) {
        self.header = [DKNetworkGlobalConfig defaultConfig].headers;
        self.requestSerializer = [DKNetworkGlobalConfig defaultConfig].requestSerializer;
        self.responseSerializer = [DKNetworkGlobalConfig defaultConfig].responseSerializer;
        self.requestTimeoutInterval = [DKNetworkGlobalConfig defaultConfig].requestTimeoutInterval;
    }
    return self;
}

@end
