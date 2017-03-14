//
//  DKHttpService.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/9.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKHttpService.h"
#import "DKNetworking.h"
#import "DKHttpResponse.h"
#import "MJExtension.h"

static NSString *const kHttpSuccessMessage = @"success";
static NSString *const kAPIDomain = @"cn.dankal.DKHttpService";

@implementation DKHttpService

#pragma mark - Request Method

+ (void)POST:(NSString *)URLString parameters:(id)parameters responseBlock:(DKHttpResponseBlock)block
{
    [self POST:URLString header:nil parameters:parameters responseBlock:block];
}

+ (void)POST:(NSString *)URLString header:(NSDictionary *)header parameters:(id)parameters responseBlock:(DKHttpResponseBlock)block
{
    [DKNetworking setValue:[[header allValues] firstObject] forHTTPHeaderField:[[header allKeys] firstObject]];
    [DKNetworking POST:URLString parameters:parameters callback:^(NSDictionary *responseObject, NSError *error) {
        [self handleHttpResponseObject:responseObject responseBlock:block error:error];
    }];
}

+ (void)GET:(NSString *)URLString parameters:(id)parameters responseBlock:(DKHttpResponseBlock)block
{
    [self GET:URLString header:nil parameters:parameters responseBlock:block];
}

+ (void)GET:(NSString *)URLString header:(NSDictionary *)header parameters:(id)parameters responseBlock:(DKHttpResponseBlock)block
{
    [DKNetworking setValue:[[header allValues] firstObject] forHTTPHeaderField:[[header allKeys] firstObject]];
    [DKNetworking GET:URLString parameters:parameters callback:^(NSDictionary *responseObject, NSError *error) {
        [self handleHttpResponseObject:responseObject responseBlock:block error:error];
    }];
}

#pragma mark - Private Method

+ (void)handleHttpResponseObject:(NSDictionary *)responseObject responseBlock:(DKHttpResponseBlock)block error:(NSError *)error
{
    DKHttpResponse *resp = [DKHttpResponse mj_objectWithKeyValues:responseObject];
    resp.rawData = responseObject;
    if (responseObject[@"result"])
        resp.result = responseObject[@"result"];
    if (block) {
        if (!error) {
            if ([resp.message isEqualToString:kHttpSuccessMessage]) {
                block(resp);
            } else {
                if (resp) {
                    resp.error = [NSError errorWithDomain:kAPIDomain code:[resp.state integerValue] userInfo:@{@"message":resp.message}];
                    block(resp);
                }
            }
        } else {
            if (error.code == NSURLErrorCancelled) return;
            DKHttpResponse *resp = [[DKHttpResponse alloc] init];
            resp.error = error;
            block(resp);
        }
    }
}


@end
