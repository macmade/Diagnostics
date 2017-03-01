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

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface CrashReport: NSObject

@property( atomic, readonly           ) NSString * path;
@property( atomic, readonly           ) NSData   * data;
@property( atomic, readonly           ) NSString * contents;
@property( atomic, readonly, nullable ) NSString * process;
@property( atomic, readonly           ) NSUInteger pid;
@property( atomic, readonly           ) NSUInteger uid;
@property( atomic, readonly, nullable ) NSString * version;
@property( atomic, readonly, nullable ) NSDate   * date;
@property( atomic, readonly, nullable ) NSString * processPath;
@property( atomic, readonly, nullable ) NSString * osVersion;
@property( atomic, readonly, nullable ) NSString * codeType;
@property( atomic, readonly, nullable ) NSString * exceptionType;
@property( atomic, readonly, nullable ) NSImage  * icon;

+ ( NSArray< CrashReport * > * )availableReports;

@end

NS_ASSUME_NONNULL_END
