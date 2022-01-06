/*==================================================================
ToolbarDelegateCategory.m : Toolbar Category Implementation File For arRsync
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

#import "ToolbarDelegateCategory.h"

@implementation MainUIController (ToolbarDelegateCategory)


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarCustomizeToolbarItemIdentifier,
				@"PresetsToggle",@"PreferencesShow",@"ResetOptions",@"ErrorLog",nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
				@"ErrorLog",
				NSToolbarFlexibleSpaceItemIdentifier, @"ResetOptions",
				@"PresetsToggle", nil];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	if ( [itemIdentifier isEqualToString:@"PreferencesShow"] ) {
			[item setLabel:@"Preferences"];
			[item setPaletteLabel:[item label]];
			[item setImage:[NSImage imageNamed:@"Prefs"]];
			//[item setTarget:preferencesWindow];
			//[item setAction:@selector(makeKeyAndOrderFront:)];
	} 
	else if ( [itemIdentifier isEqualToString:@"PresetsToggle"] ) {
			[item setLabel:@"Presets"];
			[item setPaletteLabel:[item label]];
			[item setImage:[NSImage imageNamed:@"Presets"]];
			[item setTarget:presetController];
			[item setAction:@selector(toggleDrawer:)];
	} 
	else if ( [itemIdentifier isEqualToString:@"ResetOptions"] ) {
	   	 	[item setLabel:@"Reset Options"];
	   	 	[item setPaletteLabel:[item label]];
	   	 	[item setImage:[NSImage imageNamed:@"Reset"]];
			[item setTarget: rsyncController];
			[item setAction:@selector(resetAll:)];
	}
	else if ( [itemIdentifier isEqualToString:@"ErrorLog"] ) {
   	 		[item setLabel:@"Show Error Log"];
   	 		[item setPaletteLabel:[item label]];
   	 		[item setImage:[NSImage imageNamed:@"Error"]];
			[item setTarget: errorController];
			[item setAction:@selector(showPanel:)];
	}
			
return [item autorelease];
}


- (void)setupToolbar
{
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [mainWindow setToolbar:[toolbar autorelease]];
}

- (IBAction)customiseToolbar:(id)sender 
{ 
    [toolbar runCustomizationPalette:sender]; 
}

- (IBAction)toggleToolbar:(id)sender 
{ 
    [toolbar setVisible:![toolbar isVisible]]; 
}


@end
