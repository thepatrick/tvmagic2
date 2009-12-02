//
//  TVMagicMain.h
//  TVMagic2
// 
// 	Copyright (c) 2009 Patrick Quinn-Graham
// 
// 	Permission is hereby granted, free of charge, to any person obtaining
// 	a copy of this software and associated documentation files (the
// 	"Software"), to deal in the Software without restriction, including
// 	without limitation the rights to use, copy, modify, merge, publish,
// 	distribute, sublicense, and/or sell copies of the Software, and to
// 	permit persons to whom the Software is furnished to do so, subject to
// 	the following conditions:
// 
// 	The above copyright notice and this permission notice shall be
// 	included in all copies or substantial portions of the Software.
// 
// 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// 	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// 	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// 	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// 	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// 	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// 	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>

@class TVCache;
@class TVRage;

@interface TVMagicMain : NSObject<NSApplicationDelegate> {

	IBOutlet NSTextField *lookForFilesIn;
	IBOutlet NSTextField *moveFilesTo;
	IBOutlet NSButton *changeLookFor;
	IBOutlet NSButton *changeMoveTo;
	IBOutlet NSButton *addToiTunes;
	IBOutlet NSButton *deleteOriginalFile;
	IBOutlet NSTextField *numberOfFiles;
	IBOutlet NSTextField *progressInfo;
	
	IBOutlet NSProgressIndicator *progressBar;
	
	IBOutlet NSButton *startProcess;
	
	IBOutlet NSWindow *window;
	
	TVCache *cache;
	TVRage *rage;
	
	BOOL currentlyWorking;
	
	NSMutableArray *singleFileWaitingList;
}

@property (nonatomic, retain) IBOutlet NSTextField *lookForFilesIn;
@property (nonatomic, retain) IBOutlet NSTextField *moveFilesTo;
@property (nonatomic, retain) IBOutlet NSButton *changeLookFor;
@property (nonatomic, retain) IBOutlet NSButton *changeMoveTo;
@property (nonatomic, retain) IBOutlet NSButton *addToiTunes;
@property (nonatomic, retain) IBOutlet NSButton *deleteOriginalFile;
@property (nonatomic, retain) IBOutlet NSTextField *numberOfFiles;
@property (nonatomic, retain) IBOutlet NSTextField *progressInfo;
@property (nonatomic, retain) IBOutlet NSButton *startProcess;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressBar;

@property (nonatomic, retain) IBOutlet NSWindow *window;

-(IBAction)changeMoveTo:(id)sender;
-(IBAction)changeLookFor:(id)sender;

-(void)transferSingleFile:(NSURL*)filePath;
-(IBAction)start:(id)sender;

-(void)runLoopKicker:(NSArray*)toDealWith;

-(NSString*)wrapThisFile:(NSString*)file;
-(NSDictionary*)standard:(NSString*)file;
-(NSDictionary*)dateBased:(NSString*)file show:(NSString*)showname guessName:(BOOL)guess;
-(void)addTVShowToiTunes:(NSDictionary*)data;
-(void)movie:(NSString*)file;

@end
