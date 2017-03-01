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

#import "DiagnosticReportGroup.h"
#import "DiagnosticReport.h"

NS_ASSUME_NONNULL_BEGIN

@interface DiagnosticReportGroup()

@property( atomic, readwrite, strong ) NSString                             * name;
@property( atomic, readwrite, strong ) NSArray< DiagnosticReport * >        * reports;
@property( atomic, readwrite, strong ) NSMutableArray< DiagnosticReport * > * mutableReports;
@property( atomic, readwrite, strong ) NSImage                              * icon;
@property( atomic, readwrite, strong ) NSString                             * index;

@end

NS_ASSUME_NONNULL_END

@implementation DiagnosticReportGroup

- ( instancetype )init
{
    return [ self initWithName: @"" ];
}

- ( instancetype )initWithName: ( NSString * )name
{
    if( ( self = [ super init ] ) )
    {
        self.name           = name;
        self.reports        = @[];
        self.mutableReports = [ NSMutableArray new ];
    }
    
    return self;
}

- ( NSString * )description
{
    return [ NSString stringWithFormat: @"%@ %@ (%llu reports)", [ super description ], self.name, ( unsigned long long )( self.reports.count ) ];
}

- ( void )addReport: ( DiagnosticReport * )report
{
    if( self.icon == nil )
    {
        self.icon = report.icon;
    }
    
    [ self.mutableReports addObject: report ];
    
    self.reports = [ NSArray arrayWithArray: self.mutableReports ];
    
    if( self.index == nil )
    {
        self.index = report.contents;
    }
    else
    {
        self.index = [ self.index stringByAppendingString: report.contents ];
    }
}

@end
