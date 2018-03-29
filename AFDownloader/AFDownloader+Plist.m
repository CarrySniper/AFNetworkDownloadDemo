//
//  AFDownloader+Plist.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/8.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloader+Plist.h"

#define CLFileName(URL)         [URL lastPathComponent] // 根据URL获取文件名，xxx.zip

static NSString *const kKeyForDownloadLength        = @"downloadLength";        // 已下载长度键
static NSString *const kKeyForTotalLength           = @"totalLength";           // 总长度键
static NSString *const kKeyForProgress              = @"progress";              // 进度
static NSString *const kKeyForName                  = @"name";                  // 名称
static NSString *const kKeyForUrl                   = @"url";                   // URL字符串
static NSString *const kKeyForCreateDate            = @"createDate";            // 创建时间


@implementation AFDownloader (Plist)

#pragma mark 获取一条记录
- (NSDictionary *)getOneDataWithPlist:(NSString *)plistPath urlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSDictionary *dataDict = plistData[fileName];
        return dataDict;
    }else{
        return nil;
    }
}
    
#pragma mark 获取所有记录
- (NSArray *)getAllDataWithPlist:(NSString *)plistPath {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistPath) {
        NSArray *values = plistData.allValues;
        NSArray *sortArray = [values sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [obj1[kKeyForCreateDate] compare:obj2[kKeyForCreateDate]]; //时间升序
        }];
        return sortArray;
    }else{
        return nil;
    }
}

#pragma mark 记录文件大小
- (void)writeLengthWithPlist:(NSString *)plistPath urlString:(NSString *)urlString downloadLength:(NSUInteger)downloadLength totalLength:(NSUInteger)totalLength {
    
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    plistData = plistData ? plistData : [NSMutableDictionary dictionary];
    
    NSString *fileName = CLFileName(urlString);
    float progress = totalLength > 0 ? (1.0 *downloadLength / totalLength) : 0.0f;
    NSMutableDictionary *dataDict = plistData[fileName];
    if (dataDict) {
        dataDict[kKeyForDownloadLength] = @(downloadLength);
        dataDict[kKeyForTotalLength] = @(totalLength);
        dataDict[kKeyForProgress] = @(progress);
    }else{
        dataDict = [@{kKeyForDownloadLength : @(downloadLength),
                      kKeyForTotalLength : @(totalLength),
                      kKeyForProgress : @(progress),
                      kKeyForName : fileName,
                      kKeyForUrl : urlString,
                      kKeyForCreateDate : [NSDate date],
                      } mutableCopy];
    }
    plistData[fileName] = dataDict;
    [plistData writeToFile:plistPath atomically:YES];
}

#pragma mark 更新文件数据
- (void)updateWithPlist:(NSString *)plistPath urlString:(NSString *)urlString addDownloadLength:(NSUInteger)addDownloadLength {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSMutableDictionary *dataDict = plistData[fileName];
        NSUInteger totalLength = [dataDict[kKeyForTotalLength] integerValue];
        NSUInteger downloadLength = [dataDict[kKeyForDownloadLength] integerValue] + addDownloadLength;
        
        float progress = totalLength > 0 ? (1.0 *downloadLength / totalLength) : 0.0f;
        dataDict[kKeyForDownloadLength] = @(downloadLength);
        dataDict[kKeyForProgress] = @(progress);
        
        plistData[fileName] = dataDict;
        [plistData writeToFile:plistPath atomically:YES];
    }
}

#pragma mark 获取文件大小
- (NSUInteger)totalLengthWithPlist:(NSString *)plistPath urlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        NSMutableDictionary *dataDict = plistData[fileName];
        NSUInteger totalLength = [dataDict[kKeyForTotalLength] integerValue];
        return totalLength;
    }
    return 0;
}

#pragma mark 删除一个数据
- (void)deleteOneWithPlist:(NSString *)plistPath urlString:(NSString *)urlString {
    // 获取Plist文件数据
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistData) {
        NSString *fileName = CLFileName(urlString);
        [plistData removeObjectForKey:fileName];
        [plistData writeToFile:plistPath atomically:YES];
    }
}

#pragma mark 删除所有数据
- (void)deleteAllWithPlist:(NSString *)plistPath {
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [plistData writeToFile:plistPath atomically:YES];
}

@end
