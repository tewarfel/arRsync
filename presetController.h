/*==================================================================
presetController.h : Preset Controller Header For arRsync
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
#import "rsyncController.h"
#import "mainUIController.h"

@interface PresetController : NSWindowController {
	
	IBOutlet RsyncController * rsyncController;
	IBOutlet NSTableView * presetTableView;
	IBOutlet MainUIController * mainUIController;
	
	IBOutlet NSDrawer * drawer;	
	
	NSUserDefaults * userPreferences;
}

- (void)awakeFromNib;

- (void)savePreset:(int)row;
- (void)loadPreset:(int)no;
- (BOOL)loadPresetByName:(NSNotification *)notification;

- (void)toggleDrawer:(id)sender;

//Actions
- (IBAction)savePresetAction:(NSButton *)sender;
- (IBAction)overwritePresetAction:(NSButton *)sender;
- (IBAction)loadPresetAction:(NSButton *)sender;
- (IBAction)deletePresetAction:(NSButton *)sender;

//Data source
- (int)numberOfRowsInTableView:(NSTableView *)table;
- (NSString *)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex;
- (void)tableView:(NSTableView *)table setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)rowIndex;

@end
