//
//  NSDateJSON.m
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

#import "NSDateJSON.h"


@implementation NSDate (NSDate_JSON)

+dateWithJSONString:(NSString*)jsonDate {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[inputFormatter setLocale: usLocale];
	[usLocale release];
	
	[inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDate *formattedDate = [inputFormatter dateFromString:jsonDate];
	
	[inputFormatter release];
	
	return formattedDate;
}


+dateWithSQLString:(NSString*)sqlDate {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[inputFormatter setLocale: usLocale];
	[usLocale release];
	
	[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	[inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDate *formattedDate = [inputFormatter dateFromString:sqlDate];
	
	[inputFormatter release];
	
	return formattedDate;	
}


-(NSString*)jsonString {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[inputFormatter setLocale: usLocale];
	[usLocale release];
	
	[inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSString *outDate = [inputFormatter stringFromDate:self];
	[inputFormatter release];
	return outDate;
}

-(NSString*)sqlDateString {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[inputFormatter setLocale: usLocale];
	[usLocale release];
	
	[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	[inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSString *outDate = [inputFormatter stringFromDate:self];
	
	[inputFormatter release];
	
	return outDate;	
}

@end
