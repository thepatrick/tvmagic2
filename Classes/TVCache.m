//
//  TVCache.m
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

#import "TVCache.h"
#import "SQLDatabase.h"
#import "TVShow.h"


@implementation TVCache

@synthesize db;

+storeWithFile:(NSString*)file {
	TVCache *store = [[[self alloc] init] autorelease];
	[store openDatabase:file];
	return store;
}

-init {
	if(self = [super init]) {
		dbIsOpen = NO;
		centralShowStore = [[NSMutableDictionary dictionaryWithCapacity:500] retain];
		dbLock = [[NSLock alloc] init];
	}	
	return self;
}

-(void)dealloc {
	if(dbIsOpen) {
		[self closeDatabase];
	}
	[centralShowStore release];
	[dbLock release];
    [super dealloc];
}

-(BOOL)openDatabase:(NSString *)fileName {	
	BOOL newFile = ![[NSFileManager defaultManager] fileExistsAtPath:fileName];
	self.db = [SQLDatabase databaseWithFile:fileName];
	[db open];
	dbIsOpen = YES;
	
	if(newFile) {
		DLog(@"First run, create basic file format");
		[db performQuery:@"CREATE TABLE sync_status_and_version (last_sync datetime, version integer)"];
		[db performQuery:@"INSERT INTO sync_status_and_version VALUES (NULL, 0)"];
	}
	
	SQLResult *res = [db performQuery:@"SELECT last_sync, version FROM sync_status_and_version;"];
	SQLRow *row = [res rowAtIndex:0];
	
	NSString *version = [row stringForColumn:@"version"];
	
	
	int theVersion = [version integerValue];
	
	DLog(@"Database: Version: '%d'", theVersion);
	
	[self migrateFrom:theVersion];
	
	return YES;
}

-(void)closeDatabase {
	dbIsOpen = NO;
	[db performQuery:@"COMMIT"];
	[db close];
}

-(void)migrateFrom:(NSInteger)version
{
	if(version < 1) {
		DLog(@"Database migrating to v1...");
		[db performQuery:@"CREATE TABLE tvrage_caches (id INTEGER PRIMARY KEY, showname TEXT, tvrageid INTEGER, overridename TEXT)"];		
		[db performQuery:@"UPDATE sync_status_and_version SET version = 1"];
		DLog(@"Database migrated to v1.");
	}
}

-(NSString*)sqlStringHelper:(id)obj {
	if(!obj) return @"NULL";
	return [NSString stringWithFormat:@"'%@'", [SQLDatabase prepareStringForQuery:obj]];
}

#pragma mark -
#pragma mark Shows

-(NSInteger)insertShow:(TVShow*)show {	
	NSString *sql = [NSString stringWithFormat:@"INSERT INTO tvrage_caches (id, showname, tvrageid, overridename) VALUES (%@, %@, %d, %@)",
					 @"NULL",
					 [self sqlStringHelper:show.showname],
					 show.tvrageid,
					 [self sqlStringHelper:show.overridename]];
	
	[dbLock lock];
	[db performQuery:sql];	
	[dbLock unlock];
	
	[dbLock lock];
	SQLResult *res = [db performQueryWithFormat:@"SELECT max(id) FROM tvrage_caches"];
	if(!res) {
		[db performQuery:@"ROLLBACK"];
		DLog(@"query for tvrage_caches failed...");
	}
	SQLRow *row = [res rowAtIndex:0];
	if(!row) {
		[db performQuery:@"ROLLBACK"];
		DLog(@"query for tvrage_caches failed... (no row)");
	}
	
	NSInteger newShowID = [row integerForColumnAtIndex:0];
	DLog(@"showID: %d", newShowID);
	show.dbId = [NSNumber numberWithInteger:newShowID];
	[dbLock unlock];
	
	return newShowID;
}

-(BOOL)insertOrUpdateShow:(TVShow*)show {
	BOOL shouldInsert = (show.dbId == nil);
	
	DLog(@"Insert? %@", shouldInsert ? @"YES" : @"Update");

	if(shouldInsert) {
		[self insertShow:show];
	} else { // shouldInsert == NO.
		NSString *sql = [NSString stringWithFormat:@"UPDATE tvrage_caches SET showname = %@, tvrageid = %d, overridename = %@ WHERE id = %@",
						 [self sqlStringHelper:show.showname],
						 show.tvrageid,
						 [self sqlStringHelper:show.overridename],
						 show.dbId];
		[dbLock lock];
		[db performQuery:sql];	
		[dbLock unlock];
	}
	return shouldInsert;
}

-(void)deleteShowFromStore:(NSInteger)showId {
	[self removeShowFromCache:showId];
	[db performQueryWithFormat:@"DELETE FROM tvrage_caches WHERE id = %d", showId];
}


-(void)removeShowFromCache:(NSInteger)showId {
	[centralShowStore removeObjectForKey:[NSString stringWithFormat:@"%d", showId]];
}

-(TVShow*)getShowForName:(NSString*)showname {

	[dbLock lock];
	
	SQLResult *res = [db performQueryWithFormat:@"SELECT id FROM tvrage_caches WHERE showname = %@",
					  [self sqlStringHelper:showname]];
	
	[dbLock unlock];

	TVShow *show;
	if([res rowCount] == 0) {
		show = [TVShow showWithPrimaryKey:-1 andStore:self];
		show.showname = showname;
	} else {
		SQLRow *row = [res rowAtIndex:0];
		show = [self getShow:[row integerForColumn:@"id"]];
	}
	
	return show;
}

-(TVShow*)getShow:(NSInteger)showId {
	TVShow *theShow = [centralShowStore objectForKey:[NSString stringWithFormat:@"%d", showId]];
	if(theShow == nil) {
		NSString *theKey = [NSString stringWithFormat:@"%d", showId];
		theShow = [TVShow showWithPrimaryKey:showId andStore:self];
		[centralShowStore setObject:theShow forKey:theKey];
	}
	return theShow;
}

@end
