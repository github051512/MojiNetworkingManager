//
//  MJCacheManager.h
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MJRequestCacheManager : NSObject

/**
 *  默认的磁盘空间是60MB，缓存有效期是7天
 *
 *  @return manager
 */
+ (MJRequestCacheManager *)shareManager;

/**
 *  设置缓存时间和缓存的磁盘空间
 *
 *  @param time     缓存时间
 *  @param capacity 磁盘空间
 */
- (void)setCacheTime:(NSTimeInterval)time
        diskCapacity:(NSUInteger)capacity;

/**
 *  缓存响应数据
 *
 *  @param responseObject 响应数据
 *  @param requestUrl     请求url
 *  @param params         请求参数
 */
- (void)cacheResponseObject:(id)responseObject
                 requestUrl:(NSString *)requestUrl
                     params:(NSDictionary *)params;

/**
 *  获取响应数据
 *
 *  @param requestUrl 请求url
 *  @param params     请求参数
 *
 *  @return 响应数据
 */
- (id)getCacheResponseObjectWithRequestUrl:(NSString *)requestUrl
                                    params:(NSDictionary *)params;

/**
 *  存储下载文件
 *
 *  @param data       文件数据
 *  @param requestUrl 请求url
 *
 */
- (void)storeDownloadData:(NSData *)data
               requestUrl:(NSString *)requestUrl;

/**
 *  获取磁盘中的下载文件
 *
 *  @param requestUrl 请求url
 *
 *  @return 文件本地存储路径
 */
- (NSURL *)getDownloadDataFromCacheWithRequestUrl:(NSString *)requestUrl;

/**
 *  获取缓存目录路径
 *
 *  @return 缓存目录路径
 */
- (NSString *)getCacheDiretoryPath;

/**
 *  获取下载目录路径
 *
 *  @return 下载目录路径
 */
- (NSString *)getDownDirectoryPath;

/**
 *  获取缓存大小
 *
 *  @return 缓存大小
 */
- (NSUInteger)totalCacheSize;

/**
 *  清除所有缓存
 */
- (void)clearTotalCache;

/**
 *  清除最近最少使用的缓存，用LRU算法实现
 */
- (void)clearLRUCache;

/**
 *  获取所有下载数据大小
 *
 *  @return 下载数据大小
 */
- (NSUInteger)totalDownloadDataSize;

/**
 *  清除下载数据
 */
- (void)clearDownloadData;

@end

NS_ASSUME_NONNULL_END
