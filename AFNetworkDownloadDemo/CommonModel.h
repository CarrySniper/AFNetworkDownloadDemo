//
//  CommonModel.h
//  vrmu_push
//
//  Created by CJQ on 2018/1/30.
//  Copyright © 2018年 VR-MU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

#import "AFDownloader.h"

@interface CommonModel : NSObject<NSCoding, NSCopying>

@property (nonatomic, copy) NSString *urlString;

// plist自己设定的字段

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger totalLength;
@property (nonatomic, assign) NSUInteger downloadLength;
@property (nonatomic, assign) float progress;

@property (nonatomic, copy) NSString *receivedSize;
@property (nonatomic, copy) NSString *expectedSize;

@property (nonatomic, assign) CLDownloadState state;
@property (nonatomic, assign) BOOL isStop;

@end

