//
//  DKNetworkEnum.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#ifndef DKNetworkEnum_h
#define DKNetworkEnum_h

typedef NS_ENUM(NSUInteger, DKNetworkCacheType) {
    /** 只加载网络数据 */
    DKNetworkCacheTypeNetworkOnly,
    /** 先加载缓存,然后加载网络 */
    DKNetworkCacheTypeCacheNetwork
};

typedef NS_ENUM(NSUInteger, DKNetworkStatus) {
    /** 网络状态未知 */
    DKNetworkStatusUnknown,
    /** 无网络 */
    DKNetworkStatusNotReachable,
    /** 手机网络（蜂窝） */
    DKNetworkStatusReachableViaWWAN,
    /** WIFI网络 */
    DKNetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, DKRequestSerializer) {
    /** 请求数据为二进制格式 */
    DKRequestSerializerHTTP,
    /** 请求数据为JSON格式 */
    DKRequestSerializerJSON
};

typedef NS_ENUM(NSUInteger, DKResponseSerializer) {
    /** 响应数据为JSON格式*/
    DKResponseSerializerJSON,
    /** 响应数据为二进制格式*/
    DKResponseSerializerHTTP
};

typedef NS_ENUM(NSUInteger, DKRequestMethod) {
    /** GET请求 */
    DKRequestMethodGET,
    /** POST请求 */
    DKRequestMethodPOST,
    /** PUT请求 */
    DKRequestMethodPUT,
    /** DELETE请求 */
    DKRequestMethodDELETE,
    /** PATCH请求 */
    DKRequestMethodPATCH
};

#endif /* DKNetworkEnum_h */
