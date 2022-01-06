/*==================================================================
rsyncController.m : rsync Controller File For arRsync
Copyright (C) 2006 Adam Watkins & Miles Wu

This program is free software; you can baristribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

Any Queries please contact either:
miles[dot]wu[at]wu[hyphen]home[dot]co[dot]uk
adam[dot]gc[dot]watkins[at]gmail[dot]com
==================================================================*/

#import "rsyncController.h"
#import "unistd.h"

@implementation RsyncController : NSObject

- (RsyncController *)init
{
	termination = 0;
	self = [super init];
	files = [[NSMutableArray alloc] init];
	cmd = [[NSTask alloc] init];
	return self;
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startCmdFromNotification:) name:@"startCmd" object:nil];
}

- (void)startCmdFromNotification:(NSNotification *)notification
{
	[self startCmd];
}

- (BOOL)isReady
{
	if([[self getEnabledFiles] count] > 0)
		return true;
	else
		return false;
}

//file manipulations
- (NSMutableArray *)getEnabledFiles
{
	NSMutableArray *enabledFiles = [NSMutableArray array];
	[enabledFiles retain];
	
	int i;
	for(i=0;i<[files count];i++)
		if([[[files objectAtIndex:i] objectAtIndex:0] intValue] == 1)
			[enabledFiles addObject:[files objectAtIndex:i]];
			
	return enabledFiles;
}

- (void)removeFiles:(NSIndexSet *)rows 
{
	[files removeObjectsAtIndexes:rows];
	[mainUIController updateFileTableView];
	[mainUIController updateGoButtonState];
}

- (void)addFile:(NSMutableArray *)file
{
	[files addObject:file];
	[mainUIController updateFileTableView];
	[mainUIController updateGoButtonState];
}

- (void)toggleFileEnabledAtRow:(int)row
{	
	NSMutableArray * file = [files objectAtIndex:row];
		
	if([[file objectAtIndex:0] intValue] == 0)
		[file replaceObjectAtIndex:0 withObject:@"1"];
	else
		[file replaceObjectAtIndex:0 withObject:@"0"];
		
	[mainUIController updateFileTableView];
	[mainUIController updateGoButtonState];
}


- (NSMutableArray *)lastFile
{
	return [files lastObject];
}

//cmd manips
- (BOOL)isRunning
{
	return [cmd isRunning];
}

- (void)suspendCmd
{
	[cmd suspend];
}

- (void)resumeCmd
{
	[cmd resume];
}

- (void)stopCmd
{
	NSTask *kill = [[NSTask alloc] init];
	[kill setLaunchPath:@"/bin/kill"];
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject:@"-9"];
	[arguments addObject:[NSString stringWithFormat:@"%d", [cmd processIdentifier]]];
	[kill setArguments:arguments];
	[kill launch];
	[kill release];
	termination = 1;
}

- (void)startCmd
{
	[NSThread detachNewThreadSelector:@selector(startCmdThread:) toTarget:self withObject:nil];
}

- (void)startCmdThread:(id)somethingThatISNIL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	termination = 0;
	NSArray *enabledFiles = [self getEnabledFiles];
	int i;
	NSMutableArray *rsyncArgs = [NSMutableArray array];
	NSMutableArray * arguments = [NSMutableArray array];
	NSDictionary * userSpecifiedArgs = [mainUIController getArguments];
	
	NSMutableString *flags = [NSMutableString string];
	[flags appendString:@"-vrt"];
	if([[userSpecifiedArgs objectForKey:@"wholeFile"] intValue] == 0)
		[flags appendString:@"W"];
	if([[userSpecifiedArgs objectForKey:@"checks"] intValue] == 3)
		[flags appendString:@"I"];
	else if([[userSpecifiedArgs objectForKey:@"checks"] intValue] == 1)
		[flags appendString:@"c"];
	if([[userSpecifiedArgs objectForKey:@"attributes"] intValue] == NSOnState)
		[flags appendString:@"E"];
	if([[userSpecifiedArgs objectForKey:@"permission"] intValue] == NSOnState)
		[flags appendString:@"p"];
	if([[userSpecifiedArgs objectForKey:@"symlink"] intValue] == NSOnState)
		[flags appendString:@"l"];
	if([[userSpecifiedArgs objectForKey:@"mode"] intValue] == 0 || [[userSpecifiedArgs objectForKey:@"mode"] intValue] == 2)
		[flags appendString:@"u"];
	
	for(i=0;i < [enabledFiles count]; i++) {
		arguments = [NSMutableArray array];
		[arguments addObject:@"rsync"];
		[arguments addObject:flags];
		if([[userSpecifiedArgs objectForKey:@"mode"] intValue] == 1) //Backup only
			[arguments addObject:@"--delete"];
		[arguments addObject:[NSString stringWithFormat:@"%@/%@", [[enabledFiles objectAtIndex:i] objectAtIndex:2], [[enabledFiles objectAtIndex:i] objectAtIndex:1]]]; //src + / + file
		[arguments addObject:[NSString stringWithFormat:@"%@/",   [[enabledFiles objectAtIndex:i] objectAtIndex:3]]]; //dest + '/'
		[rsyncArgs addObject:arguments];
	}
	
	if([[userSpecifiedArgs objectForKey:@"mode"] intValue] == 0) { ///2way only
		for(i=0; i < [enabledFiles count]; i++) { //Reversing args
			arguments = [NSMutableArray array];
			[arguments addObject:@"rsync"];
			[arguments addObject:flags];
			[arguments addObject:[NSString stringWithFormat:@"%@/%@", [[enabledFiles objectAtIndex:i] objectAtIndex:3], [[enabledFiles objectAtIndex:i] objectAtIndex:1]]]; //dest + / + file
			[arguments addObject:[NSString stringWithFormat:@"%@/",   [[enabledFiles objectAtIndex:i] objectAtIndex:2]]]; //source + '/'
			[rsyncArgs addObject:arguments];
		}
	}
	
	[mainUIController rsyncJustStarted];
	
	NSMutableArray *dryargs;
	NSData *data;
	NSString *str;
	int count=0;
	for(i=0; i < [rsyncArgs count]; i++) { //Doing a dry run
		cmd = [[NSTask alloc] init];
		[cmd setLaunchPath:@"/usr/bin/env"];
		
		dryargs = [NSMutableArray arrayWithArray:[rsyncArgs objectAtIndex:i]];
		[dryargs addObject:@"-n"]; //Adding dry run
		[cmd setArguments:dryargs];
		
		cmdOutput = [NSPipe pipe];
		[cmd setStandardOutput:cmdOutput];
		[cmd launch];
		NSFileHandle *o = [cmdOutput fileHandleForReading];
		
		while(1) {
			NSAutoreleasePool *pool3 = [[NSAutoreleasePool alloc] init];
			data = [o availableData];
			if([data length]==0)
				break;
			str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
			count += [self numberOfCharactersInString:str character:'\n'];
			[str release];
			//sleep(0.1);
			[pool3 release];
		}
	}
	if(termination == 0)
		[mainUIController rsyncStarted:count];
	
	for(i=0; (i < [rsyncArgs count] && termination == 0); i++) {
		cmd = [[NSTask alloc] init];
		[cmd setLaunchPath:@"/usr/bin/env"];
		[cmd setArguments:[rsyncArgs objectAtIndex:i]];
		
		cmdOutput = [NSPipe pipe];
		cmdError = [NSPipe pipe];
		
		[cmd setStandardOutput:cmdOutput];
		[cmd setStandardError:cmdError];
		[cmd launch];
		
		[NSThread detachNewThreadSelector:@selector(updateErrors:) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(updateProgress:) toTarget:self withObject:nil];
		[cmd waitUntilExit];
	}
	if(termination == 0)
		[mainUIController rsyncFinished:count];
	[pool release];
}

- (void)updateErrors:(id)anObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSFileHandle *e = [cmdError fileHandleForReading];
	[e autorelease];
	
	NSData *data;
	NSString *newstr;
	NSMutableString *bufferstr = [NSMutableString string];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	int i;
	
	while(1) {
		data = [e availableData];
		if([data length]==0)
			break;
		newstr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
		for(i=0; i<[newstr length]; i++) {
			if([newstr characterAtIndex:i] == '\n') {
				[notificationCenter postNotificationName:@"addError" object:newstr];
				bufferstr = [NSMutableString string];
			}
			else
				[bufferstr appendFormat:@"%c", [newstr characterAtIndex:i]];
		}
		[newstr release];
	}
	[pool release];
}

- (void)updateProgress:(id)anObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSFileHandle *o = [cmdOutput fileHandleForReading];
	[o autorelease];
	
	NSData *data;
	NSString *str;
	while(1) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		data = [o availableData];
		if([data length]==0)
			break;
		str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		[mainUIController updateProgress:[self numberOfCharactersInString:str character:'\n']];
		[str release];
		sleep(0.2);
		[pool2 release];
	}
	[pool release];
}



//Random manipulations
- (int)numberOfCharactersInString:(NSString *)str character:(char)chr
{
	int i, count;
	count = 0;
	for(i=0; i<[str length]; i++)
		if([str characterAtIndex:i] == chr)
			count += 1;
	return count;
}

- (int)numberOfFilesInPath:(NSArray *)paths //This func. gets huge as there could be 250,000+ files
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *name;
	NSString *basepath;
	NSDirectoryEnumerator *direnum;
	BOOL isDir;
	int count=0;
	int i;
	for(i=0; i<[paths count]; i++) {
		direnum = [manager enumeratorAtPath:[files objectAtIndex:i]];
		basepath = [[paths objectAtIndex:i] stringByAppendingString:@"/"];
		while( name = [direnum nextObject] ) {
		//	NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
			name = [basepath stringByAppendingString:name];
			[manager fileExistsAtPath:name isDirectory:&isDir];
			if(!isDir)
				count += 1;
		//	[pool2 release];
		}
	}
	return count;
}

//presets
- (void)setFiles:(NSArray *)presetFiles
{
	[files removeAllObjects];
	
	int i;
	for(i=0;i<[presetFiles count];i++)
		[files addObject:[NSMutableArray arrayWithArray:[presetFiles objectAtIndex:i]]];
	[mainUIController updateFileTableView];
	[mainUIController updateGoButtonState];
}

- (NSMutableArray *)getFiles
{
	return files;
}

- (void)resetAll:(id)sender
{
	[files removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reset" object:nil];
	NSDictionary * defaultArgs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:1], @"mode",
		[NSNumber numberWithInt:2], @"checks",
		[NSNumber numberWithInt:0], @"permissions",
		[NSNumber numberWithInt:1], @"attributes",
		[NSNumber numberWithInt:0], @"symlinks",
		[NSNumber numberWithInt:1], @"wholeFile", nil];
	[mainUIController setArguments:defaultArgs];
	[mainUIController updateFileTableView];
	[mainUIController updateGoButtonState];
}

//TableView DataSource methods
- (int)numberOfRowsInTableView:(NSTableView *)table
{	
	return [files count];
}

- (NSString *)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	return [[files objectAtIndex: rowIndex] objectAtIndex:[[column identifier] intValue]];
}

- (NSDragOperation)tableView:(NSTableView *)table validateDrop:(id)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)table acceptDrop:(id)info row:(id)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pasteboard = [info draggingPasteboard];
	NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
	
	int i;
	for(i=0; i<[filenames count]; i++)
		[files addObject: [filenames objectAtIndex:i]];

	[mainUIController updateFileTableView];
	return true;
}



@end
