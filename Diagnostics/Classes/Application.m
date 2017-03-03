/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2015 Jean-David Gadina - www-xs-labs.com
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

#import "Application.h"

@import ApplicationServices;

NS_ASSUME_NONNULL_BEGIN

@interface Application()

@property( atomic, readwrite, strong ) NSString * name;
@property( atomic, readwrite, strong ) NSURL    * url;
@property( atomic, readwrite, strong ) NSString * path;
@property( atomic, readwrite, strong ) NSImage  * icon;
@property( atomic, readwrite, strong ) NSString * bundleIdentifier;
@property( atomic, readwrite, strong ) NSString * version;

@end

NS_ASSUME_NONNULL_END

@implementation Application

+ ( NSArray * )applicationsForFile: ( NSString * )path
{
    return [ Application applicationsForFileExtension: path.pathExtension ];
}

+ ( NSArray * )applicationsForFileExtension: ( NSString * )ext
{
    NSArray      * urls;
    NSURL        * url;
    NSString     * tmp;
    char         * s;
    NSMutableSet * apps;
    Application  * app;
    
    tmp = [ NSString stringWithFormat: @"%@XXXXXX.%@", NSTemporaryDirectory(), ext ];
    s   = calloc( 1, tmp.length + 1 );
    
    strlcpy( s, tmp.UTF8String, tmp.length + 1 );
    mkstemps( s, 7 );
    
    tmp = [ NSString stringWithCString: s encoding: NSUTF8StringEncoding ];
    
    free( s );
    
    [ [ NSFileManager defaultManager ] createFileAtPath: tmp contents: nil attributes: nil ];
    
    url    = [ NSURL fileURLWithPath: tmp ];
    urls   = CFBridgingRelease( LSCopyApplicationURLsForURL( ( __bridge  CFURLRef )url, ( LSRolesMask )( kLSRolesViewer | kLSRolesEditor ) ) );
    apps   = [ NSMutableSet setWithCapacity: urls.count ];
    urls   = [ [ NSSet setWithArray: urls ] allObjects ];
    
    for( url in urls )
    {
        app = [ self applicationWithURL: url ];
        
        if( app != nil )
        {
            [ apps addObject: app ];
        }
    }
    
    [ [ NSFileManager defaultManager ] removeItemAtPath: tmp error: NULL ];
    
    return [ [ apps allObjects ] sortedArrayUsingComparator: ^ NSComparisonResult ( id obj1, id obj2 )
        {
            Application * app1;
            Application * app2;
            
            app1 = ( Application * )obj1;
            app2 = ( Application * )obj2;
            
            return [ app1.name compare: app2.name ];
        }
    ];
}

+ ( NSMenu * )applicationsMenuForFile: ( NSString * )path target: ( id )target action: ( SEL )action
{
    return [ Application applicationsMenuForFileExtension: path.pathExtension target: target action: action ];
}

+ ( NSMenu * )applicationsMenuForFileExtension: ( NSString * )ext target: ( id )target action: ( SEL )action
{
    NSMenu      * menu;
    NSArray     * apps;
    Application * app;
    NSString    * title;
    NSMenuItem  * item;
    NSImage     * image;
    
    apps = [ Application applicationsForFileExtension: ext ];
    menu = [ [ NSMenu alloc ] initWithTitle: @"" ];
    
    if( apps.count == 0 )
    {
        return menu;
    }
    
    for( app in apps )
    {
        if( app.version.length > 0 )
        {
            title = [ NSString stringWithFormat: @"%@ (%@)", app.name, app.version ];
        }
        else
        {
            title = app.name;
        }
        
        item                   = [ [ NSMenuItem alloc ] initWithTitle: title action: action keyEquivalent: @"" ];
        item.representedObject = app;
        item.target            = target;
        
        image       = app.icon;
        image.size  = NSMakeSize( 24.0, 24.0 );
        item.image  = image;
        
        [ menu addItem: item ];
    }
    
    return menu;
}

+ ( nullable instancetype )applicationWithPath: ( NSString * )path
{
    return [ [ self alloc ] initWithPath: path ];
}

+ ( nullable instancetype )applicationWithURL: ( NSURL * )url
{
    return [ [ self alloc ] initWithURL: url ];
}

- ( nullable instancetype )initWithPath: ( NSString * )path
{
    return [ self initWithURL: [ NSURL fileURLWithPath: path ] ];
}

- ( nullable instancetype )initWithURL: ( NSURL * )url
{
    BOOL       dir;
    NSBundle * bundle;
    NSString * path;
    
    if( ( self = [ self init ] ) )
    {
        dir  = NO;
        path = url.path;
        
        if( path == nil || [ [ NSFileManager defaultManager ] fileExistsAtPath: path isDirectory: &dir ] == NO || dir == NO )
        {
            return nil;
        }
        
        self.path               = url.path;
        self.url                = url;
        self.name               = [ [ NSFileManager defaultManager ] displayNameAtPath: self.path ];
        self.icon               = [ [ NSWorkspace sharedWorkspace ] iconForFile: self.path ];
        bundle                  = [ NSBundle bundleWithPath: self.path ];
        self.bundleIdentifier   = [ bundle bundleIdentifier ];
        self.version            = [ [ bundle infoDictionary ] objectForKey: @"CFBundleShortVersionString" ];
    }
    
    return self;
}

- ( void )open
{
    [ [ NSWorkspace sharedWorkspace ] launchApplication: self.path ];
}

- ( void )openFile: ( NSString * )path
{
    [ [ NSWorkspace sharedWorkspace ] openFile: path withApplication: self.path ];
}

- ( NSString * )description
{
    return [ NSString stringWithFormat: @"%@ %@ (%@)", [ super description ], self.name, [ self.path stringByDeletingLastPathComponent ] ];
}

@end
