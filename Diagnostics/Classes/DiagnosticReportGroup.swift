/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
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

import Cocoa

@objc class DiagnosticReportGroup: NSObject
{
    @objc public private( set ) dynamic var name:    String
    @objc public private( set ) dynamic var reports: [ DiagnosticReport ] = []
    @objc public private( set ) dynamic var icon:    NSImage?
    @objc public private( set ) dynamic var index:   NSString?
    
    @objc init( name: String )
    {
        self.name = name
    }
    
    @objc public override var description: String
    {
        return String( format: "%@ %@ (%@ reports)", super.description, self.name, String( self.reports.count ) )
    }
    
    @objc public func addReport( _ report: DiagnosticReport ) -> Void
    {
        if( self.icon == nil )
        {
            self.icon = report.icon
        }
        
        self.reports.append( report )
        
        let text   = ( self.index as String? ?? "" ) + report.contents
        let words  = text.split( separator: " " )
        let unique = Set( words )
        
        DispatchQueue.main.async
        {
            self.index = unique.joined( separator: " " ) as NSString
        }
    }
}
