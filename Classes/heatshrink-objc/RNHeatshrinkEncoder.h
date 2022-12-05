//
//  RNHeatshrinkEncoder.h
//  Pods
//
//  Created by Rafael Nobre on 06/05/17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNHeatshrinkEncoder : NSObject
    
- (instancetype)initWithWindowSize:(NSInteger)windowBitSize andLookaheadSize:(NSInteger)lookaheadBitSize;
    
- (NSData *)encodeData:(NSData *)dataToEncode;

@end

NS_ASSUME_NONNULL_END
