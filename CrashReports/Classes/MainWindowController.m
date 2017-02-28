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
#import "CrashReportGroup.h"
#import "CrashReport.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController()

@property( atomic, readwrite, strong ) NSArray< CrashReportGroup * > * groups;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController    * groupController;

- ( void )load;

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
    
    dispatch_async
    (
        dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ),
        ^( void )
        {
            [ self load ];
        }
    );
}

- ( void )load
{
    NSMutableDictionary< NSString *, NSMutableArray< CrashReport * > * > * groups;
    CrashReport                                                          * report;
    NSMutableArray< CrashReport * >                                      * reports;
    NSString                                                             * key;
    CrashReportGroup                                                     * group;
    
    dispatch_sync
    (
        dispatch_get_main_queue(),
        ^( void )
        {
            [ self.groupController removeObjects: self.groups ];
        }
    );
    
    groups = [ NSMutableDictionary new ];
    
    for( report in [ CrashReport availableReports ] )
    {
        reports = groups[ report.process ];
        
        if( reports == nil )
        {
            reports = [ NSMutableArray new ];
            
            [ groups setObject: reports forKey: report.process ];
        }
        
        [ reports addObject: report ];
    }
    
    for( key in groups )
    {
        group = [ [ CrashReportGroup alloc ] initWithName: key ];
        
        for( report in groups[ key ] )
        {
            [ group addCrashReport: report ];
        }
        
        dispatch_sync
        (
            dispatch_get_main_queue(),
            ^( void )
            {
                [ self.groupController addObject: group ];
            }
        );
    }
}

@end
