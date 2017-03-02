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

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController()

@property( atomic, readwrite, strong )          NSArray< DiagnosticReportGroup * > * groups;
@property( atomic, readwrite, assign )          BOOL                                 editable;
@property( atomic, readwrite, assign )          BOOL                                 loading;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController                  * groupController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController                  * reportsController;
@property( atomic, readwrite, strong ) IBOutlet NSTextView                         * textView;

- ( IBAction )performFindPanelAction: ( id )sender;
- ( IBAction )reload: ( nullable id )sender;

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

- ( IBAction )performFindPanelAction: ( id )sender
{
    [ self.textView performTextFinderAction: sender ];
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
            NSMutableDictionary< NSString *, NSMutableArray< DiagnosticReport * > * > * groups;
            __block DiagnosticReport                                                  * report;
            NSMutableArray< DiagnosticReport * >                                      * reports;
            
            groups = [ NSMutableDictionary new ];
            
            for( report in [ DiagnosticReport availableReports ] )
            {
                reports = groups[ report.process ];
                
                if( reports == nil )
                {
                    reports = [ NSMutableArray new ];
                    
                    [ groups setObject: reports forKey: report.process ];
                }
                
                [ reports addObject: report ];
            }
            
            dispatch_sync
            (
                dispatch_get_main_queue(),
                ^( void )
                {
                    NSString              * key;
                    DiagnosticReportGroup * group;
                    
                    for( key in groups )
                    {
                        group = [ [ DiagnosticReportGroup alloc ] initWithName: key ];
                        
                        for( report in groups[ key ] )
                        {
                            [ group addReport: report ];
                        }
                        
                        [ self.groupController addObject: group ];
                    }
                    
                    self.loading = NO;
                }
            );
        }
    );
}

@end
