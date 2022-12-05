//
//  RNHeatshrinkEncoder.m
//  Pods
//
//  Created by Rafael Nobre on 06/05/17.
//
//

#import "RNHeatshrinkEncoder.h"
#import "heatshrink/heatshrink_encoder.h"

@interface RNHeatshrinkEncoder()
    
@property (nonatomic) NSInteger windowBitSize;
@property (nonatomic) NSInteger windowSize;
@property (nonatomic) NSInteger lookaheadBitSize;
@property (nonatomic) NSInteger lookaheadSize;
@property (nonatomic) heatshrink_encoder *encoder;
    
@end

@implementation RNHeatshrinkEncoder
    
- (instancetype)initWithWindowSize:(NSInteger)windowBitSize andLookaheadSize:(NSInteger)lookaheadBitSize {
    if (self = [super init]) {
        _windowBitSize = windowBitSize;
        _windowSize = 1 << windowBitSize;
        _lookaheadBitSize = lookaheadBitSize;
        _lookaheadSize = 1 << lookaheadBitSize;
        _encoder = heatshrink_encoder_alloc(windowBitSize, lookaheadBitSize);
        heatshrink_encoder_reset(_encoder);
    }
    return self;
}
    
- (instancetype)init {
    if (self = [self initWithWindowSize:10 andLookaheadSize:5]) {
        
    }
    return self;
}
    
static void die(NSString *message) {
    [NSException raise:@"RNHeatshrinkDieException" format:@"Reason: %@", message];
}
    
- (NSData *)encodeData:(NSData *)dataToEncode {
    NSMutableData *output = [[NSMutableData alloc] initWithCapacity:dataToEncode.length * 2];
    
    if (dataToEncode.length == 0) {
        return output;
    }
    
    heatshrink_encoder_reset(_encoder);
    
    uint8_t *data = (uint8_t*)[dataToEncode bytes];
    size_t data_sz = [dataToEncode length];
    size_t sink_sz = 0;
    size_t poll_sz = 0;
    size_t out_sz = 4096;
    uint8_t out_buf[out_sz];
    memset(out_buf, 0, out_sz);
    
    HSE_sink_res sres;
    HSE_poll_res pres;
    HSE_finish_res fres;
    
    size_t sunk = 0;
    
    do {
        if (sunk < data_sz) {
            sres = heatshrink_encoder_sink(_encoder, &data[sunk], data_sz - sunk, &sink_sz);
            if (sres < 0) { die(@"sink"); }
            sunk += sink_sz;
        }
        
        do {
            pres = heatshrink_encoder_poll(_encoder, out_buf, out_sz, &poll_sz);
            if (pres < 0) { die(@"poll"); }
            [output appendBytes:out_buf length:poll_sz];
        } while (pres == HSER_POLL_MORE);
        
        if (sunk == data_sz) {
            fres = heatshrink_encoder_finish(_encoder);
            if (fres < 0) { die(@"finish"); }
            if (fres == HSER_FINISH_DONE) { break; }
        }
        
    } while (1);
    
    return output;
}
    
    
- (void)dealloc {
    heatshrink_encoder_free(_encoder);
}

@end
