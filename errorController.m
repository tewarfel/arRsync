/*==================================================================
errorController.m : Error Controller File For arRsync
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

#import "errorController.h"


@implementation ErrorController : NSWindowController

- (ErrorController *)init
{
	self = [super init];
	errorsArray = [[NSMutableArray alloc] init];
	return self;
}


- (void)awakeFromNib
{
	NSNotificationCenter * nCenter = [NSNotificationCenter defaultCenter];
	[nCenter addObserver:self selector:@selector(addError:) name:@"addError" object:nil];
	[nCenter addObserver:self selector:@selector(reset:) name:@"reset" object:nil];
}

- (void)showPanel:(id)sender
{
	[mainWindow makeKeyAndOrderFront:self];
}

- (void)reset:(NSNotification *)notification
{
	[errorsArray removeAllObjects];
	[errorTableView reloadData];
}

- (void)addError:(NSNotification *)notification
{
	[errorsArray addObject:[notification object]];
	[errorTableView reloadData];
}

- (int)numberOfErrors
{
	return [errorsArray count];
}

- (int)numberOfRowsInTableView:(NSTableView *)table
{
	return [errorsArray count];
}
- (NSString *)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	return [errorsArray objectAtIndex:rowIndex];
}

@end
