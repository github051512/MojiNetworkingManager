//
//  MJNetworking+CacheManager.m
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJNetworking+CacheManager.h"
#import "MJRequestCacheManager.h"

@implementation MJNetworking (CacheManager)

+ (NSUInteger)totalCacheSize {
    return [[MJRequestCacheManager shareManager] totalCacheSize];
}

+ (NSUInteger)totalDownloadDataSize {
    return [[MJRequestCacheManager shareManager] totalDownloadDataSize];
}

+ (void)clearDownloadData {
    [[MJRequestCacheManager shareManager] clearDownloadData];
}

+ (NSString *)getDownDirectoryPath {
    return [[MJRequestCacheManager shareManager] getDownDirectoryPath];
}

+ (NSString *)getCacheDiretoryPath {
    
    return [[MJRequestCacheManager shareManager] getCacheDiretoryPath];
}

+ (void)clearTotalCache {
    [[MJRequestCacheManager shareManager] clearTotalCache];
}


@end
