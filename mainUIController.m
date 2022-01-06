/*==================================================================
UIcontroller.m : Main Controller File For arRsync
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


#import "mainUIController.h"
#import "unistd.h"
#import "ToolbarDelegateCategory.h"

@implementation MainUIController

- (MainUIController *)init{
	self = [super init];
	panelFiles = [[NSMutableArray alloc] init];
	
	progressText = [[NSMutableString alloc] init];
	[self setValue:@"Idle" forKey:@"progressText"];
		
	[self setValue:[NSNumber numberWithInt:0] forKey:@"progressBarValue"];
	[self setValue:[NSNumber numberWithInt:100] forKey:@"progressBarMax"];
	
	[self setValue:[NSNumber numberWithInt:1] forKey:@"modePreference"];
	[self setValue:[NSNumber numberWithInt:1] forKey:@"wholeFilePreference"];
	[self setValue:[NSNumber numberWithInt:2] forKey:@"levelOfChecking"];
	
	[self setValue:[NSNumber numberWithInt:0] forKey:@"permissionsPreference"];
	[self setValue:[NSNumber numberWithInt:0] forKey:@"preserveSymlinksPreference"];
	[self setValue:[NSNumber numberWithInt:0] forKey:@"extendedAttrPreference"];
	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"extendedAttrWarning"];
	
	
	return self;
}


- (void)awakeFromNib
{
	//Add the Toolbar
	[self setupToolbar];
	
	[presetController toggleDrawer:self];
	
	//Add column of checkboxes
	NSButtonCell *cell = [[NSButtonCell alloc] init];
	[cell setButtonType:NSSwitchButton];
	[cell setTitle:@""];
	[cell setTarget:self];
	[cell setAction:@selector(fileCheckboxPressed:)];
	
	[[fileTableView tableColumnWithIdentifier:@"0"] setDataCell:cell];
	[cell release];
	
	//[fileTableView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
	
	if(UnsanitySCR_CanInstall(NULL)) {
		UnsanitySCR_Install(0);
	}
}

//Actions

- (void)fileCheckboxPressed:(id)sender
{	
	[rsyncController toggleFileEnabledAtRow:[sender clickedRow]];
}

- (IBAction)quitRequested:(id)sender
{
	if([rsyncController isRunning]) {
		NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure you wish to quit?" 
										 defaultButton: @"Continue with Sync"
									   alternateButton: @"Quit"
										   otherButton: nil
							 informativeTextWithFormat: @"A sync is currently in progress. If you quit now, the sync will not complete."];
		[alert setAlertStyle: NSCriticalAlertStyle];
    	
		[alert beginSheetModalForWindow: mainWindow
						  modalDelegate: self
						 didEndSelector: @selector(quitConfirmed:returnCode:contextInfo:)
							contextInfo: nil];
	}
	else
		[NSApp terminate:self];
}

- (IBAction)modifyFileAction:(NSButton *)sender
{
	if([sender tag]==1) {
		[fileSourceTextField setStringValue:@""];
		[panelFiles release];
		panelFiles = [[NSMutableArray alloc] init];
		[fileFileTableView reloadData];
		[self filePanelUpdateOKButton];
		
		[NSApp beginSheet:fileSheet
			modalForWindow: mainWindow
			modalDelegate:self
			didEndSelector:NULL
			contextInfo:nil];
	}
	else
		[rsyncController removeFiles:[fileTableView selectedRowIndexes]];
}


- (IBAction)goAction:(NSButton *)sender
{	
	if([[goButton title] isEqualToString:@"Run"]) {
	
		int mode = [[self valueForKey:@"modePreference"] intValue];
		NSString *mesg;
		
		if(mode == 0) //2-way
			mesg = @"Outdated files in both sources and destinations will be overwritten by their newer counterparts.";
		else if(mode == 1) //backup
			mesg = @"All changes in the backup destinations will be overwritten.";
		else if(mode == 2) //merge
			mesg = @"Outdated files in destinations will be overwritten by their new counterparts.";
		
		NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure you wish to continue with the sync?" 
										 defaultButton: @"Cancel"
									   alternateButton: @"Run Sync"
										   otherButton: nil
							 informativeTextWithFormat: mesg];
		[alert setAlertStyle: NSCriticalAlertStyle];
		[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"r"];
		[[[alert buttons] objectAtIndex:1] setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		[alert beginSheetModalForWindow: mainWindow
						  modalDelegate: self
						 didEndSelector: @selector(syncConfirmed:returnCode:contextInfo:)
							contextInfo: nil];
	}
	else {
		[rsyncController suspendCmd];
		NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure you wish to stop the sync?"
										 defaultButton: @"Continue"
									   alternateButton: @"Stop"
										   otherButton: nil
							 informativeTextWithFormat: @"The sync will be incomplete."];
		[alert setAlertStyle: NSCriticalAlertStyle];
		
		[alert beginSheetModalForWindow: mainWindow
						  modalDelegate: self
						 didEndSelector: @selector(syncTerminate:returnCode:contextInfo:)
							contextInfo: nil];
	}
}

//File Panel
- (IBAction)filePanelBrowse:(NSButton *)sender;
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setCanChooseDirectories: true];
	
	if([sender tag]==1) { //Destination
		NSString *str=nil;
		if([rsyncController lastFile]) {
			str = [[rsyncController lastFile] objectAtIndex:3]; //Gets last destination
		}
	
		[oPanel setCanChooseFiles: false];
		[oPanel setTitle:@"Choose Destination"];
		[oPanel setCanCreateDirectories:true];
		
		[oPanel beginSheetForDirectory: str
								  file: nil
								 types: nil
						modalForWindow: fileSheet
						 modalDelegate: self
						didEndSelector: @selector(filePanelChosenFile:returnCode:contextInfo:)
						   contextInfo: (void *)[sender tag]];
	}
	else { //Source
		NSString *str = [[rsyncController lastFile] objectAtIndex:2]; //Gets last source
		
		[oPanel setTitle:@"Choose Source"];
		[oPanel setAllowsMultipleSelection:true];
		
		[oPanel beginSheetForDirectory: str
								  file: nil
								 types: nil
						modalForWindow: fileSheet
						 modalDelegate: self
						didEndSelector: @selector(filePanelChosenFile:returnCode:contextInfo:)
						   contextInfo: (void *)[sender tag]];
	}
}

- (void)filePanelChosenFile:(NSOpenPanel *)oPanel returnCode:(int)code contextInfo:(int)contextInfo
{
	if(code == NSOKButton) {
		if(contextInfo == 0) { //Setting source
			NSMutableArray *pathComponents;
			[panelFiles removeAllObjects];
			int i;
			for(i=0; i<[[oPanel filenames] count]; i++) {
				pathComponents = [NSMutableArray arrayWithArray:[[[oPanel filenames] objectAtIndex:i] pathComponents]];
				[panelFiles addObject:[pathComponents lastObject]];
			}
			[fileFileTableView reloadData];
			
			[pathComponents removeLastObject];
			[pathComponents removeObjectAtIndex:0];
			[fileSourceTextField setStringValue:[@"/" stringByAppendingString:[pathComponents componentsJoinedByString:@"/"]]];
					
			if([rsyncController lastFile]) {
				[fileDestTextField setStringValue:[[rsyncController lastFile] objectAtIndex:3]];
			}
		}
		else { //Setting dest.
			[fileDestTextField setStringValue:[[oPanel filenames] objectAtIndex:0]];
		}
		[self filePanelUpdateOKButton];
	}
}

- (void)filePanelUpdateOKButton 
{
	if([[fileSourceTextField stringValue] length] > 0 && [[fileDestTextField stringValue] length] > 0 && [panelFiles count] > 0)
		[fileSaveButton setEnabled:true];
	else
		[fileSaveButton setEnabled:false];
}

- (IBAction)filePanelClosedAction:(NSButton *)sender
{
	if([sender tag]==1) {
		int i;
		for(i=0; i<[panelFiles count]; i++)
			[rsyncController addFile:[NSMutableArray arrayWithObjects:@"1", [panelFiles objectAtIndex:i], [fileSourceTextField stringValue], [fileDestTextField stringValue], nil]];
	}
    [fileSheet orderOut:self];
    [NSApp endSheet:fileSheet];
}

//Args

- (IBAction)extendedAttrVChecksum:(id)sender
{
	BOOL checkProb =  [[self valueForKey:@"extendedAttrPreference"] intValue] == 1;
	BOOL sliderProb = [[self valueForKey:@"levelOfChecking"] intValue] == 1;
	
	if([sender isKindOfClass:[NSSlider class]])
	{
		if(sliderProb)
		{
			[self setValue:[NSNumber numberWithBool:NO] forKey:@"extendedAttrWarning"];
			[self setValue:[NSNumber numberWithInt:0] forKey:@"extendedAttrPreference"];
		}
		else
			[self setValue:[NSNumber numberWithBool:YES] forKey:@"extendedAttrWarning"];
	}
	else if([sender isKindOfClass:[NSButton class]] || [sender isKindOfClass:[PresetController class]])
	{
		if(checkProb && sliderProb)
		{
			[self setValue:[NSNumber numberWithInt:2] forKey:@"levelOfChecking"];
			[self setValue:[NSNumber numberWithBool:YES] forKey:@"extendedAttrWarning"];
		}
	}		
}

- (void)setArguments:(NSDictionary *)args
{
	
	[self setValue:[args objectForKey:@"mode"] forKey:@"modePreference"];
	[self setValue:[args objectForKey:@"wholeFile"] forKey:@"wholeFilePreference"];
	
	[self setValue:[args objectForKey:@"checks"] forKey:@"levelOfChecking"];

	[self setValue:[args objectForKey:@"permissions"]  forKey:@"permissionsPreference"];
	[self setValue:[args objectForKey:@"symlinks"] forKey:@"preserveSymlinksPreference"];
	[self setValue:[args objectForKey:@"attributes"] forKey:@"extendedAttrPreference"];
	
	[self extendedAttrVChecksum:presetController];
}


- (NSDictionary *)getArguments
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict retain];
	
	[dict setValue:modePreference forKey:@"mode"];
	[dict setValue:wholeFilePreference forKey:@"wholeFile"];
	
	[dict setValue:levelOfChecking forKey:@"checks"];
	
	[dict setValue:extendedAttrPreference forKey:@"attributes"];
	[dict setValue:permissionsPreference forKey:@"permissions"];
	[dict setValue:preserveSymlinksPreference forKey:@"symlinks"];
	
	return dict;

}

//Alerts Returns
- (void)quitConfirmed:(NSAlert*)alert returnCode:(int)code contextInfo:(id)info
{
	if(code == 0) {
		[self syncTerminate:nil returnCode:0 contextInfo:nil];
		[NSApp terminate:self];
	}
	
}

- (void)syncTerminate:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)info
{
	if(code == 0) {
		[self setValue:@"Sync Interrupted" forKey:@"progressText"];
		[goButton setTitle:@"Run"];
		[progressBar setIndeterminate:true];
		[progressBar stopAnimation:self];
		[self setValue:[NSNumber numberWithInt:0] forKey:@"progressBarValue"];
		[self updateDockIcon:2 total:1];
		
		[mainWindow update];
		
		[rsyncController stopCmd];
	}
	else
		[rsyncController resumeCmd];
}

- (void)syncConfirmed:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)info
{
	if(code == 0) {
		existingErrors = [errorController numberOfErrors];
		[rsyncController startCmd];
	}
}


//Update GUI functions.

- (void)updateFileTableView
{
	[fileTableView reloadData];
}

- (void)updateGoButtonState
{
	if([rsyncController isReady])
		[goButton setEnabled:true];
	else
		[goButton setEnabled:false];
}

- (void)updateProgress:(int)noMore
{
	int numberDone = [progressBarValue intValue] + noMore;
	[self updateDockIcon:numberDone total:[progressBarMax intValue]];
	[self setValue:[NSNumber numberWithInt:numberDone] forKey:@"progressBarValue"];
}
- (void)rsyncJustStarted
{
	[self setValue:[NSNumber numberWithInt:0] forKey:@"progressBarValue"];
	[self setValue:[NSNumber numberWithInt:1] forKey:@"progressBarMax"];
	[progressBar startAnimation:self];
	[self setValue:@"Sync Starting..." forKey:@"progressText"];
	[goButton setTitle:@"Stop"];
	[mainWindow display];
}

- (void)rsyncStarted:(int)totalFiles
{
	[progressBar setIndeterminate:false];
	[self setValue:[NSNumber numberWithInt:totalFiles] forKey:@"progressBarMax"];
	[self setValue:@"Syncing..." forKey:@"progressText"];
	[mainWindow display];
}

- (void)rsyncFinished:(int)totalFiles
{
	NSAlert * alert;		
	[self setValue:@"Finished" forKey:@"progressText"];
	sleep(1);
	
	[goButton setTitle:@"Run"];
	[self updateDockIcon:2 total:1];
	[progressBar setIndeterminate:true];
	[progressBar stopAnimation:self];
	[self setValue:[NSNumber numberWithInt:0] forKey:@"progressBarValue"];
	
	[mainWindow display];

	if (([errorController numberOfErrors] - existingErrors) > 0){
		alert = [NSAlert alertWithMessageText: @"Sync Completed with Errors" 
				defaultButton: nil
				alternateButton: nil
				otherButton: nil
				informativeTextWithFormat: @"Your sync has finished but it may be incomplete. Check the error log for more details."];
	}
	else {
		alert = [NSAlert alertWithMessageText: @"Sync Completed" 
				defaultButton: nil
				alternateButton: nil
				otherButton: nil
				informativeTextWithFormat: @"Your sync has finished. Enjoy your backup."];

	}
		
	[alert beginSheetModalForWindow: mainWindow
			modalDelegate: self
			didEndSelector: nil
			contextInfo: nil];
}


/***********************************************************************
 * UpdateDockIcon - Taken from HandBrake [http://handbrake.m0k.org]
 ***********************************************************************
 * Shows a progression bar on the dock icon, filled according to
 * 'progress' (0.0 <= progress <= 1.0).
 * Called with progress < 0.0 or progress > 1.0, restores the original
 * icon.
 **********************************************************************/
- (void) updateDockIcon: (int) count total:(int)total
{
    NSImage * icon;
    NSData * tiff;
    NSBitmapImageRep * bmp;
    uint32_t * pen;
    uint32_t border = htonl( 0x111111FF );
    uint32_t bar   = htonl( 0x4775edFF);
    uint32_t background = htonl( 0xccccccFF);
    int row_start, row_end;
    int i, j;
    /* Get application original icon */
    icon = [NSImage imageNamed: @"NSApplicationIcon"];
	
	float progress = count;
	progress /= total;
	
    if( progress < 0.0 || progress > 1.0 )
    {
        [NSApp setApplicationIconImage: icon];
        return;
    }

    /* Get it in a raw bitmap form */
    tiff = [icon TIFFRepresentationUsingCompression:
            NSTIFFCompressionNone factor: 1.0];
    bmp = [NSBitmapImageRep imageRepWithData: tiff];
    
    /* Draw the progression bar */
    /* It's pretty simple (ugly?) now, but I'm no designer */

    row_start = 3 * [bmp pixelsHigh] / 4;
    row_end   = 7 * [bmp pixelsHigh] / 8;

    for( i = row_start; i < row_start + 2; i++ )
    {
        pen = (uint32_t *) ( [bmp bitmapData] + i * [bmp bytesPerRow] );
        for( j = 0; j < (int) [bmp pixelsWide]; j++ )
        {
            pen[j] = border;
        }
    }
    for( i = row_start + 2; i < row_end - 2; i++ )
    {
        pen = (uint32_t *) ( [bmp bitmapData] + i * [bmp bytesPerRow] );
        pen[0] = border;
        pen[1] = border;
        for( j = 2; j < [bmp pixelsWide] - 2; j++ )
        {
            if( j < 2 + ( ( [bmp pixelsWide] - 4.0 ) * progress ) )
            {
                pen[j] = bar;
            }
            else
            {
                pen[j] = background;
            }
        }
        pen[j]   = border;
        pen[j+1] = border;
    }
    for( i = row_end - 2; i < row_end; i++ )
    {
        pen = (uint32_t *) ( [bmp bitmapData] + i * [bmp bytesPerRow] );
        for( j = 0; j < [bmp pixelsWide]; j++ )
        {
            pen[j] = border;
        }
    }

    /* Now update the dock icon */
    tiff = [bmp TIFFRepresentationUsingCompression:
            NSTIFFCompressionNone factor: 1.0];
    icon = [[NSImage alloc] initWithData: tiff];
    [NSApp setApplicationIconImage: icon];
    [icon release];
}

//fileFileTableView datasource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [panelFiles count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn	row:(int)row{
	return [panelFiles objectAtIndex:row];
}

@end


