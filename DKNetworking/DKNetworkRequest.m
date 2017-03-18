//
//  DKNetworkRequest.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkRequest.h"

@implementation DKNetworkRequest

+ (instancetype)requestWithUrlStr:(NSString *)urlStr method:(DKRequestMethod)method params:(NSDictionary *)params
{
    DKNetworkRequest *request = [[self alloc] init];
    request.urlStr = urlStr;
    request.method = method;
    request.params = params;
    
    return request;
}

@end
