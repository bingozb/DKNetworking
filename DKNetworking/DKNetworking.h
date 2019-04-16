//
//  DKNetworking.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MJExtension.h"
#import "ReactiveCocoa.h"
#import "DKNetworkEnum.h"
#import "DKNetworkCache.h"
#import "DKNetworkRequest.h"
#import "DKNetworkResponse.h"
#import "DKNetworkLogManager.h"
#import "DKNetworkSessionManager.h"

#define DKNetworkManager [DKNetworking networkManager]

typedef void(^DKNetworkStatusBlock)(DKNetworkStatus status);

@interface DKNetworking : NSObject

@property (nonatomic, strong, readonly) DKNetworkSessionManager *sessionManager;


+ (instancetype)networkManager;

#pragma mark - Config

/**
 设置响应结果回调，可以设置信号返回的value为自己想要的值，比如用MJExtension框架，将DKNetworkResponse对象的rawData字典转为自己需要用的实体类再返回
 
 @param flattenMapBlock 结果映射的设置回调block，其中RACTuple的first为DKNetworkRequest对象，second为DKNetworkResponse对象
 */
+ (void)setupResponseSignalWithFlattenMapBlock:(RACStream *(^)(RACTuple *tuple))flattenMapBlock;

#pragma mark - Network Status

/**
 有网络:YES, 无网络:NO
 */
+ (BOOL)isNetworking;

/**
 手机网络:YES, 非手机网络:NO
 */
+ (BOOL)isWWANNetwork;

/**
 WiFi网络:YES, 非WiFi网络:NO
 */
+ (BOOL)isWiFiNetwork;

/**
 实时获取网络状态，通过Block回调实时获取
 */
+ (void)setupNetworkStatusWithBlock:(DKNetworkStatusBlock)networkStatusBlock;

#pragma mark - Log

/**
 开启日志打印 (Debug)
 */
+ (void)openLog;

/**
 关闭日志打印
 */
+ (void)closeLog;

#pragma mark - Request Method

- (DKNetworking *(^)(NSString *url))get;
- (DKNetworking *(^)(NSString *url))post;
- (DKNetworking *(^)(NSString *url))put;
- (DKNetworking *(^)(NSString *url))delete;
- (DKNetworking *(^)(NSString *url))patch;

- (DKNetworking *(^)(NSDictionary *params))params;
- (DKNetworking *(^)(NSDictionary *header))header;

- (DKNetworking *(^)(DKRequestSerializer requestSerializer))requestSerializer;
- (DKNetworking *(^)(DKResponseSerializer responseSerializer))responseSerializer;

- (DKNetworking *(^)(DKNetworkCacheType cacheType))cacheType;
- (DKNetworking *(^)(NSTimeInterval requestTimeoutInterval))requestTimeoutInterval;

- (RACSignal *)executeSignal;

#pragma mark - Global Config

/**
 设置接口根路径, 设置后所有的网络访问都使用相对路径
 baseURL的路径一定要有"/"结尾
 */
- (DKNetworking *(^)(NSString *baseURL))setupBaseURL;
- (DKNetworking *(^)(NSDictionary *headers))setupGlobalHeaders;
- (DKNetworking *(^)(DKRequestSerializer requestSerializer))setupGlobalRequestSerializer;
- (DKNetworking *(^)(DKResponseSerializer responseSerializer))setupGlobalResponseSerializer;
- (DKNetworking *(^)(NSTimeInterval requestTimeoutInterval))setupGlobalRequestTimeoutInterval;

@end
