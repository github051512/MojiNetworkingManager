//
//  MJNetworking+CacheManager.h
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJNetworking.h"

NS_ASSUME_NONNULL_BEGIN

@interface MJNetworking (CacheManager)

/**
 *  获取缓存目录路径
 *
 *  @return 缓存目录路径
 */
+ (NSString *)getCacheDiretoryPath;

/**
 *  获取下载目录路径
 *
 *  @return 下载目录路径
 */
+ (NSString *)getDownDirectoryPath;

/**
 *  获取缓存大小
 *
 *  @return 缓存大小
 */
+ (NSUInteger)totalCacheSize;

/**
 *  清除所有缓存
 */
+ (void)clearTotalCache;

/**
 *  获取所有下载数据大小
 *
 *  @return 下载数据大小
 */
+ (NSUInteger)totalDownloadDataSize;

/**
 *  清除下载数据
 */
+ (void)clearDownloadData;


@end

NS_ASSUME_NONNULL_END
