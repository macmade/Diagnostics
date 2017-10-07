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
import Quartz

@objc public class DiagnosticReport: NSObject, NSPasteboardWriting, QLPreviewItem
{
    @objc public enum Kind: Int
    {
        case Unknown
        case Crash
        case Spin
        case Hang
        case Diag
    }
    
    @objc public private( set ) dynamic var type:           Kind   = .Unknown
    @objc public private( set ) dynamic var path:           String = ""
    @objc public private( set ) dynamic var data:           Data   = Data()
    @objc public private( set ) dynamic var contents:       String = ""
    @objc public private( set ) dynamic var pid:            UInt   = 0
    @objc public private( set ) dynamic var uid:            UInt   = 0
    @objc public private( set ) dynamic var process:        String = ""
    @objc public private( set ) dynamic var pidNumber:      NSNumber?
    @objc public private( set ) dynamic var uidNumber:      NSNumber?
    @objc public private( set ) dynamic var pidString:      String?
    @objc public private( set ) dynamic var uidString:      String?
    @objc public private( set ) dynamic var version:        String?
    @objc public private( set ) dynamic var date:           Date?
    @objc public private( set ) dynamic var processPath:    String?
    @objc public private( set ) dynamic var osVersion:      String?
    @objc public private( set ) dynamic var codeType:       String?
    @objc public private( set ) dynamic var exceptionType:  String?
    @objc public private( set ) dynamic var icon:           NSImage?
    
    private static let dateFormatter1: DateFormatter =
    {
        let fmt = DateFormatter()
        
        fmt.locale     = Locale( identifier: "" )
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZ";
        
        return fmt
    }()
    
    private static let dateFormatter2: DateFormatter =
    {
        let fmt = DateFormatter()
        
        fmt.locale     = Locale( identifier: "" )
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ";
        
        return fmt
    }()
    
    @objc public static func availableReports() -> [ DiagnosticReport ]
    {
        return availableReports( nil )
    }
    
    @objc @discardableResult public static func availableReports( _ newReport: ( ( DiagnosticReport ) -> Void )? ) -> [ DiagnosticReport ]
    {
        var reports = [ DiagnosticReport ]()
        var user    = NSSearchPathForDirectoriesInDomains( .libraryDirectory, .userDomainMask,  true ).first
        var local   = NSSearchPathForDirectoriesInDomains( .libraryDirectory, .localDomainMask, true ).first
        
        if( user != nil )
        {
            user = ( user! as NSString ).appendingPathComponent( "Logs" )
            user = ( user! as NSString ).appendingPathComponent( "DiagnosticReports" )
        
            reports.append( contentsOf: DiagnosticReport.availableReports( in: user!, newReport: newReport ) )
        }
        
        if( user != nil )
        {
            local = ( local! as NSString ).appendingPathComponent( "Logs" )
            local = ( local! as NSString ).appendingPathComponent( "DiagnosticReports" )
        
            reports.append( contentsOf: DiagnosticReport.availableReports( in: local!, newReport: newReport ) )
        }
        
        return reports;
    }
    
    @objc public static func availableReports( in directory: String, newReport: ( ( DiagnosticReport ) -> Void )? ) -> [ DiagnosticReport ]
    {
        var isDir: ObjCBool = false
        
        if( FileManager.default.fileExists( atPath: directory, isDirectory: &isDir ) == false || isDir.boolValue == false )
        {
            return []
        }
        
        guard let enumerator = FileManager.default.enumerator( atPath:  directory ) else
        {
            return []
        }
        
        var reports = [ DiagnosticReport ]()
        
        while var path = enumerator.nextObject()
        {
            enumerator.skipDescendants()
            
            path = ( directory as NSString ).appendingPathComponent( path as! String )
            
            guard let report = DiagnosticReport( path: path as! String ) else
            {
                continue;
            }
            
            reports.append( report )
            newReport?( report )
        }
        
        return reports
    }
    
    public init?( path: String )
    {
        var isDir: ObjCBool = false
        var type:  Kind
        
        if( FileManager.default.fileExists( atPath: path, isDirectory: &isDir ) == false || isDir.boolValue == true )
        {
            return nil
        }
        
        if( ( path as NSString ).pathExtension == "crash" )
        {
            type = .Crash
        }
        else if( ( path as NSString ).pathExtension == "spin" )
        {
            type = .Spin
        }
        else if( ( path as NSString ).pathExtension == "hang" )
        {
            type = .Hang
        }
        else if( ( path as NSString ).pathExtension == "diag" )
        {
            type = .Diag
        }
        else
        {
            return nil
        }
        
        guard let data = FileManager.default.contents( atPath: path ) else
        {
            return nil
        }
        
        guard let contents = String( data: data, encoding: .utf8 ) else
        {
            return nil
        }
        
        super.init()
        
        self.type     = type
        self.path     = path
        self.data     = data
        self.contents = contents
        
        if( self.parseContents() == false )
        {
            return nil
        }
        
        if( ( self.version ?? "" ).count == 0 )
        {
            self.version = "--"
        }
        
        if( ( self.osVersion ?? "" ).count == 0 )
        {
            self.osVersion = "--"
        }
        
        if( ( self.codeType ?? "" ).count == 0 )
        {
            self.codeType = "--"
        }
        
        if( ( self.exceptionType ?? "" ).count == 0 )
        {
            self.exceptionType = "--"
        }
        
        if( ( self.pidString ?? "" ).count == 0 )
        {
            self.pidString = "--"
        }
        
        if( ( self.uidString ?? "" ).count == 0 )
        {
            self.uidString = "--"
        }
        
        if( self.processPath?.count != 0 && self.processPath?.hasPrefix( "/" ) == true )
        {
            if( self.processPath?.contains( ".app/Contents/MacOS" ) == true )
            {
                let app = ( self.processPath! as NSString ).substring( with: NSMakeRange( 0, ( self.processPath! as NSString ).range( of: ".app/Contents/MacOS" ).location + 4 ) )
                
                if( app.count > 0 )
                {
                    self.icon = NSWorkspace.shared.icon( forFile: app )
                }
            }
            
            if( self.icon == nil )
            {
                self.icon = NSWorkspace.shared.icon( forFile: self.processPath! )
            }
        }
        else
        {
            self.icon = NSWorkspace.shared.icon( forFile: "/bin/ls" )
        }
    }
    
    @objc public override var description: String
    {
        return String( format: "%@ %@ %@ %@", super.description, self.self.process, self.typeString, ( self.date != nil ) ? self.date!.description : "-" )
    }
    
    @objc public dynamic var typeString: String
    {
        switch self.type
        {
            case .Unknown: return "Unknown"
            case .Crash:   return "Crash"
            case .Spin:    return "Spin"
            case .Hang:    return "Hang"
            case .Diag:    return "Diagnostic"
        }
    }
    
    private func parseContents() -> Bool
    {
        let lines = self.contents.split( separator: "\n" )
        
        for line in lines
        {
            if( line.hasPrefix( "Process:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Process:\\s+([^\\[]+)\\[([0-9]+)\\]", numberOfCaptures: 2 ) else
                {
                    return false
                }
                
                guard let process = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.process   = process
                self.pid       = UInt( matches[ 1 ] ) ?? 0
                self.pidNumber = NSNumber( value: self.pid )
                self.pidString = String( format: "%u", self.pid )
            }
            else if( line.hasPrefix( "Command:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Command:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let process = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.process = process
            }
            else if( line.hasPrefix( "Version:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Version:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let version = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.version = version
            }
            else if( line.hasPrefix( "OS Version:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "OS Version:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let osVersion = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.osVersion = osVersion
            }
            else if( line.hasPrefix( "Code Type:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Code Type:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let codeType = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.codeType = codeType
            }
            else if( line.hasPrefix( "Exception Type:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Exception Type:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let exceptionType = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.exceptionType = exceptionType
            }
            else if( line.hasPrefix( "User ID:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "User ID:\\s+([0-9]+)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                self.uid       = UInt( matches[ 0 ] ) ?? 0
                self.uidNumber = NSNumber( value: self.uid )
                self.uidString = String( format: "%u", self.uid )
            }
            else if( line.hasPrefix( "Date/Time:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Date/Time:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let str = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                guard let date = DiagnosticReport.dateFormatter1.date( from: str ) else
                {
                    guard let date = DiagnosticReport.dateFormatter1.date( from: str ) else
                    {
                        return false
                    }
                    
                    self.date = date
                    
                    continue
                }
                
                self.date = date
            }
            else if( line.hasPrefix( "Path:" ) )
            {
                guard let matches = self.matches( in: String( line ), with: "Path:\\s+(.*)", numberOfCaptures: 1 ) else
                {
                    return false
                }
                
                guard let processPath = matches.first?.trimmingCharacters( in: .whitespaces ) else
                {
                    return false
                }
                
                self.processPath = processPath
            }
        }
        
        return true
    }
    
    private func matches( in string: String, with expression: String, numberOfCaptures: UInt ) -> [ String ]?
    {
        if( string.count == 0 || expression.count == 0 || numberOfCaptures == 0 )
        {
            return nil
        }
        
        do
        {
            let regexp = try NSRegularExpression( pattern: expression, options: .caseInsensitive )
            
            guard let res = regexp.matches( in: string, options: .reportCompletion, range: NSMakeRange( 0, string.count ) ).first else
            {
                return nil
            }
            
            if( res.numberOfRanges != numberOfCaptures + 1 )
            {
                return nil
            }
            
            var matches = [ String ]()
            
            for i in 1 ... res.numberOfRanges - 1
            {
                let r     = res.range( at: i )
                let match = ( string as NSString ).substring( with: r )
                
                matches.append( match )
            }
            
            return matches
        }
        catch
        {
            return nil
        }
    }
    
    // MARK: - QLPreviewItem
    
    public var previewItemURL: URL!
    {
        return URL( fileURLWithPath: self.path )
    }
    
    public var previewItemTitle: String!
    {
        return ( self.path as NSString ).lastPathComponent
    }
    
    // MARK: - NSPasteboardWriting
    
    @objc public func writableTypes( for pasteboard: NSPasteboard ) -> [ NSPasteboard.PasteboardType ]
    {
        return [ kUTTypeFileURL as NSPasteboard.PasteboardType ]
    }
    
    @objc public func pasteboardPropertyList( forType type: NSPasteboard.PasteboardType ) -> Any?
    {
        if( type == kUTTypeFileURL as NSPasteboard.PasteboardType )
        {
            return NSURL( fileURLWithPath: self.path ).absoluteString
        }
        
        return nil
    }
}
