//
//  MainViewController.h
//  OHHTTPStubsDemo
//
//  Created by Olivier Halligon on 11/08/12.
//  Copyright (c) 2012 AliSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
- (IBAction)toggleStubs:(UISwitch*)sender;
- (IBAction)downloadText:(UIButton*)sender;
- (IBAction)installTextStub:(UISwitch*)sender;
- (IBAction)downloadImage:(UIButton*)sender;
- (IBAction)installImageStub:(UISwitch*)sender;
- (IBAction)clearResults;

@property (retain, nonatomic) IBOutlet UISwitch *delaySwitch;
@property (retain, nonatomic) IBOutlet UITextView *textView;
@property (retain, nonatomic) IBOutlet UISwitch *installTextStubSwitch;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UISwitch *installImageStubSwitch;
@end
