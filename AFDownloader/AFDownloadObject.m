//
//  AFDownloadObject.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloadObject.h"
#import "AFDownloader.h"

@implementation AFDownloadObject

- (instancetype)initWithUrlString:(NSString *)urlString beginRange:(NSUInteger)length directoryPath:(NSString *)directoryPath {
    self = [super init];
    if (self) {
        if (!urlString) {
            return self;
        }
        self.urlString = urlString;
        self.speed = @"0bytes";
        self.directoryPath = directoryPath;
        
        // Range
        // bytes=x-y ==  x byte ~ y byte
        // bytes=x-  ==  x byte ~ end
        // bytes=-y  ==  head ~ y byte
		NSString *filePath = [[AFDownloader manager] fileAbsolutePath:urlString];
		if (directoryPath) {// 替换存放地址
			filePath = [directoryPath stringByAppendingPathComponent:[filePath lastPathComponent]];
		}
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
		
		NSURL *URL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-", (long)length] forHTTPHeaderField:@"Range"];
        // 下载任务，不在此回调，交给AFDownloader sessionManager处理
        self.dataTask = [[AFDownloader manager].sessionManager dataTaskWithRequest:request
                                                                    uploadProgress:nil
                                                                  downloadProgress:nil
                                                                 completionHandler:nil];
    }
    return self;
}

#pragma mark - 保存文件
- (void)openOutputStream {
    
    if (!_outputStream) {
        return;
    }
    [_outputStream open];
}

- (void)closeOutputStream {
    
    if (!_outputStream) {
        return;
    }
    if (_outputStream.streamStatus > NSStreamStatusNotOpen &&
        _outputStream.streamStatus < NSStreamStatusClosed) {
        [_outputStream close];
    }
    _outputStream = nil;
}

@end
