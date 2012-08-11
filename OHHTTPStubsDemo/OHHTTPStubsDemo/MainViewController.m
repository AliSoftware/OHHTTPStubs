//
//  MainViewController.m
//  OHHTTPStubsDemo
//
//  Created by Olivier Halligon on 11/08/12.
//  Copyright (c) 2012 AliSoftware. All rights reserved.
//

#import "MainViewController.h"
#import "OHHTTPStubs.h"

@interface MainViewController(/* Private Interface */) {
    dispatch_queue_t downloadQueue;
}
- (void)configureStubs;
@end




@implementation MainViewController
@synthesize delaySwitch = _delaySwitch;
@synthesize textView = _textView;
@synthesize imageView = _imageView;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Methods

- (void)configureStubs
{
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck)
     {
         NSString* ext = request.URL.absoluteString.pathExtension;
         if ([ext isEqualToString:@"txt"])
         {
             return [OHHTTPStubsResponse responseWithFile:@"stub.txt"
                                              contentType:@"text/plain"
                                             responseTime:self.delaySwitch.on ? 2.f: 0.f];
         }
         else if ([ext isEqualToString:@"jpg"])
         {
             return [OHHTTPStubsResponse responseWithFile:@"stub.jpg"
                                              contentType:@"image/jpeg"
                                             responseTime:self.delaySwitch.on ? 2.f: 0.f];
         }
         else
         {
             return OHHTTPStubsResponseDontUseStub;
         }
     }];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        downloadQueue = dispatch_queue_create("OHHTTPStubs.example.download", NULL);
        
        // Configure your stubs
        [self configureStubs];
    }
    return self;
}

- (void)dealloc
{
    [_textView release];
    [_imageView release];
    dispatch_release(downloadQueue);
    [_delaySwitch release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setImageView:nil];
    [self setDelaySwitch:nil];
    [super viewDidUnload];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (IBAction)toggleStubs:(UISwitch *)sender
{
    [OHHTTPStubs setEnabled:sender.on];
    self.delaySwitch.enabled = sender.on;
}

- (IBAction)downloadText:(UIButton*)sender
{
    NSString* urlString = @"http://www.loremipsum.de/downloads/version3.txt";
    // Quick & Dirty way to download data without bothering with delegate implementation and such (and compatible with iOS <5.0)
    sender.enabled = NO;
    dispatch_async(downloadQueue, ^{
        NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        NSData* downloadedData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        dispatch_sync(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            self.textView.text = [[[NSString alloc] initWithData:downloadedData encoding:NSASCIIStringEncoding] autorelease];
        });
    });
}

- (IBAction)downloadImage:(UIButton*)sender
{
    NSString* urlString = @"http://images.apple.com/iphone/ios/images/ios_business_2x.jpg";
    // Quick & Dirty way to download data without bothering with delegate implementation and such (and compatible with iOS <5.0)
    sender.enabled = NO;
    dispatch_async(downloadQueue, ^{
        NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        NSData* downloadedData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        dispatch_sync(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            self.imageView.image = [UIImage imageWithData:downloadedData];
        });
    });
}

- (IBAction)clearResults
{
    self.textView.text = @"";
    self.imageView.image = nil;
}

@end
