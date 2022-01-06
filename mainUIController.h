/*==================================================================
UIcontroller.h : Main Controller Header File For arRsync
Copyright (C) 2006 Adam Watkins & Miles Wu

This program is free software; you can redistribute it and/or
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
#import "rsyncController.h"
#import "presetController.h"
#import "SmartCrashReportsInstall.h"

@interface MainUIController : NSWindowController {
	IBOutlet NSWindow * mainWindow;
	IBOutlet NSPanel * fileSheet;
	IBOutlet NSTableView * fileTableView;
	IBOutlet NSButton * goButton;
	IBOutlet NSProgressIndicator * progressBar;
	
	NSNumber * progressBarValue;
	NSNumber * progressBarMax;
	NSString * progressText;
	
	NSNumber * modePreference;
	NSNumber * wholeFilePreference;
	NSNumber * levelOfChecking;

	NSNumber * permissionsPreference;
	NSNumber * extendedAttrPreference;
	NSNumber * preserveSymlinksPreference;
	NSNumber * extendedAttrWarning;
	
	int existingErrors;

	IBOutlet NSTextField * fileSourceTextField;
	IBOutlet NSTextField * fileDestTextField;
	IBOutlet NSTableView * fileFileTableView;
	IBOutlet NSButton * fileSaveButton;
		
 	IBOutlet ErrorController * errorController;
	IBOutlet RsyncController * rsyncController;
	IBOutlet PresetController * presetController;
	IBOutlet id scheduleController;
	
	NSMutableArray * panelFiles;
}

//Initialisation, reading of defaults etc.
- (MainUIController *)init;
- (void)awakeFromNib;

//Update GUI
- (void)updateFileTableView;
- (void)updateGoButtonState;

- (void)updateDockIcon: (int) count total:(int)total;
- (void)updateProgress:(int) numberDone;
- (void)rsyncStarted:(int)totalFiles;
- (void)rsyncFinished:(int)totalFiles;
- (void)rsyncJustStarted;

//Alerts
- (void)syncConfirmed:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)info;
- (void)syncTerminate:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)info;
- (void)quitConfirmed:(NSAlert*)alert returnCode:(int)code contextInfo:(id)info;


- (void)fileCheckboxPressed:(id)sender;
//FileTableView data methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn	row:(int)row;

//File Panel

- (IBAction)filePanelBrowse:(NSButton *)sender;
- (IBAction)filePanelClosedAction:(NSButton *)sender;
- (void)filePanelUpdateOKButton;
- (void)filePanelChosenFile:(NSOpenPanel *)oPanel returnCode:(int)code contextInfo:(int)contextInfo;

//Arguments
- (IBAction)extendedAttrVChecksum:(id)sender;

- (NSDictionary *)getArguments;
- (void)setArguments:(NSDictionary *)args;


//Actions
- (IBAction)modifyFileAction:(NSButton *)sender;
- (IBAction)goAction:(NSButton *)sender;
- (IBAction)quitRequested:(id)sender;

@end