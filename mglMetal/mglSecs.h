//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglSecs.h
//  mglMetal
//
//  Created by justin gardner on 1/5/20.
//  Copyright © 2020 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// class which returns a double that reprsesent
// the same value that mglGetSecs returns in matlab
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@interface mglSecs : NSObject
-(double) get;
@end

NS_ASSUME_NONNULL_END
