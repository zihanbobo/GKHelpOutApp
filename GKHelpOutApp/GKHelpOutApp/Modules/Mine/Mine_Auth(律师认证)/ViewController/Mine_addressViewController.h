//
//  Mine_addressViewController.h
//  GKHelpOutApp
//
//  Created by 狂生烈徒 on 2019/3/4.
//  Copyright © 2019年 kky. All rights reserved.
//

#import "ViewController.h"
typedef void (^ReturnBlock) (NSDictionary *dictionaryValue);

@interface Mine_addressViewController : RootViewController
@property(nonatomic, copy) ReturnBlock returnValueBlock;
@end
