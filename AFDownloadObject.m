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

- (instancetype)initWithUrlString:(NSString *)urlString beginRange:(NSUInteger)length withPath:(NSString *)directory {
    self = [super init];
    if (self) {
        if (!urlString) {
            return self;
        }
        self.urlString = urlString;
        self.speed = @"0bytes";
        self.directoryPath = directory;
        
        // Range
        // bytes=x-y ==  x byte ~ y byte
        // bytes=x-  ==  x byte ~ end
        // bytes=-y  ==  head ~ y byte
        NSURL *URL = [NSURL URLWithString:urlString];
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:[[AFDownloader manager] fileAbsolutePath:urlString] append:YES];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-", (long)length] forHTTPHeaderField:@"Range"];
        
        self.dataTask = [[AFDownloader manager].sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            
        }];
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
