//
//  RNHeatshrinkDecoder.m
//  Pods
//
//  Created by Rafael Nobre on 06/05/17.
//
//

#import "RNHeatshrinkDecoder.h"
#import "heatshrink/heatshrink_decoder.h"

@interface RNHeatshrinkDecoder()
    
@property (nonatomic) NSInteger inputBufferSize;
@property (nonatomic) NSInteger windowBitSize;
@property (nonatomic) NSInteger windowSize;
@property (nonatomic) NSInteger lookaheadBitSize;
@property (nonatomic) NSInteger lookaheadSize;
@property (nonatomic) heatshrink_decoder *decoder;

@end

@implementation RNHeatshrinkDecoder
    
- (instancetype)init {
    if (self = [self initWithWindowSize:10 andLookaheadSize:5]) {
        
    }
    return self;
}
    
- (instancetype)initWithWindowSize:(NSInteger)windowBitSize andLookaheadSize:(NSInteger)lookaheadBitSize {
    if (self = [self initWithBufferSize:4096 windowSize:windowBitSize andLookaheadSize:lookaheadBitSize]) {
        
    }
    return self;
}
    
- (instancetype)initWithBufferSize:(NSInteger)inputBufferSize windowSize:(NSInteger)windowBitSize andLookaheadSize:(NSInteger)lookaheadBitSize {
    if (self = [super init]) {
        _inputBufferSize = inputBufferSize;
        _windowBitSize = windowBitSize;
        _windowSize = 1 << windowBitSize;
        _lookaheadBitSize = lookaheadBitSize;
        _lookaheadSize = 1 << lookaheadBitSize;
        _decoder = heatshrink_decoder_alloc(inputBufferSize, windowBitSize, lookaheadBitSize);
    }
    return self;
}
    
static void die(NSString *message) {
    [NSException raise:@"RNHeatshrinkDieException" format:@"Reason: %@", message];
}
    
- (NSData *)decodeData:(NSData *)dataToDecode {
    NSMutableData *output = [[NSMutableData alloc] initWithCapacity:dataToDecode.length * 2];
    
    if (dataToDecode.length == 0) {
        return output;
    }
    
    heatshrink_decoder_reset(_decoder);
    
    uint8_t *data = (uint8_t*)[dataToDecode bytes];
    size_t data_sz = [dataToDecode length];
    size_t sink_sz = 0;
    size_t poll_sz = 0;
    size_t out_sz = 4096;
    uint8_t out_buf[out_sz];
    memset(out_buf, 0, out_sz);
    
    HSD_sink_res sres;
    HSD_poll_res pres;
    HSD_finish_res fres;
    
    size_t sunk = 0;

    do {
        if (sunk < data_sz) {
            sres = heatshrink_decoder_sink(_decoder, &data[sunk], data_sz - sunk, &sink_sz);
            if (sres < 0) { die(@"sink"); }
            sunk += sink_sz;
        }
        
        do {
            pres = heatshrink_decoder_poll(_decoder, out_buf, out_sz, &poll_sz);
            if (pres < 0) { die(@"poll"); }
            [output appendBytes:out_buf length:poll_sz];
        } while (pres == HSDR_POLL_MORE);
        
        if (sunk == data_sz) {
            fres = heatshrink_decoder_finish(_decoder);
            if (fres < 0) { die(@"finish"); }
            if (fres == HSDR_FINISH_DONE) { break; }
        }
        
    } while (1);
    
    return output;
}

- (void)dealloc {
    heatshrink_decoder_free(_decoder);
}

@end
