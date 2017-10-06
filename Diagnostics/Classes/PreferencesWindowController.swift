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

@objc class PreferencesWindowController: NSWindowController
{
    @objc private dynamic var fontDescription: String  = ""
    @objc private dynamic var backgroundColor: NSColor = NSColor.white
    @objc private dynamic var foregroundColor: NSColor = NSColor.black
    @objc private dynamic var selectedTheme:   Int     = 0
    
    private var observation1: NSKeyValueObservation?
    private var observation2: NSKeyValueObservation?
    private var observation3: NSKeyValueObservation?
    private var observation4: NSKeyValueObservation?
    private var observation5: NSKeyValueObservation?
    
    @objc private dynamic var preferences: Preferences
    {
        return Preferences.sharedInstance()
    }
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.fontDescription = String( format: "%@ %.0f", Preferences.sharedInstance().fontName ?? "-", Preferences.sharedInstance().fontSize )
        self.backgroundColor = NSColor( deviceRed: Preferences.sharedInstance().backgroundColorR, green: Preferences.sharedInstance().backgroundColorG, blue: Preferences.sharedInstance().backgroundColorB, alpha: 1.0 )
        self.foregroundColor = NSColor( deviceRed: Preferences.sharedInstance().foregroundColorR, green: Preferences.sharedInstance().foregroundColorG, blue: Preferences.sharedInstance().foregroundColorB, alpha: 1.0 )
        
        self.observation1 = self.observe( \.preferences.fontName )
        {
            object, change in self.fontDescription = String( format: "%@ %.0f", Preferences.sharedInstance().fontName ?? "-", Preferences.sharedInstance().fontSize )
        }
        
        self.observation2 = self.observe( \.preferences.fontSize )
        {
            object, change in self.fontDescription = String( format: "%@ %.0f", Preferences.sharedInstance().fontName ?? "-", Preferences.sharedInstance().fontSize )
        }
        
        self.observation3 = self.observe( \.backgroundColor )
        {
            object, change in
            
            var r: CGFloat = 0.0
            var g: CGFloat = 0.0
            var b: CGFloat = 0.0
            
            self.backgroundColor.usingColorSpace( .deviceRGB )?.getRed( &r, green: &g, blue: &b, alpha: nil )
            
            Preferences.sharedInstance().backgroundColorR = r
            Preferences.sharedInstance().backgroundColorG = g
            Preferences.sharedInstance().backgroundColorB = b
        }
        
        self.observation4 = self.observe( \.foregroundColor )
        {
            object, change in
            
            var r: CGFloat = 0.0
            var g: CGFloat = 0.0
            var b: CGFloat = 0.0
            
            self.foregroundColor.usingColorSpace( .deviceRGB )?.getRed( &r, green: &g, blue: &b, alpha: nil )
            
            Preferences.sharedInstance().foregroundColorR = r
            Preferences.sharedInstance().foregroundColorG = g
            Preferences.sharedInstance().foregroundColorB = b
        }
        
        self.observation5 = self.observe( \.selectedTheme )
        {
            object, change in
            
            switch( self.selectedTheme )
            {
                case 1:
                    
                    self.backgroundColor = self.hexColor( 0xFFFFFF, alpha: 1.0 );
                    self.foregroundColor = self.hexColor( 0x000000, alpha: 1.0 );
                    
                    break;
                    
                case 2:
                    
                    self.backgroundColor = self.hexColor( 0x000000, alpha: 1.0 );
                    self.foregroundColor = self.hexColor( 0xFFFFFF, alpha: 1.0 );
                    
                    break;
                    
                case 3:
                    
                    self.backgroundColor = self.hexColor( 0xFFFCE5, alpha: 1.0 );
                    self.foregroundColor = self.hexColor( 0xC3741C, alpha: 1.0 );
                    
                    break;
                    
                case 4:
                    
                    self.backgroundColor = self.hexColor( 0x161A1D, alpha: 1.0 );
                    self.foregroundColor = self.hexColor( 0xBFBFBF, alpha: 1.0 );
                    
                    break;
                    
                default:
                    
                    break;
            }
        }
    }
    
    private func hexColor( _ hex: UInt, alpha: CGFloat ) -> NSColor
    {
        let r: CGFloat = CGFloat( ( ( hex >> 16 ) & 0x0000FF ) ) / 255.0
        let g: CGFloat = CGFloat( ( ( hex >>  8 ) & 0x0000FF ) ) / 255.0
        let b: CGFloat = CGFloat( ( ( hex       ) & 0x0000FF ) ) / 255.0
        
        return NSColor( deviceRed: r, green: g, blue: b, alpha: alpha )
    }
    
    @IBAction func chooseFont( _ sender: Any? )
    {
        let font    = NSFont( name: Preferences.sharedInstance().fontName ?? "", size: Preferences.sharedInstance().fontSize )
        let manager = NSFontManager.shared
        let panel   = manager.fontPanel( true )
        
        if( font != nil )
        {
            manager.setSelectedFont( font!, isMultiple: false )
        }
        
        panel?.makeKeyAndOrderFront( sender )
    }
    
    @IBAction override func changeFont( _ sender: Any? )
    {
        guard let manager = ( sender as AnyObject? ) as? NSFontManager else
        {
            return
        }
        
        guard let selected = manager.selectedFont else
        {
            return
        }
        
        let font = manager.convert( selected )
        
        Preferences.sharedInstance().fontName = font.fontName
        Preferences.sharedInstance().fontSize = font.pointSize
    }
}

