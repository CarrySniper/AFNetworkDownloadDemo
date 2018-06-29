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
- (NSDictionary *)getPlistDataWithUrlString:(NSString *)urlString;

/**
 获取所有记录
 */
- (NSArray *)getAllPlistData;


/**
 添加文件数据

 @param urlString url链接
 @param directoryPath 下载路径
 @param downloadLength 已下载大小
 @param totalLength 总文件大小
 */
- (void)addPlistWithUrlString:(NSString *)urlString
				directoryPath:(NSString *)directoryPath
			   downloadLength:(NSUInteger)downloadLength
				  totalLength:(NSUInteger)totalLength;

/**
 文件更新

 @param urlString url链接
 @param addDownloadLength 添加下载大小
 */
- (void)updatePlistWithUrlString:(NSString *)urlString
			   addDownloadLength:(NSUInteger)addDownloadLength;

/**
 文件是否已下载完成，已完成则返回文件大小
 */
- (NSUInteger)isDownloadCompleted:(NSString *)urlString;

/**
 获取文件总大小
 */
- (NSUInteger)totalLengthPlistWithUrlString:(NSString *)urlString;

/**
 获取文件已下载大小
 */
- (NSUInteger)downloadLengthPlistWithUrlString:(NSString *)urlString;

/**
 删除一个数据
 */
- (void)deletePlistWithUrlString:(NSString *)urlString;

/**
 删除所有数据
 */
- (void)deleteAllPlistData;

@end
