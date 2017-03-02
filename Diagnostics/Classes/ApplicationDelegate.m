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

#import "ApplicationDelegate.h"
#import "MainWindowController.h"
#import "AboutWindowController.h"
#import "Preferences.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApplicationDelegate()

@property( atomic, readwrite, strong ) AboutWindowController                    * aboutWindowController;
@property( atomic, readwrite, strong ) NSMutableArray< MainWindowController * > * mainWindowControllers;

- ( IBAction )showAboutWindow: ( id )sender;
- ( void )windowWillClose: ( NSNotification * )notification;

@end

NS_ASSUME_NONNULL_END

@implementation ApplicationDelegate

- ( void )applicationDidFinishLaunching: ( NSNotification * )notification
{
    ( void )notification;
    
    self.mainWindowControllers = [ NSMutableArray new ];
    
    [ [ NSNotificationCenter defaultCenter ] addObserver: self selector: @selector( windowWillClose: ) name: NSWindowWillCloseNotification object: nil ];
    [ self newDocument: nil ];
    [ Preferences sharedInstance ].lastStart = [ NSDate date ];
}

- ( void) applicationWillTerminate: ( NSNotification * )notification
{
    ( void )notification;
    
    [ [ NSNotificationCenter defaultCenter ] removeObserver: self ];
}

- ( BOOL )applicationShouldTerminateAfterLastWindowClosed: ( NSApplication * )sender
{
    ( void )sender;
    
    return NO;
}

- ( IBAction )showAboutWindow: ( id )sender
{
    if( self.aboutWindowController == nil )
    {
        self.aboutWindowController = [ AboutWindowController new ];
        
        [ self.aboutWindowController.window center ];
    }
    
    [ self.aboutWindowController.window makeKeyAndOrderFront: sender ];
}

- ( IBAction )newDocument: ( nullable id )sender
{
    MainWindowController * controller;
    
    ( void )sender;
    
    controller = [ MainWindowController new ];
    
    if( [ Preferences sharedInstance ].lastStart == nil )
    {
        [ controller.window center ];
    }
    
    [ self.mainWindowControllers addObject: controller ];
    [ controller.window makeKeyAndOrderFront: nil ];
}

- ( void )windowWillClose: ( NSNotification * )notification
{
    NSWindow             * window;
    MainWindowController * controller;
    BOOL                   found;
    
    window = notification.object;
    
    if( window == nil || [ window isKindOfClass: [ NSWindow class ] ] == NO )
    {
        return;
    }
    
    found = NO;
    
    for( controller in self.mainWindowControllers )
    {
        if( controller == window.windowController )
        {
            found = YES;
            
            break;
        }
    }
    
    if( found )
    {
        [ self.mainWindowControllers removeObject: controller ];
    }
}

@end
