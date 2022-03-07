//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglSecs.m
//  mglMetal
//
//  Created by justin gardner on 1/5/20.
//  Copyright © 2020 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

#import "mglSecs.h"
#include <mach/mach.h>
#include <mach/mach_time.h>

@implementation mglSecs

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// mglSecs: get
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(double) get
{
    static const double kOneBillion = 1000 * 1000 * 1000;
    static mach_timebase_info_data_t sTimebaseInfo;

    if (sTimebaseInfo.denom == 0) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    // This seems to work on Mac OS 10.9 with a Mac PRO. But note that sTimebaseInfo is hardware implementation
    // dependent. The mach_absolute_time is ticks since the machine started and to convert it to ms you
    // multiply by the fraction in sTimebaseInfo - worried that this could possibly overflow the
    // 64 bit int values depending on what is actually returned. Maybe that is not a problem
    double currtime = ((double)((mach_absolute_time()*(uint64_t)(sTimebaseInfo.numer)/(uint64_t)(sTimebaseInfo.denom)))/kOneBillion);
    return(currtime);
}
@end
