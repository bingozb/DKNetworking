//
//  DKNetworkLogManager.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkLogManager.h"

@interface DKNetworkLogManager ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation DKNetworkLogManager

static DKNetworkLogManager *_logManager;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logManager = [super allocWithZone:zone];
    });
    return _logManager;
}

+ (instancetype)defaultManager
{
    if (_logManager == nil) {
        _logManager = [[self alloc] init];
    }
    return _logManager;
}

- (NSString *)logDateTime
{
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

- (void)setupDateFormat:(NSString *)formatStr
{
    [self.dateFormatter setDateFormat:formatStr];
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss.SSS"];
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

@end
