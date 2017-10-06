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

@objc class Application: NSObject
{
    @objc public private( set ) dynamic var name:              String = ""
    @objc public private( set ) dynamic var path:              String = ""
    @objc public private( set ) dynamic var bundleIdentifier:  String = ""
    @objc public private( set ) dynamic var version:           String = ""
    @objc public private( set ) dynamic var url:               URL
    @objc public private( set ) dynamic var icon:              NSImage?
    
    @objc public static func applicationsForFile( _ file: String ) -> Array< Application >
    {
        return self.applicationsForFileExtension( ( file as NSString ).pathExtension )
    }
    
    @objc public static func applicationsForFileExtension( _ fileExtension: String ) -> [ Application ]
    {
        let tmp = ( NSTemporaryDirectory() as NSString ).appendingFormat( "%@.%@", NSUUID().uuidString, fileExtension ) as String
        let url = NSURL( fileURLWithPath:  tmp )
        
        FileManager.default.createFile( atPath: tmp, contents: nil, attributes:  nil )
        
        let urls = LSCopyApplicationURLsForURL( url, [ .viewer, .editor ] )?.takeUnretainedValue() as? [ URL ]
        var apps = Set< Application >();
        
        if( urls != nil )
        {
            for url in urls!
            {
                guard let app = Application.applicationWithURL( url ) else
                {
                    continue
                }
                
                apps.insert( app )
            }
        }
        
        do
        {
            try FileManager.default.removeItem( atPath: tmp )
        }
        catch
        {}
        
        return apps.sorted{ $0.name < $1.name }
    }
    
    @objc public static func applicationsMenuForFile( _ file: String, target: AnyObject, action: Selector ) -> NSMenu
    {
        return self.applicationsMenuForFileExtension( ( file as NSString ).pathExtension, target: target, action: action )
    }
    
    @objc public static func applicationsMenuForFileExtension( _ fileExtension: String, target: AnyObject, action: Selector ) -> NSMenu
    {
        let apps = Application.applicationsForFileExtension( fileExtension )
        let menu = NSMenu()
        
        if( apps.count == 0 )
        {
            return menu
        }
        
        for app in apps
        {
            var title: String
            
            if( app.version.count > 0 )
            {
                title = String( format: "%@ (%@)", app.name, app.version );
            }
            else
            {
                title = app.name;
            }
            
            let item = NSMenuItem( title: title, action: action, keyEquivalent: "" )
            
            item.representedObject = app
            item.target            = target
            
            let image = app.icon
            
            image?.size = NSMakeSize( 24.0, 24.0 )
            item.image  = image
            
            menu.addItem( item )
        }
        
        return menu
    }
    
    @objc public static func applicationWithPath( _ path: String ) -> Application?
    {
        return Application( path: path )
    }
    
    @objc public static func applicationWithURL( _ url: URL ) -> Application?
    {
        return Application( url: url )
    }
    
    @objc convenience init?( path: String )
    {
        self.init( url: URL.init( fileURLWithPath: path ) )
    }
    
    @objc init?( url: URL )
    {
        var isDir: ObjCBool = false;
        
        if( FileManager.default.fileExists( atPath: url.path, isDirectory: &isDir ) == false || isDir.boolValue == false )
        {
            return nil
        }
        
        guard let bundle = Bundle( path: url.path ) else
        {
            return nil
        }
        
        self.path             = url.path
        self.url              = url
        self.name             = FileManager.default.displayName( atPath: self.path )
        self.icon             = NSWorkspace.shared.icon( forFile: self.path )
        self.bundleIdentifier = bundle.bundleIdentifier ?? ""
        self.version          = bundle.infoDictionary?[ "CFBundleShortVersionString" ] as! String? ?? ""
    }
    
    @objc public func open() -> Void
    {
        do
        {
            try NSWorkspace.shared.launchApplication( at: self.url, options: .default, configuration: [ : ] )
        }
        catch
        {}
    }
    
    @objc public func openFile( _ file: String ) -> Void
    {
        NSWorkspace.shared.openFile( file, withApplication: self.path )
    }
    
    @objc public override var description: String
    {
        return String( format: "%@ %@ (%@)", super.description, self.name, ( self.path as NSString ).deletingLastPathComponent )
    }
}
