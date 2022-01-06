/*==================================================================
rsyncController.h : rsync Controller Header For arRsync
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

#import "header.h"
#import "errorController.h"
#import "mainUIController.h"

@interface RsyncController : NSObject {
	
	IBOutlet MainUIController * mainUIController;
	
	int termination;
	
	NSTask * cmd;
	NSPipe * cmdOutput;
	NSPipe * cmdError;
	
	NSMutableArray * args;
	NSMutableArray * files;
	NSString * backupLocation;
}

- (RsyncController *)init;
- (void)awakeFromNib;
- (BOOL)isReady;

//Manipulations on files
- (NSMutableArray *)getEnabledFiles;
- (void)removeFiles:(NSIndexSet *)rows;
- (void)addFile:(NSMutableArray *)file;
- (void)toggleFileEnabledAtRow:(int)row;
- (NSMutableArray *)lastFile;

//cmd manip
- (BOOL)isRunning;
- (void)suspendCmd;
- (void)resumeCmd;
- (void)stopCmd;
- (void)startCmd;
- (void)startCmdThread:(id)somethingThatISNIL;

//progress
- (void)updateErrors:(id)anObject;
- (void)updateProgress:(id)anObject;

//Stuff
- (int)numberOfCharactersInString:(NSString *)str character:(char)chr;
- (int)numberOfFilesInPath:(NSArray *)paths;

//presets
- (void)setFiles:(NSArray *)files;
- (void)resetAll:(id)sender;
- (NSMutableArray *)getFiles;

//NSTableView stuff  (at some point a seperate data source should be used)
- (int)numberOfRowsInTableView:(NSTableView *)table;
- (NSString *)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)table acceptDrop:(id)info row:(id)row dropOperation:(NSTableViewDropOperation)operation;
- (NSDragOperation)tableView:(NSTableView *)table validateDrop:(id)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;

@end
