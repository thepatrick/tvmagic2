//
//  TVRage.m
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
#import "TVRage.h"


@implementation TVRage


-(NSString*)stringForFirstTag:(NSString*)tag fromElement:(NSXMLElement*)el {
	return [[[[el elementsForName:tag] objectAtIndex:0] childAtIndex:0] stringValue];	
}

-(NSInteger)tvrageIDForShowName:(NSString*)showName {
	NSString *showNameURL = [showName stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
	NSString *urlString = [@"http://services.tvrage.com/feeds/search.php?show=" stringByAppendingString:showNameURL];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSError *err = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&err] autorelease];
	if(err != nil) {
		NSLog(@"NSXMLDocument failed to initialise because of %@", err);
		return -1;
	}
	
	NSArray *shows = [[doc rootElement] elementsForName:@"show"];	

	if([shows count] == 0) {
		NSLog(@"No shows returned");
		return -1;
	}
	
	NSXMLElement *show = [shows objectAtIndex:0];
	NSInteger actualShowID = [[self stringForFirstTag:@"showid" fromElement:show] integerValue];

	DLog(@"ShowID is: %d", actualShowID);
	
	return actualShowID;
}


-(NSDictionary*)showAndEpisodeNameForShowID:(NSInteger)showID season:(NSInteger)season andEpisode:(NSInteger)episode {
	
	NSString *episodeName = [NSString stringWithFormat:@"Episode %d", episode];
	
	NSString *showIDURL = [NSString stringWithFormat:@"%d", showID];
	NSString *urlString = [@"http://services.tvrage.com/feeds/episode_list.php?sid=" stringByAppendingString:showIDURL];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSError *err = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&err] autorelease];
	if(err != nil) {
		NSLog(@"NSXMLDocument failed to initialise because of %@", err);
		return nil;
	}
	
	NSXMLElement *root = [doc rootElement];
	
	// get what we think the show name is.
	NSString *showName = [self stringForFirstTag:@"name" fromElement:root];
	
	DLog(@"I think the show is called %@", showName);
	
	err = nil;
	
	// get the season
	NSString *xp = [NSString stringWithFormat:@"Episodelist/Season[@no=%d]", season];
	NSArray *theSeasons = [root nodesForXPath:xp error:&err];
	if(err != nil) {
		NSLog(@"nodesForXPath failed with: %@", err);
		return [NSDictionary dictionaryWithObjectsAndKeys:episodeName, @"episodeName",
				showName, @"showName", nil];
	}
	
	if([theSeasons count] == 0) {
		NSLog(@"nodesForXPath failed because no seaons for season %d were found ", season);
		return [NSDictionary dictionaryWithObjectsAndKeys:episodeName, @"episodeName",
				showName, @"showName", nil];
	}
	
	NSXMLElement *theSeason = [theSeasons objectAtIndex:0];
		
	// find the episode in the list
	for (NSXMLElement *anEpisode in [theSeason elementsForName:@"episode"]) {
		NSInteger thisEpNum = [[self stringForFirstTag:@"seasonnum" fromElement:anEpisode] integerValue];
		if(thisEpNum == episode) {
			episodeName = [self stringForFirstTag:@"title" fromElement:anEpisode];
			break;
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:episodeName, @"episodeName",
				showName, @"showName", nil];
}

@end
