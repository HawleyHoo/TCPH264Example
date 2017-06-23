//
//  MacroDefine.h
//  VTH264examples
//
//  Created by 胡杨 on 2017/3/7.
//  Copyright © 2017年 srd. All rights reserved.
//

#ifndef MacroDefine_h
#define MacroDefine_h

#pragma mark - Log打印[宏]
/**    Log打印[宏]   */
#ifdef  DEBUG

/// 不要直接改NSLog，有需要就自定义一个宏**Log
//#define NSLog(format, ...) printf("[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String])

#define NSLog(...) NSLog(@"%s [行数:%d] \n  %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
//NSLog(__VA_ARGS__)
#define HYLog(...) NSLog(@"HY--- %s [行数:%d] \n  %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define HYLog(...)
#define NSLog(...)
#endif

#endif /* MacroDefine_h */
