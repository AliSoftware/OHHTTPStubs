//
//  MainViewController.m
//  OHHTTPStubsDemo
//
//  Created by Olivier Halligon on 11/08/12.
//  Copyright (c) 2012 AliSoftware. All rights reserved.
//

#import "MainViewController.h"
#import <OHHTTPStubs/OHHTTPStubs.h>


@implementation MainViewController
// IBOutlets
@synthesize delaySwitch = _delaySwitch;
@synthesize textView = _textView;
@synthesize installTextStubSwitch = _installTextStubSwitch;
@synthesize installImageStubSwitch = _installImageStubSwitch;
@synthesize imageView = _imageView;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc

- (void)dealloc
{
#if ! __has_feature(objc_arc)
    [_textView release];
    [_imageView release];
    [_delaySwitch release];
    [_installTextStubSwitch release];
    [_installImageStubSwitch release];
    [super dealloc];
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self installTextStub:self.installTextStubSwitch];
    [self installImageStub:self.installImageStubSwitch];
}
- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setImageView:nil];
    [self setDelaySwitch:nil];
    [super viewDidUnload];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Global stubs activation

- (IBAction)toggleStubs:(UISwitch *)sender
{
    [OHHTTPStubs setEnabled:sender.on];
    self.delaySwitch.enabled = sender.on;
    self.installTextStubSwitch.enabled = sender.on;
    self.installImageStubSwitch.enabled = sender.on;
}




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Text Download and Stub


- (IBAction)downloadText:(UIButton*)sender
{
    sender.enabled = NO;

    NSString* urlString = @"http://www.loremipsum.de/downloads/version3.txt";
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // This is a very handy way to send an asynchronous method, but only available in iOS5+
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         sender.enabled = YES;
         NSString* receivedText = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
         self.textView.text = receivedText;
#if ! __has_feature(objc_arc)
         [receivedText release];
#endif
     }];
}




- (IBAction)installTextStub:(UISwitch *)sender
{
    static id textHandler = nil; // Note: no need to retain this value, it is retained by the OHHTTPStubs itself already :)
    
    if (sender.on)
    {
        // Install
        textHandler = [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            // This handler will only configure stub requests for "*.txt" files
            return [request.URL.absoluteString.pathExtension isEqualToString:@"txt"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            // Stub txt files with this
            return [OHHTTPStubsResponse responseWithFile:@"stub.txt"
                                             contentType:@"text/plain"
                                            responseTime:self.delaySwitch.on ? 2.f: 0.f];
        }];
    }
    else
    {
        // Uninstall
        [OHHTTPStubs removeRequestHandler:textHandler];
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image Download and Stub

- (IBAction)downloadImage:(UIButton*)sender
{
    sender.enabled = NO;
    
    NSString* urlString = @"http://images.apple.com/iphone/ios/images/ios_business_2x.jpg";
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // This is a very handy way to send an asynchronous method, but only available in iOS5+
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         sender.enabled = YES;
         self.imageView.image = [UIImage imageWithData:data];
     }];
}

- (IBAction)installImageStub:(UISwitch *)sender
{
    static id imageHandler = nil; // Note: no need to retain this value, it is retained by the OHHTTPStubs itself already :)
    if (sender.on)
    {
        // Install
        imageHandler = [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            // This handler will only configure stub requests for "*.jpg" files
            return [request.URL.absoluteString.pathExtension isEqualToString:@"jpg"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            // Stub jpg files with this
            return [OHHTTPStubsResponse responseWithFile:@"stub.jpg"
                                             contentType:@"image/jpeg"
                                            responseTime:self.delaySwitch.on ? 2.f: 0.f];
        }];
    }
    else
    {
        // Uninstall
        [OHHTTPStubs removeRequestHandler:imageHandler];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cleaning

- (IBAction)clearResults
{
    self.textView.text = @"";
    self.imageView.image = nil;
}

@end
