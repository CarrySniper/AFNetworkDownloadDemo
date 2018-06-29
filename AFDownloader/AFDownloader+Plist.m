//
//  AFDownloader+Plist.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/8.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloader+Plist.h"

#define CLFileName(URL)         [URL lastPathComponent] // 根据URL获取文件名，xxx.zip

static NSString *const kDownloadeOfDownloadLength        = @"downloadLength";        // 已下载长度
static NSString *const kDownloadeOfTotalLength           = @"totalLength";           // 总长度
static NSString *const kDownloadeOfProgress              = @"progress";              // 进度
static NSString *const kDownloadeOfName                  = @"name";                  // 名称
static NSString *const kDownloadeOfPath                  = @"path";                  // 存储路径
static NSString *const kDownloadeOfUrl                   = @"url";                   // URL字符串
static NSString *const kDownloadeOfCreateDate            = @"createDate";            // 创建时间


@implementation AFDownloader (Plist)

#pragma mark 获取一条记录
- (NSDictionary *)getPlistDataWithUrlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSDictionary *dataDict = plistData[fileName];
        return dataDict;
    }else{
        return nil;
    }
}

#pragma mark 获取所有记录
- (NSArray *)getAllPlistData {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    if (plistData) {
        NSArray *values = plistData.allValues;
        NSArray *sortArray = [values sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [obj1[kDownloadeOfCreateDate] compare:obj2[kDownloadeOfCreateDate]]; //时间升序
        }];
        return sortArray;
    }else{
        return nil;
    }
}


#pragma mark 添加文件数据
- (void)addPlistWithUrlString:(NSString *)urlString
				directoryPath:(NSString *)directoryPath
			   downloadLength:(NSUInteger)downloadLength
				  totalLength:(NSUInteger)totalLength {
    
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    plistData = plistData ? plistData : [NSMutableDictionary dictionary];
    
    NSString *fileName = CLFileName(urlString);
    float progress = totalLength > 0 ? (1.0 *downloadLength / totalLength) : 0.0f;
    NSMutableDictionary *dataDict = plistData[fileName];
    if (dataDict) {
        dataDict[kDownloadeOfDownloadLength] = @(downloadLength);
        dataDict[kDownloadeOfTotalLength] = @(totalLength);
        dataDict[kDownloadeOfProgress] = @(progress);
    }else{
        dataDict = [@{kDownloadeOfDownloadLength : @(downloadLength),
                      kDownloadeOfTotalLength : @(totalLength),
                      kDownloadeOfProgress : @(progress),
                      kDownloadeOfName : fileName,
                      kDownloadeOfUrl : urlString,
					  kDownloadeOfPath : directoryPath ? directoryPath : @"",
                      kDownloadeOfCreateDate : [NSDate date],
                      } mutableCopy];
    }
    plistData[fileName] = dataDict;
    [plistData writeToFile:CLFilesPlistPath atomically:YES];
}

#pragma mark 更新文件数据
- (void)updatePlistWithUrlString:(NSString *)urlString addDownloadLength:(NSUInteger)addDownloadLength {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSMutableDictionary *dataDict = plistData[fileName];
        NSUInteger totalLength = [dataDict[kDownloadeOfTotalLength] integerValue];
        NSUInteger downloadLength = [dataDict[kDownloadeOfDownloadLength] integerValue] + addDownloadLength;
        
        float progress = totalLength > 0 ? (1.0 *downloadLength / totalLength) : 0.0f;
        dataDict[kDownloadeOfDownloadLength] = @(downloadLength);
        dataDict[kDownloadeOfProgress] = @(progress);
        
        plistData[fileName] = dataDict;
        [plistData writeToFile:CLFilesPlistPath atomically:YES];
    }
}

#pragma mark 文件是否已下载完成，已完成则返回文件大小
- (NSUInteger)isDownloadCompleted:(NSString *)urlString {
	// 获取Plist文件数据
	NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
	if (plistData) {
		NSString *fileName = CLFileName(urlString);
		NSMutableDictionary *dataDict = plistData[fileName];
		if ([dataDict[kDownloadeOfTotalLength] isEqualToNumber:dataDict[kDownloadeOfDownloadLength]]) {
			NSUInteger totalLength = [dataDict[kDownloadeOfTotalLength] integerValue];
			return totalLength;
		}
	}
	return 0;
}

#pragma mark 获取文件总大小
- (NSUInteger)totalLengthPlistWithUrlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSMutableDictionary *dataDict = plistData[fileName];
        NSUInteger totalLength = [dataDict[kDownloadeOfTotalLength] integerValue];
        return totalLength;
    }
    return 0;
}

#pragma mark 获取文件已下载大小
- (NSUInteger)downloadLengthPlistWithUrlString:(NSString *)urlString {
	// 获取Plist文件数据
	NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
	if (plistData) {
		NSString *fileName = CLFileName(urlString);
		NSMutableDictionary *dataDict = plistData[fileName];
		NSUInteger downloadLengt = [dataDict[kDownloadeOfDownloadLength] integerValue];
		return downloadLengt;
	}
	return 0;
}

#pragma mark 删除一个数据
- (void)deletePlistWithUrlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        [plistData removeObjectForKey:fileName];
        [plistData writeToFile:CLFilesPlistPath atomically:YES];
    }
}

#pragma mark 删除所有数据
- (void)deleteAllPlistData {
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:CLFilesPlistPath];
    [plistData writeToFile:CLFilesPlistPath atomically:YES];
}

@end
