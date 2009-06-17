//
//  TVMagicMain.m
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

#import <QTKit/QTKit.h>

#import "TVMagicMain.h"

#import "RegexKitLite.h"
#import "TVCache.h"
#import "TVShow.h"
#import "TVRage.h"

#import "THCalendarInfo.h"

#import "iTunes.h"

@implementation TVMagicMain

@synthesize lookForFilesIn;
@synthesize moveFilesTo;
@synthesize changeLookFor;
@synthesize changeMoveTo;
@synthesize addToiTunes;
@synthesize deleteOriginalFile;
@synthesize numberOfFiles;
@synthesize progressInfo;
@synthesize startProcess;
@synthesize window;
@synthesize progressBar;

-(void)awakeFromNib {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true);
	
	NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	
	NSString *myBaseFolder = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
	
	NSFileManager *mgr = [NSFileManager defaultManager]; 
	
	BOOL isDir = NO;
	if(!([mgr fileExistsAtPath:myBaseFolder isDirectory:&isDir] && isDir)) {
		NSError *err;
		if(![mgr createDirectoryAtPath:myBaseFolder withIntermediateDirectories:YES attributes:nil error:&err]) {
			NSLog(@"Creating the directory %@ failed with error: %@", myBaseFolder, err);
		}
	}
	
	NSString *cacheFile = [myBaseFolder stringByAppendingPathComponent:@"Cache.tvmagic2"];
	
	DLog(@"cache file is: %@", cacheFile);
	cache = [[TVCache storeWithFile:cacheFile] retain];
	rage = [[TVRage alloc] init];
}

-(void)dealloc {
	[cache closeDatabase];
	[cache release];
	[rage release];
	[super dealloc];
}

-(IBAction)changeMoveTo:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose destination folder"];
	[openPanel setCanChooseFiles:NO];	
	[openPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:self.window modalDelegate:self 
					   didEndSelector:@selector(changeLookForOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:@"MoveFilesTo"];
}
-(IBAction)changeLookFor:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose source folder"];
	[openPanel setCanChooseFiles:NO];	
	[openPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:self.window modalDelegate:self 
					   didEndSelector:@selector(changeLookForOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:@"OriginalFiles"];
}

- (void)changeLookForOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if(returnCode != NSOKButton) {
		return; // don't bother with it.
	}	
	[[NSUserDefaults standardUserDefaults] setValue:[panel directory] forKey:(NSString*)contextInfo];
}	

-(IBAction)start:(id)sender {
	
	NSString *p = [[NSUserDefaults standardUserDefaults] valueForKey:@"OriginalFiles"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSError *err;	
	NSArray *arr = [fileManager contentsOfDirectoryAtPath:p error:&err];
	
	NSInteger movies = 0;
	for(NSString *file in arr) {
		
		if([[file pathExtension] isMatchedByRegex:@"(mov|avi|mp4|m4v|mkv)"]) {
			movies++;
		}
	}
	
	[numberOfFiles setTitleWithMnemonic:[NSString stringWithFormat:@"%d", movies]];
	
	[progressBar setMaxValue:movies];
	[progressBar setDoubleValue:0];
	
	[progressInfo setTitleWithMnemonic:@"Starting up..."];
	
	[self performSelectorInBackground:@selector(runLoopOfFiles:) withObject:arr];
}

-(void)runLoopOfFiles:(NSArray*)files {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[files retain];
	
	NSString *p = [[NSUserDefaults standardUserDefaults] valueForKey:@"OriginalFiles"];
	
	for(NSString *file in files) {
		if([[file pathExtension] isEqualToString:@"avi"]) {
			file = [self wrapThisFile:[p stringByAppendingPathComponent:file]];
		}
		
		if([file isMatchedByRegex:@"^The.Colbert.Report\\.[0-9]"]) {
			NSDictionary *output = [self dateBased:[p stringByAppendingPathComponent:file] show:@"The Colbert Report" guessName:NO];
			if(output) [self addTVShowToiTunes:output];
			
		} else if([file isMatchedByRegex:@"^The.Daily.Show\\.[0-9]"]) {
			NSDictionary *output = [self dateBased:[p stringByAppendingPathComponent:file] show:@"The Daily Show" guessName:NO];
			if(output) [self addTVShowToiTunes:output];
			
		} else if([file isMatchedByRegex:@"^Conan.O.Brien\\.[0-9]"]) {
			NSDictionary *output = [self dateBased:[p stringByAppendingPathComponent:file] show:@"Conan O'Brien" guessName:YES];
			if(output) [self addTVShowToiTunes:output];
			
		} else if([file isMatchedByRegex:@"^Jay.Leno\\.[0-9]"]) {
			NSDictionary *output = [self dateBased:[p stringByAppendingPathComponent:file] show:@"Jay Leno" guessName:YES];
			if(output) [self addTVShowToiTunes:output];
			
			
		// Standard TV Shows
		} else if([file isMatchedByRegex:@"[\\S\\s]([0-9]+)[Ee]([0-9]+)(.*)\\.(mov|avi|m4v|mp4)$"]) {
			NSDictionary *output = [self standard:[p stringByAppendingPathComponent:file]];
			DLog(@"Output was %@", output);
			[self addTVShowToiTunes:output];

		// Standard Movies
		} else if([file isMatchedByRegex:@"^(.*)\\.MOVIE\\.([a-zA-Z]+)\\.(m4v|mp4)$"]) {
			DLog(@"I think this is a movie");
			[self movie:[p stringByAppendingPathComponent:file]];
			
		}
		
		// Only increment the progressometer if we actually just dealt with a video
		if([[file pathExtension] isMatchedByRegex:@"(mov|avi|mp4|m4v|mkv)"]) {
			[progressBar performSelectorOnMainThread:@selector(incrementBy:) withObject:[NSNumber numberWithInteger:1] waitUntilDone:YES];
			
			NSInteger counter = [numberOfFiles integerValue];
			[numberOfFiles performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:[NSString stringWithFormat:@"%d", (counter - 1)] waitUntilDone:YES];
		}
		
	}
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Done." waitUntilDone:YES];

	[files release];
	[pool release];
	
}

-(NSString*)wrapThisFile:(NSString*)file {
	NSString *filePath = [file stringByReplacingOccurrencesOfString:@".avi" withString:@".mov"];
	NSString *outFileName = [filePath lastPathComponent];

	NSError *err = nil;
	
	NSURL *nothing = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"nothing" ofType:@"mov"]];
	QTMovie *mMovie = [[QTMovie alloc] initWithURL:nothing error:&err];
	if(err != nil) {
		NSLog(@"Failed to create qtmovie: %@", err);
		[mMovie release];
		return [file lastPathComponent];
	}
	
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Loading..." waitUntilDone:YES];
	NSURL *working = [NSURL fileURLWithPath:file];
	QTMovie *wMovie = [[QTMovie alloc] initWithURL:working error:&err];
	if(err != nil) {
		NSLog(@"Failed to create working qtmovie: %@", err);	
		[mMovie release];
		[wMovie release];
		return [file lastPathComponent];
	}
	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Merging..." waitUntilDone:YES];
	[mMovie insertSegmentOfMovie:wMovie timeRange:QTMakeTimeRange(QTZeroTime, [wMovie duration]) atTime:QTZeroTime];
	
	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Saving..." waitUntilDone:YES];
	BOOL success = [mMovie writeToFile:filePath withAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
																						   forKey:QTMovieFlatten]];
	
	if(!success)
		NSLog(@"Movie flattening failed.");
	else
		[[NSFileManager defaultManager] removeItemAtPath:file error:&err];
	
	[mMovie release];
	[wMovie release];
	return outFileName;
}

-(NSDictionary*)standard:(NSString*)file {
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Standard..." waitUntilDone:YES];

	NSString *fileMain = [file lastPathComponent];
	
	NSArray *pieces = [[fileMain arrayOfCaptureComponentsMatchedByRegex:@"(.*?)\\.[\\S\\s]([0-9]+)[Ee]([0-9]+)(.*)\\.(mov|avi|m4v|mp4)$"] objectAtIndex:0];
	
	DLog(@"Pieces are: %@", pieces); 
	
	NSString *showname = [[pieces objectAtIndex:1] stringByReplacingOccurrencesOfRegex:@"[^a-zA-Z0-9\\s]" withString:@" "];
	DLog(@"showname: %@", showname);
	NSInteger season = [[pieces objectAtIndex:2] integerValue];
	NSInteger episode = [[pieces objectAtIndex:3] integerValue];
	NSString *fileFormat = [pieces objectAtIndex:5];
	
	TVShow *show = [cache getShowForName:showname];
	if(show.dbId == nil) {
		// we need to get this from tvrage...
		DLog(@"Creating TVShow...");
	 	show.tvrageid = [rage tvrageIDForShowName:showname];
		[show save];
	} else {
		DLog(@"TVShow already existed");
	}
	
	DLog(@"Our tvshow is %@", show);

	NSMutableDictionary *ourInfo = [NSMutableDictionary dictionaryWithCapacity:10];
	
	if(show.tvrageid != -1) {
		NSDictionary *rageInfo = [rage showAndEpisodeNameForShowID:show.tvrageid season:season andEpisode:episode];	
		DLog(@"Rage Info: %@", rageInfo);
		[ourInfo setObject:[rageInfo objectForKey:@"showName"] forKey:@"showName"];
		[ourInfo setObject:[rageInfo objectForKey:@"episodeName"] forKey:@"episodeName"];
	} else {
		[ourInfo setObject:showname forKey:@"showName"];
		[ourInfo setObject:[NSString stringWithFormat:@"Episode %d", episode] forKey:@"episodeName"];
	}
	
	[ourInfo setObject:[NSNumber numberWithInteger:season] forKey:@"season"];
	[ourInfo setObject:[NSNumber numberWithInteger:episode] forKey:@"episode"];
	[ourInfo setObject:fileFormat forKey:@"format"];
	[ourInfo setObject:file forKey:@"file"];
	
	NSString *placeIn = [@"TV" stringByAppendingPathComponent:[ourInfo objectForKey:@"showName"]];
	[ourInfo setObject:[placeIn stringByAppendingPathComponent:[NSString stringWithFormat:@"Season %d", season]] forKey:@"placeIn"];
	
	return ourInfo;
}


-(NSDictionary*)dateBased:(NSString*)file show:(NSString*)showname guessName:(BOOL)guess {
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Date based..." waitUntilDone:YES];
	
	NSString *fileMain = [file lastPathComponent];
	
	NSString *fileFormat = [file pathExtension];	
	
	NSInteger year;
	NSInteger month;
	NSInteger day;
	NSString *guest;
	
	
	if([file isMatchedByRegex:@"([0-9]{4})\\.([0-9]{2})\\.([0-9]{2})"]) {
		
		//		OSX::NSLog("It's year-month-day...") unless @superDebug.nil?
		NSString *regex = @"([0-9]{4})\\.([0-9]{2})\\.([0-9]{2})[\\.]?(.*)?\\.(mov|avi|m4v|mp4)";
		
		NSArray *pieces = [[fileMain arrayOfCaptureComponentsMatchedByRegex:regex] objectAtIndex:0];
		
		year = [[pieces objectAtIndex:1] integerValue];
		month = [[pieces objectAtIndex:2] integerValue];
		day = [[pieces objectAtIndex:3] integerValue];
		
		guest = [pieces objectAtIndex:4];
		
		//		(year, month, day, guest), x = file.to_s.scan //	
		
	} else if([file isMatchedByRegex:@"([0-9]{2})\\.([0-9]{2})\\.([0-9]{4})"]) {
		//		(month, day, year, guest), x = file.to_s.scan //	
		
		NSString *regex = @"([0-9]{2})\\.([0-9]{2})\\.([0-9]{4})[\\.]?(.*)?\\.(mov|avi|m4v|mp4)";
		
		NSArray *pieces = [[fileMain arrayOfCaptureComponentsMatchedByRegex:regex] objectAtIndex:0];
		
		month = [[pieces objectAtIndex:1] integerValue];
		day = [[pieces objectAtIndex:2] integerValue];
		year = [[pieces objectAtIndex:3] integerValue];		
		guest = [pieces objectAtIndex:4];
		
	} else {
		NSLog(@"Can't handle this...");
		return nil;
	}
	
	
	NSString *episodeTitle = @"";
	
	if(guess && guest) {
		NSString *epRegex = @"(HDTV|X[vV][iI]D\\-|YesTV|MOMENTUM|BAJSKORV|LMAO|PDTV)";
		episodeTitle = [[guest stringByReplacingOccurrencesOfRegex:epRegex withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@" "];
	} else {
		THCalendarInfo *t = [THCalendarInfo calendarInfo];
		[t setCalendarDate:[NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone systemTimeZone]]];
		episodeTitle = [NSString stringWithFormat:@"%@ %d, %d", [t monthName], day, year];
	}
	
	
	NSMutableDictionary *ourInfo = [NSMutableDictionary dictionaryWithCapacity:10];
	
	[ourInfo setObject:showname forKey:@"showName"];
	[ourInfo setObject:episodeTitle forKey:@"episodeName"];
	[ourInfo setObject:[NSNumber numberWithInteger:year] forKey:@"season"];
	[ourInfo setObject:[NSNumber numberWithInteger:(month * 100) + day] forKey:@"episode"];
	[ourInfo setObject:fileFormat forKey:@"format"];
	[ourInfo setObject:file forKey:@"file"];
	
	NSString *placeIn = [[@"TV" stringByAppendingPathComponent:[ourInfo objectForKey:@"showName"]] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", year]];
	[ourInfo setObject:[placeIn stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", month]] forKey:@"placeIn"];
	
	return ourInfo;
}




-(void)movie:(NSString*)file {
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Movie..." waitUntilDone:YES];
	
	NSString *fileMain = [file lastPathComponent];
	
	NSArray *pieces = [[fileMain arrayOfCaptureComponentsMatchedByRegex:@"^(.*)\\.MOVIE\\.([a-zA-Z]+)\\.(m4v|mp4)$"] objectAtIndex:0];
	
	NSString *title = [pieces objectAtIndex:1];
	NSString *genre = [pieces objectAtIndex:2];
	NSString *extension = [pieces objectAtIndex:3];
	
	DLog(@"Pieces are: %@", pieces); 

	NSString *fileName = [NSString stringWithFormat:@"%@.%@", title, extension];

	NSError *err;
	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Moving..." waitUntilDone:YES];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	
	NSString *base = [[NSUserDefaults standardUserDefaults] valueForKey:@"MoveFilesTo"];	
	NSString *placeIn = [base stringByAppendingPathComponent:[@"Movie" stringByAppendingPathComponent:genre]];
	
	BOOL isDir = NO;
	if(!([mgr fileExistsAtPath:placeIn isDirectory:&isDir] && isDir)) {
		if(![mgr createDirectoryAtPath:placeIn withIntermediateDirectories:YES attributes:nil error:&err]) {
			NSLog(@"Creating the directory %@ failed with error: %@", placeIn, err);
			return;
		}
	}
	
	// This _NEEDS_ to replace / in the episodeName!
	NSString *finalName = [placeIn stringByAppendingPathComponent:fileName];
	
	if(![mgr moveItemAtPath:file toPath:finalName error:&err]) {
		NSLog(@"Error moving %@ to %@: %@", file, finalName, err);
		return;
	}
	
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	
	if(![iTunes isRunning]) {
		[iTunes activate];
	}
	
	DLog(@"finalName: %@", finalName);
	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"iTunes..." waitUntilDone:YES];
	
	NSURL *urlToFile = [NSURL fileURLWithPath:finalName];
	iTunesTrack *track = [iTunes add:[NSArray arrayWithObject:urlToFile] to:nil];
	
	if(!track) {
		NSLog(@"Adding the track failed... :( Trying to move the file back...");
		
		if(![mgr moveItemAtPath:finalName toPath:file error:&err]) {
			NSLog(@"Error moving %@ to %@: %@", file, finalName, err);
		} else {
			NSLog(@"Done. At least that didn't go badly as well...");
		}
		return;
	}
		
	track.name = title;
	track.genre = genre;
	track.videoKind = iTunesEVdKMovie;
	
	DLog(@"Done!");
	
}

-(void)addTVShowToiTunes:(NSDictionary*)data {
	
	NSError *err;

	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"Moving..." waitUntilDone:YES];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	
	NSString *base = [[NSUserDefaults standardUserDefaults] valueForKey:@"MoveFilesTo"];
	
	NSString *placeIn = [base stringByAppendingPathComponent:[data valueForKey:@"placeIn"]];
	
	BOOL isDir = NO;
	if(!([mgr fileExistsAtPath:placeIn isDirectory:&isDir] && isDir)) {
		if(![mgr createDirectoryAtPath:placeIn withIntermediateDirectories:YES attributes:nil error:&err]) {
			NSLog(@"Creating the directory %@ failed with error: %@", placeIn, err);
			return;
		}
	}
	
	NSNumber *season = [data objectForKey:@"season"];
	NSNumber *episode = [data objectForKey:@"episode"];
	NSString *episodeName = [data objectForKey:@"episodeName"];
	NSString *format = [data objectForKey:@"format"];
	NSString *showName = [data objectForKey:@"showName"];
	
	
	// This _NEEDS_ to replace / in the episodeName!
	NSString *fileName = [NSString stringWithFormat:@"%@ %@.%@", episode, [episodeName stringByReplacingOccurrencesOfString:@"/" withString:@" "], format];
	NSString *finalName = [placeIn stringByAppendingPathComponent:fileName];
	
	if(![mgr moveItemAtPath:[data objectForKey:@"file"] toPath:finalName error:&err]) {
		NSLog(@"Error moving %@ to %@: %@", [data objectForKey:@"file"], finalName, err);
		return;
	}
	
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	
	if(![iTunes isRunning]) {
		[iTunes activate];
	}
	
	DLog(@"finalName: %@", finalName);

	
	[progressInfo performSelectorOnMainThread:@selector(setTitleWithMnemonic:) withObject:@"iTunes..." waitUntilDone:YES];
	
	NSURL *urlToFile = [NSURL fileURLWithPath:finalName];
	iTunesTrack *track = [iTunes add:[NSArray arrayWithObject:urlToFile] to:nil];
	
	if(!track) {
		NSLog(@"Adding the track failed... :( Trying to move the file back...");
		
		if(![mgr moveItemAtPath:finalName toPath:[data objectForKey:@"file"] error:&err]) {
			NSLog(@"Error moving %@ to %@: %@", [data objectForKey:@"file"], finalName, err);
		} else {
			NSLog(@"Done. At least that didn't go badly as well...");
		}
		return;
	}
	
	track.show = showName;
	track.seasonNumber = [season integerValue];
	track.album = [NSString stringWithFormat:@"%@, Season %@", showName, season];
	
	track.name = episodeName;
	track.episodeNumber = [episode integerValue];
	track.episodeID = [NSString stringWithFormat:@"%@%@", season, episode];
	track.trackNumber = [episode integerValue];

	track.artist = showName;
	track.videoKind = iTunesEVdKTVShow;
	
	THCalendarInfo * calInfo = [THCalendarInfo calendarInfo];
	track.year = [calInfo year];
	
	DLog(@"Done!");
}

@end
