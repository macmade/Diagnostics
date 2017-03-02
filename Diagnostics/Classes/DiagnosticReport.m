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

#import "DiagnosticReport.h"

NS_ASSUME_NONNULL_BEGIN

@interface DiagnosticReport()

@property( atomic, readwrite, assign           ) DiagnosticReportType type;
@property( atomic, readwrite, strong           ) NSString           * path;
@property( atomic, readwrite, strong           ) NSData             * data;
@property( atomic, readwrite, strong           ) NSString           * contents;
@property( atomic, readwrite, strong, nullable ) NSString           * process;
@property( atomic, readwrite, assign           ) NSUInteger           pid;
@property( atomic, readwrite, strong, nullable ) NSNumber           * pidNumber;
@property( atomic, readwrite, strong, nullable ) NSString           * pidString;
@property( atomic, readwrite, assign           ) NSUInteger           uid;
@property( atomic, readwrite, strong, nullable ) NSNumber           * uidNumber;
@property( atomic, readwrite, strong, nullable ) NSString           * uidString;
@property( atomic, readwrite, strong, nullable ) NSString           * version;
@property( atomic, readwrite, strong, nullable ) NSDate             * date;
@property( atomic, readwrite, strong, nullable ) NSString           * processPath;
@property( atomic, readwrite, strong, nullable ) NSString           * osVersion;
@property( atomic, readwrite, strong, nullable ) NSString           * codeType;
@property( atomic, readwrite, strong, nullable ) NSString           * exceptionType;
@property( atomic, readwrite, strong, nullable ) NSImage            * icon;

+ ( NSArray< DiagnosticReport * > * )availableReportsInDirectory: ( NSString * )dir;

- ( nullable instancetype )initWithPath: ( NSString * )path;
- ( BOOL )parseContents;
- ( nullable NSArray< NSString * > * )matchesInString: ( NSString * )str withExpression: ( NSString * )expr numberOfCaptures: ( NSUInteger )n;

@end

NS_ASSUME_NONNULL_END

@implementation DiagnosticReport

+ ( NSArray< DiagnosticReport * > * )availableReports
{
    NSString                             * dir;
    NSMutableArray< DiagnosticReport * > * reports;
    
    reports = [ NSMutableArray new ];
    
    {
        dir = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, YES ).firstObject;
        
        if( dir == nil || dir.length == 0 )
        {
            return @[];
        }
        
        dir = [ dir stringByAppendingPathComponent: @"Logs" ];
        dir = [ dir stringByAppendingPathComponent: @"DiagnosticReports" ];
        
        [ reports addObjectsFromArray: [ self availableReportsInDirectory: dir ] ];
    }
    
    {
        dir = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSLocalDomainMask, YES ).firstObject;
        
        if( dir == nil || dir.length == 0 )
        {
            return @[];
        }
        
        dir = [ dir stringByAppendingPathComponent: @"Logs" ];
        dir = [ dir stringByAppendingPathComponent: @"DiagnosticReports" ];
        
        [ reports addObjectsFromArray: [ self availableReportsInDirectory: dir ] ];
    }
    
    return [ NSArray arrayWithArray: reports ];
}

+ ( NSArray< DiagnosticReport * > * )availableReportsInDirectory: ( NSString * )dir
{
    NSString                             * path;
    BOOL                                   isDir;
    NSMutableArray< DiagnosticReport * > * reports;
    NSDirectoryEnumerator                * enumerator;
    DiagnosticReport                     * report;
    
    if( [ [ NSFileManager defaultManager ] fileExistsAtPath: dir isDirectory: &isDir ] == NO || isDir == NO )
    {
        return @[];
    }
    
    reports    = [ NSMutableArray new ];
    enumerator = [ [ NSFileManager defaultManager ] enumeratorAtPath: dir ];
    
    while( path = [ enumerator nextObject ] )
    {
        [ enumerator skipDescendants ];
        
        path   = [ dir stringByAppendingPathComponent: path ];
        report = [ [ DiagnosticReport alloc ] initWithPath: path ];
        
        if( report != nil )
        {
            [ reports addObject: report ];
        }
    }
    
    return [ NSArray arrayWithArray: reports ];
}

- ( nullable instancetype )initWithPath: ( NSString * )path
{
    BOOL                 isDir;
    NSData             * data;
    DiagnosticReportType type;
    
    if( [ [ NSFileManager defaultManager ] fileExistsAtPath: path isDirectory: &isDir ] == NO || isDir == YES )
    {
        return nil;
    }
    
    if( [ path.pathExtension isEqualToString: @"crash" ] )
    {
        type = DiagnosticReportTypeCrash;
    }
    else if( [ path.pathExtension isEqualToString: @"spin" ] )
    {
        type = DiagnosticReportTypeSpin;
    }
    else if( [ path.pathExtension isEqualToString: @"diag" ] )
    {
        type = DiagnosticReportTypeHang;
    }
    else if( [ path.pathExtension isEqualToString: @"hang" ] )
    {
        type = DiagnosticReportTypeDiag;
    }
    else
    {
        return nil;
    }
    
    data = [ [ NSFileManager defaultManager ] contentsAtPath: path ];
    
    if( data == nil || data.length == 0 )
    {
        return nil;
    }
    
    if( ( self = [ self init ] ) )
    {
        self.type     = type;
        self.path     = path;
        self.data     = data;
        self.contents = [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ];
        
        if( self.contents == nil || self.contents.length == 0 )
        {
            return nil;
        }
        
        if( [ self parseContents ] == NO || self.process == nil )
        {
            return nil;
        }
        
        if( self.version.length == 0 )
        {
            self.version = @"--";
        }
        
        if( self.osVersion.length == 0 )
        {
            self.osVersion = @"--";
        }
        
        if( self.codeType.length == 0 )
        {
            self.codeType = @"--";
        }
        
        if( self.exceptionType.length == 0 )
        {
            self.exceptionType = @"--";
        }
        
        if( self.pidString.length == 0 )
        {
            self.pidString = @"--";
        }
        
        if( self.uidString.length == 0 )
        {
            self.uidString = @"--";
        }
        
        if( self.processPath.length > 0 )
        {
            if( [ self.processPath rangeOfString: @".app/Contents/MacOS" ].location != NSNotFound )
            {
                @try
                {
                    {
                        NSString * app;
                        
                        app = [ self.processPath substringWithRange: NSMakeRange( 0, [ self.processPath rangeOfString: @".app/Contents/MacOS" ].location + 4 ) ];
                        
                        if( app.length > 0 )
                        {
                            self.icon = [ [ NSWorkspace sharedWorkspace ] iconForFile: app ];
                        }
                    }
                }
                @catch( NSException * e )
                {
                    ( void )e;
                }
            }
            
            if( self.icon == nil )
            {
                self.icon = [ [ NSWorkspace sharedWorkspace ] iconForFile: self.processPath ];
            }
        }
        else
        {
            self.icon = [ [ NSWorkspace sharedWorkspace ] iconForFile: @"/bin/ls" ];
        }
    }
    
    return self;
}

- ( NSString * )description
{
    return [ NSString stringWithFormat: @"%@ %@ %@ %@", [ super description ], self.process, self.typeString, self.date ];
}

- ( NSString * )typeString
{
    switch( self.type )
    {
        case DiagnosticReportTypeUnknown: return @"Unknown";
        case DiagnosticReportTypeCrash:   return @"Crash";
        case DiagnosticReportTypeSpin:    return @"Spin";
        case DiagnosticReportTypeHang:    return @"Hang";
        case DiagnosticReportTypeDiag:    return @"Diagnostic";
    }
}

- ( BOOL )parseContents
{
    NSArray< NSString * > * lines;
    NSString              * line;
    NSArray< NSString * > * matches;
    
    lines = [ self.contents componentsSeparatedByString: @"\n" ];
    
    @try
    {
        for( line in lines )
        {
            if( [ line hasPrefix: @"Process:" ] )
            {
                matches        = [ self matchesInString: line withExpression: @"Process:\\s+([^\\[]+)\\[([0-9]+)\\]" numberOfCaptures: 2 ];
                self.process   = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                self.pid       = ( NSUInteger )( [ matches objectAtIndex: 1 ].integerValue );
                self.pidNumber = [ NSNumber numberWithUnsignedInteger: self.pid ];
                self.pidString = [ NSString stringWithFormat: @"%llu", ( unsigned long long )( self.pid ) ];
                
                if( self.process == nil || self.process.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"Command:" ] )
            {
                matches      = [ self matchesInString: line withExpression: @"Command:\\s+(.*)" numberOfCaptures: 1 ];
                self.process = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.process == nil || self.process.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"Version:" ] )
            {
                matches      = [ self matchesInString: line withExpression: @"Version:\\s+(.*)" numberOfCaptures: 1 ];
                self.version = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.version == nil || self.version.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"OS Version:" ] )
            {
                matches        = [ self matchesInString: line withExpression: @"OS Version:\\s+(.*)" numberOfCaptures: 1 ];
                self.osVersion = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.osVersion == nil || self.osVersion.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"Code Type:" ] )
            {
                matches       = [ self matchesInString: line withExpression: @"Code Type:\\s+(.*)" numberOfCaptures: 1 ];
                self.codeType = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.codeType == nil || self.codeType.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"Exception Type:" ] )
            {
                matches            = [ self matchesInString: line withExpression: @"Exception Type:\\s+(.*)" numberOfCaptures: 1 ];
                self.exceptionType = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.exceptionType == nil || self.exceptionType.length == 0 )
                {
                    return NO;
                }
            }
            else if( [ line hasPrefix: @"User ID:" ] )
            {
                matches        = [ self matchesInString: line withExpression: @"User ID:\\s+([0-9]+)" numberOfCaptures: 1 ];
                self.uid       = ( NSUInteger )( [ matches objectAtIndex: 0 ].integerValue );
                self.uidNumber = [ NSNumber numberWithUnsignedInteger: self.uid ];
                self.uidString = [ NSString stringWithFormat: @"%llu", ( unsigned long long )( self.uid ) ];
            }
            else if( [ line hasPrefix: @"Date/Time:" ] )
            {
                {
                    NSString        * str;
                    NSDateFormatter * fmt;
                    
                    matches = [ self matchesInString: line withExpression: @"Date/Time:\\s+(.*)" numberOfCaptures: 1 ];
                    str     = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                    
                    if( str == nil || str.length == 0 )
                    {
                        return NO;
                    }
                    
                    fmt            = [ NSDateFormatter new ];
                    fmt.locale     = [ NSLocale localeWithLocaleIdentifier: @"" ];
                    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS ZZZ";
                    self.date      = [ fmt dateFromString: str ];
                    
                    if( self.date == nil )
                    {
                        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
                        self.date      = [ fmt dateFromString: str ];
                        
                        if( self.date == nil )
                        {
                            return NO;
                        }
                    }
                }
            }
            else if( [ line hasPrefix: @"Path:" ] )
            {
                matches          = [ self matchesInString: line withExpression: @"Path:\\s+(.*)" numberOfCaptures: 1 ];
                self.processPath = [ [ matches objectAtIndex: 0 ] stringByTrimmingCharactersInSet: [ NSCharacterSet whitespaceCharacterSet ] ];
                
                if( self.processPath == nil || self.processPath.length == 0 )
                {
                    return NO;
                }
            }
        }
    }
    @catch( NSException * e )
    {
        return NO;
    }
    
    return YES;
}

- ( nullable NSArray< NSString * > * )matchesInString: ( NSString * )str withExpression: ( NSString * )expr numberOfCaptures: ( NSUInteger )n
{
    NSRegularExpression  * regexp;
    NSError              * error;
    NSTextCheckingResult * res;
    NSMutableArray       * matches;
    NSUInteger             i;
    NSRange                r;
    NSString             * match;
    
    if( str.length == 0 || expr.length == 0 || n == 0 )
    {
        return nil;
    }
    
    error  = nil;
    regexp = [ NSRegularExpression regularExpressionWithPattern: expr options: NSRegularExpressionCaseInsensitive error: &error ];
    
    if( regexp == nil || error != nil )
    {
        return nil;
    }
    
    res = [ regexp matchesInString: str options: NSMatchingReportCompletion range: NSMakeRange( 0, str.length ) ].firstObject;
    
    if( res == nil || res.numberOfRanges != n + 1 )
    {
        return nil;
    }
    
    matches = [ NSMutableArray new ];
    
    for( i = 1; i < res.numberOfRanges; i++ )
    {
        r = [ res rangeAtIndex: i ];
        
        match = [ str substringWithRange: r ];
        
        if( match != nil )
        {
            [ matches addObject: match ];
        }
    }
    
    return [ NSArray arrayWithArray: matches ];
}

@end
