//
//  MJLRUManager.h
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  最近最少使用淘汰算法，创建一个队列，新加的结点添加在队列的尾部；命中缓存时，调整结点的位置，将其放在队列的尾部；要淘汰缓存时，删除队列的头部节点
 */
@interface MJLRUManager : NSObject

/**
 *  当前队列的情况
 */
@property (nonatomic, copy, readonly)NSArray *currentQueue;

+ (MJLRUManager *)shareManager;

/**
 *  添加新的结点
 *
 *  @param filename 文件名字
 */
- (void)addFileNode:(NSString *)filename;

/**
 *  调整结点位置，一般用于命中缓存时
 *
 *  @param filename 文件名字
 */
- (void)refreshIndexOfFileNode:(NSString *)filename;

/**
 *  删除最近最久未使用的缓存
 *
 *  @param time 缓存时间
 *
 *  @return 删除结点的文件名列表
 */
- (NSArray *)removeLRUFileNodeWithCacheTime:(NSTimeInterval) time;


@end

NS_ASSUME_NONNULL_END
