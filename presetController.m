/*==================================================================
presetController.m : Error Controller File For arRsync
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

#import "presetController.h"


@implementation PresetController : NSWindowController

- (void)awakeFromNib
{		

	userPreferences = [NSUserDefaults standardUserDefaults];
	
	if ([userPreferences objectForKey:@"lastAppVersion"] == nil){
		[userPreferences setObject:nil forKey:@"presets"];
	}
	[presetTableView reloadData];

	//Intelligent Version Checking may be needed in the future (for UserDefaults conversion)
	[userPreferences setObject:@"0.4" forKey:@"lastAppVersion"];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPresetByName:) name:@"loadPresetByName" object:nil];
}


- (BOOL)loadPresetByName:(NSNotification *)notification
{
	NSString *name = [notification object];
	NSArray *presets = [userPreferences arrayForKey:@"presets"];
	int i;
	int index = -1;
	for(i=0; i<[presets count]; i++) {
		if([[[presets objectAtIndex:i] objectForKey:@"name"] isEqualToString:name]) {
			index = i;
			break;
		}
	}
	
	if(index != -1)
	{
		[self loadPreset:index];
		return YES;
	}
	else
		return NO; 
}

- (void)loadPreset:(int)no
{
	NSDictionary *preset = [ [userPreferences arrayForKey:@"presets"] objectAtIndex:no];
	[rsyncController setFiles:[preset objectForKey:@"files"]];
	[mainUIController setArguments:[preset objectForKey:@"arguments"]];
}

- (void)savePreset:(int)row
{
	NSMutableArray *presets = [NSMutableArray arrayWithArray:[userPreferences arrayForKey:@"presets"]];
	NSMutableDictionary *preset = [NSMutableDictionary dictionary];
		
	if (row == -10)
	{
		[preset setValue:@"Untitled Preset" forKey:@"name"];
	}else if(row > -1) 
	{
		[preset setValue:[[presets objectAtIndex:row] objectForKey:@"name"] forKey:@"name"];
		[presets removeObjectAtIndex:row];
		[userPreferences setObject:presets forKey:@"presets"];		
	}
	
	
	[preset setObject:[mainUIController getArguments] forKey:@"arguments"];
	[preset setObject:[rsyncController getFiles] forKey:@"files"];
	
	[presets addObject:preset];
	[userPreferences setObject:presets forKey:@"presets"];
	[presetTableView reloadData];
		
	[presetTableView selectRow:([presets count]-1) byExtendingSelection:NO];
	
	if (row == -10)
		[presetTableView editColumn:0 row:([presets count]-1) withEvent:nil select:YES];
}

- (void)toggleDrawer:(id)sender
{
	[drawer toggle:self];
}
//Data source
- (int)numberOfRowsInTableView:(NSTableView *)table
{
	if([userPreferences objectForKey:@"presets"])
		return [[userPreferences objectForKey:@"presets"] count];
	else
		return 0;
}

- (NSString *)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	return [[[userPreferences objectForKey:@"presets"] objectAtIndex:rowIndex] objectForKey:@"name"];
}

- (void)tableView:(NSTableView *)table setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	NSMutableArray *presets = [NSMutableArray arrayWithArray:[userPreferences arrayForKey:@"presets"]];
	
	NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithDictionary:[presets objectAtIndex:rowIndex]];
	[preset setObject:value forKey:@"name"];
	
	[presets replaceObjectAtIndex:rowIndex withObject:preset];
	
	[userPreferences setObject:presets forKey:@"presets"];
	[presetTableView reloadData];
}

//Actions
- (IBAction)savePresetAction:(NSButton *)sender;
{
	[self savePreset:-10];
}

- (IBAction)overwritePresetAction:(NSButton *)sender;
{
	int row = [presetTableView selectedRow];
	if(row != -1 && [presetTableView editedColumn] == -1)
		[self savePreset:row];
}

- (IBAction)loadPresetAction:(NSButton *)sender;
{
	int row = [presetTableView selectedRow];
	if(row != -1)
		[self loadPreset:row];
}

- (IBAction)deletePresetAction:(NSButton *)sender;
{
	NSMutableArray *presets = [NSMutableArray arrayWithArray:[userPreferences arrayForKey:@"presets"]];
	int row = [presetTableView selectedRow];
	if(row != -1 && [presetTableView editedColumn] == -1)
	{
		[presets removeObjectAtIndex: [presetTableView selectedRow]];
		[userPreferences setObject:presets forKey:@"presets"];
		[presetTableView reloadData];
	}
}


@end
