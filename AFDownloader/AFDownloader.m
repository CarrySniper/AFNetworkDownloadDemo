//
//  AFDownloader.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloader.h"
#import "AFDownloader+Plist.h"
#import "AFDownloader+Listener.h"

@interface AFDownloader ()

@end

@implementation AFDownloader

+ (instancetype)manager {
    return [[self alloc] init];
}

static AFDownloader *instance = nil;
static dispatch_once_t onceToken;
- (instancetype)init
{
    dispatch_once(&onceToken, ^{
        instance = [super init];
        
        [self setSessionManagerListener];
        
        self.maxConcurrentCount = 0;
        self.fileManager = [NSFileManager defaultManager];
        self.downloadsSet = [NSMutableDictionary dictionary];
        self.downloadingArray = [NSMutableArray array];
        self.waitingArray = [NSMutableArray array];
        
        // 创建下载目录
        NSString *cachesDirectory = [self cachesDirectory];
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:cachesDirectory isDirectory:&isDirectory];
        if (!isExists || !isDirectory) {
            [fileManager createDirectoryAtPath:cachesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSLog(@"AFDownloader下载目录：%@", cachesDirectory);
    });
    return instance;
}

#pragma mark 下载数据
- (void)downloadURL:(NSString *)urlString
          directory:(NSString *)directory
              state:(CLDownloadStateBlock)state
           progress:(CLDownloadProgressBlock) progress
         completion:(CLDownloadCompletionBlock)completion
{
    if (!urlString) {
        return;
    }
    
    NSString *encodedString = [self encodedString:urlString];
    NSInteger length = [self downloadedLength:encodedString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    // 判断urlString的文件名是否已经下载完成
    if ([self isDownloadCompleted:encodedString]) {
        if (state) {
            state(CLDownloadStateCompleted);
        }
        if (progress) {
            progress([self formatByteCount:length], [self formatByteCount:length], [self formatByteCount:0.0], 1.0);
        }
        if (completion) {
            completion(YES, [self fileAbsolutePath:encodedString], nil);
        }
        return;
    }
    
    // 判断是否在下载集合里面，存在则不创建新的
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];//键为文件名
    if (object) {
        return;
    }
    
    // 实例化 新的下载对象
    object = [[AFDownloadObject alloc]initWithUrlString:encodedString beginRange:length withPath:directory];
    object.dataTask.taskDescription = CLFileName(URL);//键为文件名
    object.stateBlock = state;
    object.progressBlock = progress;
    object.completionBlock = completion;
    
    self.downloadsSet[object.dataTask.taskDescription] = object;
    
    // 添加到待下载列表，进行下载
    [self.waitingArray addObject:object];
    [self toDowloadNextObject];
}

#pragma mark - 下载列表数据
- (NSDictionary *)downloadObjectWithUrlString:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    return [self getOneDataWithPlist:CLFilesPlistPath urlString:encodedString];
}
- (NSArray *)downloadList {
    return [self getAllDataWithPlist:CLFilesPlistPath];
}

#pragma mark - Assist Methods
#pragma mark 可以恢复下载
- (BOOL)canBeginDownload {
    // 最大的并发下载数量，0没有限制。
    if (self.maxConcurrentCount == 0) {
        return YES;
    }
    if (self.downloadingArray.count >= self.maxConcurrentCount) {
        return NO;
    }
    return YES;
}

#pragma mark 下载下一个
- (void)toDowloadNextObject {
    if (self.waitingArray.count == 0) {
        return;
    }
    
    AFDownloadObject *object = self.waitingArray.firstObject;
    
    if ([self canBeginDownload]) {
        [self.waitingArray removeObject:object];
        [self.downloadingArray addObject:object];
        
        [object.dataTask resume];
        if (object.stateBlock) {
            object.stateBlock(CLDownloadStateRunning);
        }
    }else{
        for (AFDownloadObject *downloadObjec in self.waitingArray) {
            if (downloadObjec.stateBlock) {
                downloadObjec.stateBlock(CLDownloadStateWaiting);
            }
        }
    }
}

#pragma mark - Downloads
#pragma mark 挂起指定下载任务
- (void)suspendDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }

    if ([self.waitingArray containsObject:object]) {
        [self.waitingArray removeObject:object];
    } else {
        [object.dataTask suspend];
        [self.downloadingArray removeObject:object];
    }
    if (object.stateBlock) {
        object.stateBlock(CLDownloadStateSuspended);
    }
    
    [self toDowloadNextObject];
}

#pragma mark 挂起全部下载任务
- (void)suspendAllDownloads {
    if (self.downloadsSet.count == 0) {
        return;
    }

    if (self.waitingArray.count > 0) {
        for (AFDownloadObject *object in self.waitingArray) {
            if (object.stateBlock) {
                object.stateBlock(CLDownloadStateSuspended);
            }
        }
        [self.waitingArray removeAllObjects];
    }

    if (self.downloadingArray.count > 0) {
        for (AFDownloadObject *object in self.waitingArray) {
            [object.dataTask suspend];
            if (object.stateBlock) {
                object.stateBlock(CLDownloadStateSuspended);
            }
        }
        [self.downloadingArray removeAllObjects];
    }
}

#pragma mark 恢复指定下载任务
- (void)resumeDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }
    
    [self.waitingArray addObject:object];
    [self toDowloadNextObject];
}

#pragma mark 恢复全部下载任务
- (void)resumeAllDownloads {

    if (self.downloadsSet.count == 0) {
        return;
    }

    NSArray *downloads = self.downloadsSet.allValues;
    for (AFDownloadObject *object in downloads) {
        [self.waitingArray addObject:object];
        [self toDowloadNextObject];
    }
}

#pragma mark 删除指定下载任务
- (void)deleteDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    
    [self deleteOneWithPlist:CLFilesPlistPath urlString:urlString]; // 删除Plist数据
    [self deleteFile:urlString];                                    // 删除文件数据
    
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }
    
    [object closeOutputStream];
    [object.dataTask cancel];
    
    if (object.stateBlock) {
        object.stateBlock(CLDownloadStateCanceling);
    }
    
    // 删除保存到数据
    if ([self.waitingArray containsObject:object]) {
        [self.waitingArray removeObject:object];
    } else {
        [self.downloadingArray removeObject:object];
    }
    [self.downloadsSet removeObjectForKey:CLFileName(URL)];         // 删除集合数据
    
    [self toDowloadNextObject];
}

#pragma mark 删除全部下载任务
- (void)deleteAllDownloads {
    
    [self deleteAllWithPlist:CLFilesPlistPath];         // 删除Plist数据
    [self deleteAllFiles];                              // 删除文件数据
    
    if (self.downloadsSet.count == 0) {
        return;
    }
    
    NSArray *objects = self.downloadsSet.allValues;
    for (AFDownloadObject *object in objects) {
        [object closeOutputStream];
        [object.dataTask cancel];
        if (object.stateBlock) {
            object.stateBlock(CLDownloadStateCanceling);
        }
    }
    
    [self.waitingArray removeAllObjects];               // 删除集合数据
    [self.downloadingArray removeAllObjects];           // 删除集合数据
    [self.downloadsSet removeAllObjects];               // 删除集合数据
}

#pragma mark - Files
#pragma mark 文件缓存目录
- (NSString *)cachesDirectory {
    NSString *defaultPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:NSStringFromClass([self class])];
    return defaultPath;
}

#pragma mark 文件绝对路径
- (NSString *)fileAbsolutePath:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    return CLFilePath(URL);
}

#pragma mark 文件是否已下载
- (BOOL)isDownloadCompleted:(NSString *)urlString {
    NSInteger totalLength = [self totalLengthWithPlist:CLFilesPlistPath urlString:urlString];
    if (totalLength != 0) {
        if (totalLength == [self downloadedLength:urlString]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark 文件已经下载的大小
- (NSUInteger)downloadedLength:(NSString *)urlString {
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:[self fileAbsolutePath:urlString] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

#pragma mark 删除指定文件
- (void)deleteFile:(NSString *)urlString {
    // 绝对路径删除
    NSString *filePath = [self fileAbsolutePath:urlString];
    if (![self.fileManager fileExistsAtPath:filePath]) {
        return;
    }
    [self.fileManager removeItemAtPath:filePath error:nil];
}

#pragma mark 删除全部文件
- (void)deleteAllFiles {
    NSArray *fileNames = [self.fileManager contentsOfDirectoryAtPath:CLCachesDirectory error:nil];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [CLCachesDirectory stringByAppendingPathComponent:fileName];
        [self.fileManager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark 格式化文件大小
- (NSString *)formatByteCount:(long long)size {
    return [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}

#pragma mark 转换带特殊字符的Url
- (NSString *)encodedString:(NSString *)urlString {
    return [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];;
}

#pragma mark - Lazy Loading
#pragma mark AFURLSessionManager 请求会话
- (AFURLSessionManager *)sessionManager {
    if (!_sessionManager) {
        //默认配置
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        //AFN3.0+基于封住URLSession的句柄
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        _sessionManager = manager;
    }
    return _sessionManager;
}

@end

