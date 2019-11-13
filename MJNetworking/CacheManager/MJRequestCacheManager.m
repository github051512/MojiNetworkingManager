//
//  MJRequestCacheManager.m
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJRequestCacheManager.h"
#import "MJMemoryCache.h"
#import "MJDiskCache.h"
#import "MJLRUManager.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const cacheDirKey = @"MJCacheDirKey";

static NSString *const downloadDirKey = @"MJDownloadDirKey";

static NSUInteger diskCapacity = 60 * 1024 * 1024;

static NSTimeInterval cacheTime = 7 * 24 * 60 * 60;


@implementation MJRequestCacheManager

+ (MJRequestCacheManager *)shareManager {
    
    static MJRequestCacheManager *_MJRequestCacheManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _MJRequestCacheManager = [[MJRequestCacheManager alloc] init];
    });
    return _MJRequestCacheManager;
}

- (void)setCacheTime:(NSTimeInterval)time diskCapacity:(NSUInteger)capacity {
    
    diskCapacity = capacity;
    cacheTime = time;
}

- (void)cacheResponseObject:(id)responseObject
                 requestUrl:(NSString *)requestUrl
                     params:(NSDictionary *)params {
    
    assert(responseObject);
    
    assert(requestUrl);
    
    if (!params) params = @{};
    
    NSString *originString = [NSString stringWithFormat:@"%@%@",requestUrl,params];
    NSString *hash = [self md5:originString];
    
    NSData *data = nil;
    NSError *error = nil;
    if ([responseObject isKindOfClass:[NSData class]]) {
       
        data = responseObject;
    }else if ([responseObject isKindOfClass:[NSDictionary class]]){
        
        data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
    }
    
    if (error == nil) {
        //缓存到内存中
        [MJMemoryCache writeData:responseObject forKey:hash];
        
        //缓存到磁盘中
        //磁盘路径
        NSString *directoryPath = nil;
      
        directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
        
        if (!directoryPath) {
        
            directoryPath = [@"MJNetworking" stringByAppendingPathComponent:@"NetworkCache"];
            //[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"MJNetworking"] stringByAppendingPathComponent:@"NetworkCache"];
            
            [[NSUserDefaults standardUserDefaults] setObject:directoryPath forKey:cacheDirKey];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [MJDiskCache writeData:data toDir:[self dataFilePathWithName:directoryPath] filename:hash];
        
        [[MJLRUManager shareManager] addFileNode:hash];
    }
}

- (NSString *)dataFilePathWithName:(NSString *)name {
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *completitonPath = [path stringByAppendingPathComponent:name];
    
    return completitonPath;
}

- (id)getCacheResponseObjectWithRequestUrl:(NSString *)requestUrl
                                    params:(NSDictionary *)params {
    assert(requestUrl);
    
    id cacheData = nil;
    
    if (!params) params = @{};
    
    NSString *originString = [NSString stringWithFormat:@"%@%@",requestUrl,params];
    NSString *hash = [self md5:originString];
    
    //先从内存中查找
    cacheData = [MJMemoryCache readDataWithKey:hash];
    
    if (!cacheData) {
        NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
        
        if (directoryPath) {
            cacheData = [MJDiskCache readDataFromDir:[self dataFilePathWithName:directoryPath] filename:hash];
            
            if (cacheData) [[MJLRUManager shareManager] refreshIndexOfFileNode:hash];
        }
    }
    
    if (cacheData) {
        
        NSError *error = nil;
        id  responseJson = [NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers error:&error];
        
        return responseJson;
        
    } else {
        
        return nil;
    }
    
    
}

- (void)storeDownloadData:(NSData *)data
               requestUrl:(NSString *)requestUrl {
    assert(data);
    
    assert(requestUrl);
    
    NSString *fileName = nil;
    NSString *type = nil;
    NSArray *strArray = nil;
    
    strArray = [requestUrl componentsSeparatedByString:@"."];
    if (strArray.count > 0) {
        type = strArray[strArray.count - 1];
    }
    
    if (type) {
        fileName = [NSString stringWithFormat:@"%@.%@",[self md5:requestUrl],type];
    }else {
        fileName = [NSString stringWithFormat:@"%@",[self md5:requestUrl]];
    }
    
    NSString *directoryPath = nil;
    directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:downloadDirKey];
    if (!directoryPath) {
        directoryPath = [@"MJNetworking" stringByAppendingPathComponent:@"MJDownload"];
        
//        [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@""] stringByAppendingPathComponent:@"Download"];
        
        [[NSUserDefaults standardUserDefaults] setObject:directoryPath forKey:downloadDirKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    [MJDiskCache writeData:data toDir:directoryPath filename:fileName];
}

- (NSURL *)getDownloadDataFromCacheWithRequestUrl:(NSString *)requestUrl {
    assert(requestUrl);
    
    NSData *data = nil;
    NSString *fileName = nil;
    NSString *type = nil;
    NSArray *strArray = nil;
    NSURL *fileUrl = nil;
    
    strArray = [requestUrl componentsSeparatedByString:@"."];
    if (strArray.count > 0) {
        type = strArray[strArray.count - 1];
    }
    
    if (type) {
        fileName = [NSString stringWithFormat:@"%@.%@",[self md5:requestUrl],type];
    }else {
        fileName = [NSString stringWithFormat:@"%@",[self md5:requestUrl]];
    }
    
    NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:downloadDirKey];
    
    if (directoryPath) data = [MJDiskCache readDataFromDir:[self dataFilePathWithName:directoryPath] filename:fileName];
    
    if (data) {
        NSString *path = [directoryPath stringByAppendingPathComponent:fileName];
        fileUrl = [NSURL fileURLWithPath:path];
    }
    
    return fileUrl;
}

- (NSUInteger)totalCacheSize {
    
    NSString *diretoryPath = [[NSUserDefaults standardUserDefaults] objectForKey: cacheDirKey];
    
    return [MJDiskCache dataSizeInDir:diretoryPath];
}

- (NSUInteger)totalDownloadDataSize {
    
    NSString *diretoryPath = [[NSUserDefaults standardUserDefaults] objectForKey: downloadDirKey];
    
    return [MJDiskCache dataSizeInDir:diretoryPath];
}

- (void)clearDownloadData {
    
    NSString *diretoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:downloadDirKey];
    
    [MJDiskCache clearDataIinDir:diretoryPath];
}

- (NSString *)getDownDirectoryPath {
    
    NSString *diretoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:downloadDirKey];
    return diretoryPath;
}

- (NSString *)getCacheDiretoryPath {
    NSString *diretoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
    return diretoryPath;
}

- (void)clearTotalCache {
    NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
    
    [MJDiskCache clearDataIinDir:directoryPath];
}

- (void)clearLRUCache {
    if ([self totalCacheSize] > diskCapacity) {
        NSArray *deleteFiles = [[MJLRUManager shareManager] removeLRUFileNodeWithCacheTime:cacheTime];
        NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
       
        if (directoryPath && deleteFiles.count > 0) {
        
            [deleteFiles enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
                NSString *filePath = [directoryPath stringByAppendingPathComponent:obj];
                [MJDiskCache deleteCache:filePath];
            }];
            
        }
    }
}

#pragma mark - 散列值
- (NSString *)md5:(NSString *)string {
    if (string == nil || string.length == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH],i;
    
    CC_MD5([string UTF8String],(int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],digest);
    
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x",(int)(digest[i])];
    }
    
    return [ms copy];
}


@end
