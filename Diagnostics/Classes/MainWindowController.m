/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2015 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

#import "MainWindowController.h"
#import "DiagnosticReportGroup.h"
#import "DiagnosticReport.h"
#import "Preferences.h"
#import "Application.h"

@import QuickLook;
@import Quartz;

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController() < NSTableViewDelegate, NSTableViewDataSource, QLPreviewPanelDelegate, QLPreviewPanelDataSource, NSMenuDelegate >

@property( atomic, readwrite, strong )          NSArray< DiagnosticReportGroup * > * groups;
@property( atomic, readwrite, assign )          BOOL                                 editable;
@property( atomic, readwrite, assign )          BOOL                                 loading;
@property( atomic, readwrite, assign )          BOOL                                 copying;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController                  * groupController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController                  * reportsController;
@property( atomic, readwrite, strong ) IBOutlet NSTableView                        * reportsTableView;
@property( atomic, readwrite, strong ) IBOutlet NSTextView                         * textView;

- ( NSArray< DiagnosticReport * > * )clickedOrSelectedItems;

- ( IBAction )share: ( nullable id )sender;
- ( IBAction )performFindPanelAction: ( id )sender;
- ( IBAction )reload: ( nullable id )sender;
- ( IBAction )open: ( nullable id )sender;
- ( IBAction )openDocument: ( nullable id )sender;
- ( IBAction )openWithApp: ( id )sender;
- ( IBAction )openReports: ( NSArray< DiagnosticReport * > * )reports;
- ( IBAction )showInFinder: ( nullable id )sender;
- ( IBAction )saveAs: ( nullable id )sender;
- ( IBAction )saveDocument: ( nullable id )sender;
- ( IBAction )saveDocumentAs: ( nullable id )sender;
- ( IBAction )saveReports: ( NSArray< DiagnosticReport * > * )reports;
- ( IBAction )saveReports: ( NSArray< DiagnosticReport * > * )reports toURL: ( NSURL * )url;

@end

NS_ASSUME_NONNULL_END

@implementation MainWindowController

- ( instancetype )init
{
    return [ self initWithWindowNibName: NSStringFromClass( self.class ) ];
}

- ( void )windowDidLoad
{
    self.groups = @[];
    
    [ super windowDidLoad ];
    
    self.window.titlebarAppearsTransparent  = YES;
    self.window.titleVisibility             = NSWindowTitleHidden;
    self.groupController.sortDescriptors    = @[ [ NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES selector: @selector( localizedCaseInsensitiveCompare: ) ] ];
    self.reportsController.sortDescriptors  = @[ [ NSSortDescriptor sortDescriptorWithKey: @"date" ascending: NO ] ];
    self.textView.textContainerInset        = NSMakeSize( 10.0, 15.0 );
    
    {
        NSFont * font;
        
        font = [ NSFont fontWithName: @"Consolas" size: 10 ];
        
        if( font == nil )
        {
            font = [ NSFont fontWithName: @"Menlo" size: 10 ];
        }
        
        if( font == nil )
        {
            font = [ NSFont fontWithName: @"Monaco" size: 10 ];
        }
        
        if( font )
        {
            self.textView.font = font;
        }
    }
    
    [ self reload: nil ];
}

- ( NSArray< DiagnosticReport * > * )clickedOrSelectedItems;
{
    NSArray< DiagnosticReport * > * reports;
    
    if( self.reportsTableView.clickedRow >= 0 )
    {
        if( ( NSUInteger )( self.reportsTableView.clickedRow ) >= [ self.reportsController.arrangedObjects count ] )
        {
            return @[];
        }
        
        if( [ self.reportsController.selectedObjects containsObject: [ self.reportsController.arrangedObjects objectAtIndex: ( NSUInteger )( self.reportsTableView.clickedRow ) ] ] )
        {
            reports = self.reportsController.selectedObjects;
        }
        else
        {
            reports = @[ [ self.reportsController.arrangedObjects objectAtIndex: ( NSUInteger )( self.reportsTableView.clickedRow ) ] ];
        }
    }
    else
    {
        reports = self.reportsController.selectedObjects;
    }
    
    return reports;
}

- ( void )share: ( nullable id )sender
{
    NSSharingServicePicker * picker;
    NSView                 * view;
    
    ( void )sender;
    
    picker = [ [ NSSharingServicePicker alloc ] initWithItems: [ self clickedOrSelectedItems ] ];
    view   = [ self.reportsTableView viewAtColumn: self.reportsTableView.clickedColumn row: self.reportsTableView.clickedRow makeIfNecessary: NO ];
    
    [ picker showRelativeToRect: view.bounds ofView: view preferredEdge: NSRectEdgeMinY ];
}

- ( IBAction )performFindPanelAction: ( id )sender
{
    [ self.textView performTextFinderAction: sender ];
}

- ( IBAction )open: ( nullable id )sender
{
    ( void )sender;
    
    [ self openReports: [ self clickedOrSelectedItems ] ];
}

- ( IBAction )openDocument: ( nullable id )sender
{
    ( void )sender;
    
    [ self openReports: self.reportsController.selectedObjects ];
}

- ( IBAction )openWithApp: ( id )sender
{
    NSMenuItem       * item;
    Application      * app;
    DiagnosticReport * report;
    
    if( [ sender isKindOfClass: [ NSMenuItem class ] ] == NO )
    {
        return;
    }
    
    item = sender;
    
    if( [ item.representedObject isKindOfClass: [ Application class ] ]== NO )
    {
        return;
    }
    
    app = item.representedObject;
    
    for( report in [ self clickedOrSelectedItems ] )
    {
        [ app openFile: report.path ];
    }
}

- ( IBAction )openReports: ( NSArray< DiagnosticReport * > * )reports
{
    DiagnosticReport * report;
    
    for( report in reports )
    {
        [ [ NSWorkspace sharedWorkspace ] openFile: report.path ];
    }
}

- ( IBAction )showInFinder: ( nullable id )sender
{
    DiagnosticReport          * report;
    NSURL                     * url;
    NSMutableArray< NSURL * > * urls;
    
    ( void )sender;
    
    urls = [ NSMutableArray new ];
    
    for( report in [ self clickedOrSelectedItems ] )
    {
        url = [ NSURL fileURLWithPath: report.path ];
        
        if( url )
        {
            [ urls addObject: url ];
        }
    }
    
    if( urls.count )
    {
        [ [ NSWorkspace sharedWorkspace ] activateFileViewerSelectingURLs: urls ];
    }
}

- ( IBAction )saveAs: ( nullable id )sender
{
    ( void )sender;
    
    [ self saveReports: [ self clickedOrSelectedItems ] ];
}

- ( IBAction )saveDocument: ( nullable id )sender
{
    ( void )sender;
    
    [ self saveReports: self.reportsController.selectedObjects ];
}

- ( IBAction )saveDocumentAs: ( nullable id )sender
{
    ( void )sender;
    
    [ self saveReports: self.reportsController.selectedObjects ];
}

- ( IBAction )saveReports: ( NSArray< DiagnosticReport * > * )reports
{
    NSOpenPanel * panel;
    
    if( reports.count == 0 )
    {
        return;
    }
    
    panel = [ NSOpenPanel openPanel ];
    
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories    = YES;
    panel.canChooseFiles          = NO;
    panel.canCreateDirectories    = YES;
    panel.prompt                  = NSLocalizedString( @"Save", @"Confirmation buton in save dialog (choose location)" );
    
    [ panel beginSheetModalForWindow: self.window completionHandler: ^( NSInteger i )
        {
            if( i != NSFileHandlingPanelOKButton || panel.URLs.count == 0 )
            {
                return;
            }
            
            [ self saveReports: reports toURL: panel.URLs.firstObject ];
        }
    ];
}

- ( IBAction )saveReports: ( NSArray< DiagnosticReport * > * )reports toURL: ( NSURL * )url
{
    BOOL isDir;
    
    
    if( [ [ NSFileManager defaultManager ] fileExistsAtPath: url.path isDirectory: &isDir ] == NO || isDir == NO )
    {
        return;
    }
    
    self.copying = YES;
    
    dispatch_async
    (
        dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ),
        ^( void )
        {
            DiagnosticReport      * report;
            NSString              * path;
            NSError               * error;
            __block NSModalResponse r;
            __block BOOL            applyToAll;
            
            applyToAll = NO;
            r          = NSAlertSecondButtonReturn;
            
            for( report in reports )
            {
                error = nil;
                path  = [ url.path stringByAppendingPathComponent: report.path.lastPathComponent ];
                
                if( [ [ NSFileManager defaultManager ] fileExistsAtPath: path ] )
                {
                    if( applyToAll == NO )
                    {
                        dispatch_sync
                        (
                            dispatch_get_main_queue(),
                            ^( void )
                            {
                                NSAlert * alert;
                                
                                alert                        = [ NSAlert new ];
                                alert.messageText            = NSLocalizedString( @"File already exists", @"Existing file alert title" );
                                alert.informativeText        = [ NSString stringWithFormat: NSLocalizedString( @"A file named %@ already exists in the selected locaktion.", @"Existing file alert message" ), path.lastPathComponent ];
                                
                                [ alert addButtonWithTitle: NSLocalizedString( @"Replace", @"Replace button in existing file alert" ) ];
                                [ alert addButtonWithTitle: NSLocalizedString( @"Skip",    @"Skip button in existing file alert" ) ];
                                [ alert addButtonWithTitle: NSLocalizedString( @"Stop",    @"Stop button in existing file alert" ) ];
                                
                                alert.accessoryView = [ NSButton checkboxWithTitle: NSLocalizedString( @"Apply to All", @"Checkbox in existing file alert" ) target: nil action: NULL ];
                                
                                r          = [ alert runModal ];
                                applyToAll = ( ( ( NSButton *)( alert.accessoryView ) ).integerValue ) ? YES : NO;
                            }
                        );
                    }
                    
                    if( r == NSAlertFirstButtonReturn )
                    {
                        [ [ NSFileManager defaultManager ] removeItemAtPath: path error: &error ];
                        
                        if( error )
                        {
                            dispatch_sync
                            (
                                dispatch_get_main_queue(),
                                ^( void )
                                {
                                    NSAlert * alert;
                                    
                                    alert = [ NSAlert alertWithError: error ];
                                    
                                    [ alert runModal ];
                                }
                            );
                            
                            goto end;
                        }
                    }
                    else if( r == NSAlertSecondButtonReturn )
                    {
                        continue;
                    }
                    else
                    {
                        goto end;
                    }
                }
                
                [ [ NSFileManager defaultManager ] copyItemAtPath: report.path toPath: path error: &error ];
                
                if( error == nil )
                {
                    continue;
                }
                
                dispatch_sync
                (
                    dispatch_get_main_queue(),
                    ^( void )
                    {
                        NSAlert * alert;
                        
                        alert = [ NSAlert alertWithError: error ];
                        
                        [ alert runModal ];
                    }
                );
                
                goto end;
            }
            
            end:
                
                dispatch_after
                (
                    dispatch_time( DISPATCH_TIME_NOW, ( int64_t )( 1 * NSEC_PER_SEC ) ),
                    dispatch_get_main_queue(),
                    ^( void )
                    {
                        self.copying = NO;
                    }
                );
        }
    );
}

- ( IBAction )reload: ( nullable id )sender
{
    ( void )sender;
    
    if( self.loading )
    {
        return;
    }
    
    self.loading = YES;
    
    [ self.groupController removeObjects: self.groups ];
    
    dispatch_async
    (
        dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ),
        ^( void )
        {
            NSMutableDictionary< NSString *, DiagnosticReportGroup * > * groups;
            __block DiagnosticReport                                   * report;
            DiagnosticReportGroup                                      * group;
            
            groups = [ NSMutableDictionary new ];
            
            for( report in [ DiagnosticReport availableReports ] )
            {
                group = groups[ report.process ];
                
                if( group == nil )
                {
                    group = [ [ DiagnosticReportGroup alloc ] initWithName: report.process ];
                    
                    [ groups setObject: group forKey: report.process ];
                }
                
                [ group addReport: report ];
            }
            
            dispatch_sync
            (
                dispatch_get_main_queue(),
                ^( void )
                {
                    NSString * key;
                    
                    for( key in groups )
                    {
                        [ self.groupController addObject: groups[ key ] ];
                    }
                    
                    self.loading = NO;
                }
            );
        }
    );
}

- ( BOOL )validateMenuItem: ( NSMenuItem * )item
{
    if( item.action == @selector( reload: ) )
    {
        return self.loading == NO;
    }
    
    if
    (
           item.action == @selector( open: )
        || item.action == @selector( openWithApp: )
        || item.action == @selector( showInFinder: )
        || item.action == @selector( saveAs: )
        || item.action == @selector( share: )
    )
    {
        return self.reportsTableView.clickedRow >= 0;
    }
    
    if
    (
           item.action == @selector( saveDocument: )
        || item.action == @selector( saveDocumentAs: )
        || item.action == @selector( openDocument: )
    )
    {
        return self.reportsController.selectedObjects.count > 0;
    }
    
    return NO;
}

#pragma mark - QuickLook

- ( BOOL )acceptsPreviewPanelControl: ( QLPreviewPanel * )panel
{
    ( void )panel;
    
    return self.reportsController.selectedObjects.count > 0;
}

- ( void )beginPreviewPanelControl: ( QLPreviewPanel * )panel
{
    panel.delegate   = self;
    panel.dataSource = self;
}

- ( void )endPreviewPanelControl: ( QLPreviewPanel * )panel
{
    panel.delegate   = nil;
    panel.dataSource = nil;
}

#pragma mark - QLPreviewPanelDataSource

- ( NSInteger )numberOfPreviewItemsInPreviewPanel: ( QLPreviewPanel * )panel;
{
    ( void )panel;
    
    return ( NSInteger )( self.reportsController.selectedObjects.count );
}

- ( id < QLPreviewItem > )previewPanel: ( QLPreviewPanel * )panel previewItemAtIndex: ( NSInteger )index
{
    ( void )panel;
    
    @try
    {
        return [ self.reportsController.selectedObjects objectAtIndex: ( NSUInteger )index ];
    }
    @catch( NSException * e )
    {
        ( void )e;
    }
    
    return nil;
}

#pragma mark - NSMenuController

- ( void )menuWillOpen: ( NSMenu * )menu
{
    NSMenuItem  * item;
    Application * console;
    NSMenuItem  * consoleItem;
    
    for( item in menu.itemArray )
    {
        if( item.tag == 1 )
        {
            item.submenu = [ Application applicationsMenuForFileExtension: @"txt" target: self action: @selector( openWithApp: ) ];
            console      = [ Application applicationWithPath: @"/Applications/Utilities/Console.app" ];
            
            if( console )
            {
                consoleItem                   = [ [ NSMenuItem alloc ] initWithTitle: [ NSString stringWithFormat: @"%@ (%@)", console.name, console.version ] action: @selector( openWithApp: ) keyEquivalent: @"" ];
                consoleItem.image             = console.icon;
                consoleItem.target            = self;
                consoleItem.representedObject = console;
                
                [ item.submenu insertItem: consoleItem atIndex: 0 ];
                [ item.submenu insertItem: [ NSMenuItem separatorItem ] atIndex: 1 ];
            }
        }
    }
}

#pragma mark - NSTableViewDelegate

- ( BOOL )tableView: ( NSTableView * )tableView shouldTypeSelectForEvent: ( NSEvent * )event withCurrentSearchString: ( NSString * )searchString
{
    ( void )tableView;
    
    if( searchString.length == 0 && [ [ event charactersIgnoringModifiers ] isEqualToString: @" " ] == YES )
    {
        if( [ QLPreviewPanel sharedPreviewPanelExists ] && [ [ QLPreviewPanel sharedPreviewPanel ] isVisible ] )
        {
            [ [ QLPreviewPanel sharedPreviewPanel ] orderOut: nil ];
        }
        else
        {
            [ [ QLPreviewPanel sharedPreviewPanel ] center ];
            [ [ QLPreviewPanel sharedPreviewPanel ] updateController ];
            [ [ QLPreviewPanel sharedPreviewPanel ] makeKeyAndOrderFront: nil ];
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - NSTableViewDataSource

- ( BOOL )tableView: ( NSTableView * )tableView writeRowsWithIndexes: ( NSIndexSet * )rowIndexes toPasteboard: ( NSPasteboard * )pasteboard
{
    NSString                      * ext;
    DiagnosticReport              * item;
    NSArray< DiagnosticReport * > * items;
    NSMutableArray< NSString * >  * extensions;
    NSMutableArray< NSString * >  * contents;
    
    if( tableView != self.reportsTableView )
    {
        return NO;
    }
    
    [ tableView setDraggingSourceOperationMask: NSDragOperationCopy forLocal: NO ];
    
    items      = [ self.reportsController.arrangedObjects objectsAtIndexes: rowIndexes ];
    extensions = [ NSMutableArray new ];
    contents   = [ NSMutableArray new ];
    
    for( item in items )
    {
        ext = item.path.pathExtension;
        
        if( ext == nil )
        {
            ext = @"";
        }
        
        [ extensions addObject: ext ];
        [ contents   addObject: item.contents ];
    }
    
    if( extensions.count )
    {
        [ pasteboard setPropertyList: extensions forType: NSFilesPromisePboardType ];
        [ pasteboard setString: [ contents componentsJoinedByString: @"\n\n--------------------------------------------------------------------------------\n\n" ] forType: NSStringPboardType ];
        
        return YES;
    }
    
    return NO;
}

- ( NSArray< NSString * > * )tableView: ( NSTableView * )tableView namesOfPromisedFilesDroppedAtDestination: ( NSURL * )dropDestination forDraggedRowsWithIndexes: ( NSIndexSet * )indexSet
{
    NSArray< DiagnosticReport * > * items;
    
    if( tableView != self.reportsTableView )
    {
        return @[];
    }
    
    items = [ self.reportsController.arrangedObjects objectsAtIndexes: indexSet ];
    
    [ self saveReports: items toURL: ( dropDestination ) ];
    
    return @[];
}

@end
