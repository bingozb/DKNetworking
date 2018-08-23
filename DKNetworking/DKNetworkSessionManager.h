//
//  DKNetworkSessionManager.h
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "DKNetworkResponse.h"

/** 请求任务Block */
typedef void(^DKNetworkTaskBlock)(NSURLSessionDataTask *task, DKNetworkResponse *response);

/**
 封装表单数据上传协议
 */
@protocol DKMultipartFormData <AFMultipartFormData>

@end

/**
 遵守协议，让编译通过，调用AFN私有API
 - dataTaskWithHTTPMethod:URLString:parameters:success:failure
 */
@protocol DKNetWorkSessionManagerProtocol <NSObject>

@optional

/**
 AFN底层网络请求方法

 @param method HTTP请求方法
 @param URLString 请求地址
 @param parameters 参数字典
 @param success 成功回调
 @param failure 失败回调
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(void (^)(NSProgress *uploadProgress))uploadProgress
                                downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;

@end

/**
 对网络请求底层方法的封装，以便以后可能会换掉AFHTTPSessionManager
 */
@interface DKNetworkSessionManager : AFHTTPSessionManager

/**
 DKN网络请求底层方法

 @param method HTTP请求方法
 @param URLString 请求地址
 @param parameters 请求参数
 @param completion 请求回调
 @return 请求任务对象
 */
- (NSURLSessionDataTask *)requestWithMethod:(NSString *)method
                                  URLString:(NSString *)URLString
                                 parameters:(id)parameters
                                 completion:(DKNetworkTaskBlock)completion;

@end
