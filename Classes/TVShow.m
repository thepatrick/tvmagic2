//
//  TVShow.m
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

#import "SQLDatabase.h"
#import "TVCache.h"

#import "TVShow.h"


@implementation TVShow

@synthesize dbId;
@synthesize showname;
@synthesize tvrageid;
@synthesize overridename;
@synthesize store;

+show
{
	return [[[self alloc] init] autorelease];	
}


+showWithPrimaryKey:(NSInteger)theID andStore:(TVCache*)newStore {
	return [[[self alloc] initWithPrimaryKey:theID andStore:newStore] autorelease];
}

-initWithPrimaryKey:(NSInteger)theID andStore:(TVCache*)newStore {
	if(self = [super init]) {
		dirty = NO;
		hydrated = NO;
		if(theID != -1)
			dbId = [[NSNumber numberWithInteger:theID] retain];
		store = [newStore retain];
	}
	[self hydrate];
	return self;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ID: '%@'. Name: '%@'.", [self class], self.dbId, self.showname];
}

-hydrate
{
	if(self.dbId == nil || hydrated) {
		return self; // we're not going to hydrate in this situation, it's unncessary!
	}
	
	SQLResult *res = [store.db performQueryWithFormat:@"SELECT * FROM tvrage_caches WHERE id = %d", [self.dbId integerValue]];
	if([res rowCount] == 0) {
		NSLog(@"Didn't hydrate because the select returned 0 results, sql was %@", [NSString stringWithFormat:@"SELECT * FROM tvrage_caches WHERE id = %@", self.dbId]);
		return self; // bugger.
	}
	
	SQLRow *row = [res rowAtIndex:0];
	
	self.showname = [row stringForColumn:@"showname"];
	self.tvrageid = [[row stringForColumn:@"tvrageid"] integerValue];
	self.overridename = [row stringForColumn:@"overridename"];
	
	hydrated = YES;
	return self;
}

-(void)dehydrate
{
	if(!hydrated) return; // no point wasting time
	
	if(self.dbId == nil) {
		return; // we're not going to dehydrate in this situation, it's unpossible!
	}
	
	[self save];
	
	[showname release];
	showname = nil;
	[overridename release];
	overridename = nil;
	
	hydrated = NO;
}

-(void)save
{
	if(dirty) {
		DLog(@"it's dirty, so save using store %@", store);
		[store insertOrUpdateShow:self];
		dirty = NO;
	} else {
		DLog(@"we're not marked as dirty, so don't save.");
	}
}

-(void)setShowname:(NSString*)newValue
{
	[showname release];
	showname = [newValue copy];
	dirty = YES;	
}

-(void)setTvrageid:(NSInteger)newValue
{
	if(tvrageid == newValue) 
		return;
	tvrageid = newValue;
	dirty = YES;	
}

-(void)setOverridename:(NSString*)newValue
{
	[overridename release];
	overridename = [newValue copy];
	dirty = YES;	
}

@end
