//
//  AFDownloader+Plist.h
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/8.
//  Copyright © 2018年 CJQ. All rights reserved.
//

// Plist文件
#import "AFDownloader.h"

@interface AFDownloader (Plist)

/**
 获取一条记录
 */
- (NSDictionary *)getOneDataWithPlist:(NSString *)plistPath urlString:(NSString *)urlString;

/**
 获取所有记录
 */
- (NSArray *)getAllDataWithPlist:(NSString *)plistPath;

/**
 记录文件大小
 */
- (void)writeLengthWithPlist:(NSString *)plistPath
                 urlString:(NSString *)urlString
            downloadLength:(NSUInteger)downloadLength
               totalLength:(NSUInteger)totalLength;

/**
 文件更新
 */
- (void)updateWithPlist:(NSString *)plistPath
          urlString:(NSString *)urlString
  addDownloadLength:(NSUInteger)addDownloadLength;

/**
 获取文件大小
 */
- (NSUInteger)totalLengthWithPlist:(NSString *)plistPath
                     urlString:(NSString *)urlString;

/**
 删除一个数据
 */
- (void)deleteOneWithPlist:(NSString *)plistPath urlString:(NSString *)urlString;

/**
 删除所有数据
 */
- (void)deleteAllWithPlist:(NSString *)plistPath;

@end
