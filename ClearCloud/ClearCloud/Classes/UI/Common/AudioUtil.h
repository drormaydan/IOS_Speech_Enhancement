//
//  AudioUtil.h
//  ClearCloud
//
//  Created by Boris Katok on 10/1/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioUtil : NSObject

- (NSString *)fixForFastPlayback:(char*)dest:(ALAsset*)selected;

@end

NS_ASSUME_NONNULL_END
