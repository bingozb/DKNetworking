//
//  DKNetworkRequest.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkRequest.h"

@implementation DKNetworkRequest

+ (instancetype)requestWithUrlStr:(NSString *)urlStr method:(DKNetworkRequestMethod)method params:(NSDictionary *)params header:(NSDictionary *)header cacheType:(DKNetworkCacheType)cacheType requestSerializer:(DKRequestSerializer)requestSerializer
{
    DKNetworkRequest *request = [[self alloc] init];
    request.urlStr = urlStr;
    request.method = method;
    request.header = header;
    request.params = params;
    request.cacheType = cacheType;
    request.requestSerializer = requestSerializer;
    
    return request;
}

@end
