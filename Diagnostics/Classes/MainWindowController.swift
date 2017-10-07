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

@objc class MainWindowController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource, QLPreviewPanelDelegate, QLPreviewPanelDataSource, NSMenuDelegate
{
    @objc private dynamic var groups:       [ DiagnosticReportGroup ] = []
    @objc private dynamic var editable:     Bool                      = false
    @objc private dynamic var initializing: Bool                      = false
    @objc private dynamic var loading:      Bool                      = false
    @objc private dynamic var copying:      Bool                      = false
    @objc private dynamic var observations: [ NSKeyValueObservation ] = []
    
    @IBOutlet @objc private dynamic var groupController:   NSArrayController?
    @IBOutlet @objc private dynamic var reportsController: NSArrayController?
    @IBOutlet @objc private dynamic var reportsTableView:  NSTableView?
    @IBOutlet @objc private dynamic var textView:          NSTextView?
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility            = .hidden
        self.groupController?.sortDescriptors   = [ NSSortDescriptor( key: "name", ascending: true ) ]
        self.reportsController?.sortDescriptors = [ NSSortDescriptor( key: "date", ascending: false ) ]
        self.textView?.textContainerInset       = NSMakeSize( 10.0, 15.0 )
        
        let o1 = Preferences.shared.observe( \.fontName         ) { ( o, c ) in self.updateDisplaySettings() }
        let o2 = Preferences.shared.observe( \.fontSize         ) { ( o, c ) in self.updateDisplaySettings() }
        let o3 = Preferences.shared.observe( \.backgroundColorR ) { ( o, c ) in self.updateDisplaySettings() }
        let o4 = Preferences.shared.observe( \.backgroundColorG ) { ( o, c ) in self.updateDisplaySettings() }
        let o5 = Preferences.shared.observe( \.backgroundColorB ) { ( o, c ) in self.updateDisplaySettings() }
        let o6 = Preferences.shared.observe( \.foregroundColorR ) { ( o, c ) in self.updateDisplaySettings() }
        let o7 = Preferences.shared.observe( \.foregroundColorG ) { ( o, c ) in self.updateDisplaySettings() }
        let o8 = Preferences.shared.observe( \.foregroundColorB ) { ( o, c ) in self.updateDisplaySettings() }
        
        self.observations.append( contentsOf: [ o1, o2, o3, o4, o5, o6, o7, o8 ] )
        
        self.updateDisplaySettings()
        self.reload( nil )
    }
    
    @objc private func updateDisplaySettings() -> Void
    {
        var font = NSFont( name: Preferences.shared.fontName ?? "", size: Preferences.shared.fontSize )
        
        if( font == nil )
        {
            font = NSFont( name: "Consolas", size: 10 )
        }
        
        if( font == nil )
        {
            font = NSFont( name: "Menlo", size: 10 )
        }
        
        if( font == nil )
        {
            font = NSFont( name: "Monaco", size: 10 )
        }
        
        let background = NSColor( deviceRed: Preferences.shared.backgroundColorR, green: Preferences.shared.backgroundColorG, blue: Preferences.shared.backgroundColorB, alpha: 1.0 )
        let foreground = NSColor( deviceRed: Preferences.shared.foregroundColorR, green: Preferences.shared.foregroundColorG, blue: Preferences.shared.foregroundColorB, alpha: 1.0 )
        
        self.textView?.font            = font
        self.textView?.backgroundColor = background
        self.textView?.textColor       = foreground
    }
    
    @objc private func clickedOrSelectedItems() -> [ DiagnosticReport ]
    {
        guard let tableView = self.reportsTableView else
        {
            return []
        }
        
        guard let controller = self.reportsController else
        {
            return []
        }
        
        let arranged = controller.arrangedObjectsArray() as [ DiagnosticReport ]
        let selected = controller.selectedObjectsArray() as [ DiagnosticReport ]
        
        if( tableView.clickedRow >= 0 )
        {
            if( tableView.clickedRow >= arranged.count )
            {
                return []
            }
            
            if( selected.contains( arranged[ tableView.clickedRow ] ) )
            {
                return selected
            }
            else
            {
                return [ arranged[ tableView.clickedRow ] ]
            }
        }
        else
        {
            return selected
        }
    }
    
    @objc private func share( _ sender: Any? ) -> Void
    {
        guard let tableView = self.reportsTableView else
        {
            return
        }
        
        guard let view = tableView.view( atColumn: tableView.clickedColumn, row: tableView.clickedRow, makeIfNecessary: false ) else
        {
            return
        }
        
        let picker = NSSharingServicePicker( items: self.clickedOrSelectedItems() )
        
        picker.show( relativeTo: view.bounds, of: view, preferredEdge: .minY )
    }
    
    @objc private func performFindPanelAction( _ sender: Any ) -> Void
    {
        self.textView?.performTextFinderAction( sender )
    }
    
    @objc private func open( _ sender: Any? ) -> Void
    {
        self.openReports( self.clickedOrSelectedItems() )
    }
    
    @objc private func openDocument( _ sender: Any? ) -> Void
    {
        self.openReports( self.reportsController?.selectedObjects as! [ DiagnosticReport ] )
    }
    
    @objc private func openWithApp( _ sender: Any ) -> Void
    {
        guard let menuItem = sender as? NSMenuItem else
        {
            return
        }
        
        guard let app = menuItem.representedObject as? Application else
        {
            return
        }
        
        for report in self.clickedOrSelectedItems()
        {
            app.openFile( report.path )
        }
    }
    
    @objc private func openReports( _ reports: [ DiagnosticReport ] ) -> Void
    {
        for report in reports
        {
            NSWorkspace.shared.openFile( report.path )
        }
    }
    
    @objc private func showInFinder( _ sender: Any? ) -> Void
    {
        var urls = [ URL ]()
        
        for report in self.clickedOrSelectedItems()
        {
            urls.append( URL( fileURLWithPath: report.path ) )
        }
        
        if( urls.count > 0 )
        {
            NSWorkspace.shared.activateFileViewerSelecting( urls )
        }
    }
    
    @objc private func saveAs( _ sender: Any? ) -> Void
    {
        self.saveReports( self.clickedOrSelectedItems() )
    }
    
    @objc private func saveDocument( _ sender: Any? ) -> Void
    {
        guard let controller = self.reportsController else
        {
            return
        }
        
        self.saveReports( controller.selectedObjectsArray() )
    }
    
    @objc private func saveDocumentAs( _ sender: Any? ) -> Void
    {
        guard let controller = self.reportsController else
        {
            return
        }
        
        self.saveReports( controller.selectedObjectsArray() )
    }
    
    @objc private func saveReports( _ reports: [ DiagnosticReport ] ) -> Void
    {
        if( reports.count == 0 )
        {
            return
        }
        
        let panel                     = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.canCreateDirectories    = true
        panel.prompt                  = "Save"
        
        panel.beginSheetModal( for: self.window! )
        {
            ( r ) in
            
            if( r != .OK || panel.urls.count == 0 )
            {
                return
            }
            
            self.saveReports( reports, to: panel.urls[ 0 ] )
        }
    }
    
    @objc private func saveReports( _ reports: [ DiagnosticReport ], to url: URL ) -> Void
    {
        var isDir: ObjCBool                = false
        var applyToAll                     = false
        var r: NSApplication.ModalResponse = .alertSecondButtonReturn
        
        if( FileManager.default.fileExists( atPath: url.path, isDirectory: &isDir ) == false || isDir.boolValue == false )
        {
            return
        }
        
        self.copying = true
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            for report in reports
            {
                let path = ( url.path as NSString ).appendingPathComponent( ( report.path as NSString ).lastPathComponent )
                
                if( FileManager.default.fileExists( atPath: path ) )
                {
                    if( applyToAll == false )
                    {
                        DispatchQueue.main.sync
                        {
                            let alert             = NSAlert()
                            alert.messageText     = "File already exists"
                            alert.informativeText = String( format: "A file named %@ already exists in the selected location.", ( path as NSString ).lastPathComponent )
                            
                            alert.addButton( withTitle: "Replace" )
                            alert.addButton( withTitle: "Skip" )
                            alert.addButton( withTitle: "Stop" )
                            
                            let check        = NSButton( frame: NSZeroRect )
                            check.title      = "Apply to All"
                            check.isBordered = false
                            
                            check.setButtonType( .`switch` )
                            check.sizeToFit()
                            
                            alert.accessoryView = check
                            
                            r          = alert.runModal()
                            applyToAll = check.integerValue == 1
                        }
                    }
                    
                    if( r == .alertFirstButtonReturn )
                    {
                        do
                        {
                            try FileManager.default.removeItem( atPath: path )
                        }
                        catch let error
                        {
                            DispatchQueue.main.sync
                            {
                                let alert = NSAlert( error: error )
                                
                                alert.runModal()
                            }
                        }
                    }
                    else if( r == .alertSecondButtonReturn )
                    {
                        continue
                    }
                    else
                    {
                        DispatchQueue.main.sync{ self.copying = false }
                        
                        return
                    }
                }
                
                do
                {
                    try FileManager.default.copyItem( atPath: report.path, toPath: path )
                }
                catch let error
                {
                    DispatchQueue.main.sync
                    {
                        let alert = NSAlert( error: error )
                        
                        alert.runModal()
                        
                        self.copying = false
                    }
                    
                    return
                }
            }
            
            DispatchQueue.main.sync{ self.copying = false }
        }
    }
    
    @objc private func reload( _ sender: Any? ) -> Void
    {
        if( self.loading )
        {
            return
        }
        
        self.initializing = true
        self.loading      = true
        
        self.groupController?.remove( contentsOf: self.groups )
        
        DispatchQueue.global( qos: .userInitiated ).asyncAfter( deadline: DispatchTime.now() + .seconds( 1 ) )
        {
            DiagnosticReport.availableReports
            {
                ( report ) in
                
                var group = self.groups.first{ $0.reports.first?.process == report.process }
                var add   = false
                
                if( group == nil )
                {
                    group = DiagnosticReportGroup( name: report.process )
                    add   = true
                }
                
                DispatchQueue.main.sync
                {
                    group?.addReport( report )
                    
                    if( add )
                    {
                        self.groupController?.addObject( group! )
                    }
                    
                    self.initializing = false
                }
            }
            
            DispatchQueue.main.sync{ self.loading = false }
        }
    }
    
    override func validateMenuItem( _ menuItem: NSMenuItem ) -> Bool
    {
        guard let action = menuItem.action else
        {
            return false
        }
        
        guard let tableView = self.reportsTableView else
        {
            return false
        }
        
        guard let controller = self.reportsController else
        {
            return false
        }
        
        if( action == #selector( reload( _ : ) ) )
        {
            return self.loading == false
        }
        
        if
        (
               action == #selector( open( _ : ) )
            || action == #selector( openWithApp( _ : ) )
            || action == #selector( showInFinder( _ : ) )
            || action == #selector( saveAs( _ : ) )
            || action == #selector( share( _ : ) )
        )
        {
            return tableView.clickedRow >= 0
        }
        
        if
        (
               action == #selector( saveDocument( _ : ) )
            || action == #selector( saveDocumentAs( _ : ) )
            || action == #selector( openDocument( _ : ) )
        )
        {
            return controller.selectedObjects.count >= 0
        }
        
        return false
    }
    
    // MARK: - QuickLook
    
    override func acceptsPreviewPanelControl( _ panel: QLPreviewPanel! ) -> Bool
    {
        guard let controller = self.reportsController else
        {
            return false
        }
        
        return controller.selectedObjects.count > 0
    }
    
    override func beginPreviewPanelControl( _ panel: QLPreviewPanel! )
    {
        panel.delegate   = self
        panel.dataSource = self
    }
    
    override func endPreviewPanelControl( _ panel: QLPreviewPanel! )
    {
        panel.delegate   = nil
        panel.dataSource = nil
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    func numberOfPreviewItems( in panel: QLPreviewPanel! ) -> Int
    {
        return self.reportsController?.selectedObjects.count ?? 0
    }
    
    func previewPanel( _ panel: QLPreviewPanel!, previewItemAt index: Int ) -> QLPreviewItem!
    {
        guard let array: [ DiagnosticReport ] = self.reportsController?.selectedObjectsArray() else
        {
            return nil
        }
        
        return ( array.count > index ) ? array[ index ] : nil
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen( _ menu: NSMenu )
    {
        for item in menu.items
        {
            if( item.tag != 1 )
            {
                continue
            }
            
            item.submenu = Application.applicationsMenuForFileExtension( "txt", target:  self, action: #selector( openWithApp( _: ) ) )
            
            guard let console = Application.applicationWithPath( "/Applications/Utilities/Console.app" ) else
            {
                continue
            }
            
            let consoleItem               = NSMenuItem( title: String( format: "%@ (%@)", console.name, console.version ), action: #selector( openWithApp( _: ) ), keyEquivalent: "" )
            consoleItem.image             = console.icon
            consoleItem.target            = self
            consoleItem.representedObject = console
            
            item.submenu?.insertItem( consoleItem,            at: 0 )
            item.submenu?.insertItem( NSMenuItem.separator(), at: 1 )
        }
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView( _ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String? ) -> Bool
    {
        if( ( searchString == nil || searchString!.count == 0 ) && event.charactersIgnoringModifiers == " " )
        {
            if( QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible )
            {
                QLPreviewPanel.shared().orderOut( nil )
            }
            else
            {
                QLPreviewPanel.shared().center()
                QLPreviewPanel.shared().updateController()
                QLPreviewPanel.shared().makeKeyAndOrderFront( nil )
            }
            
            return false
        }
        
        return true
    }
    
    // MARK: - NSTableViewDataSource
    
    func tableView( _ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard ) -> Bool
    {
        if( tableView != self.reportsTableView )
        {
            return false
        }
        
        tableView.setDraggingSourceOperationMask( .copy, forLocal: false )
        
        guard let items = ( self.reportsController?.arrangedObjects as? NSArray )?.objects( at: rowIndexes ) else
        {
            return false
        }
        
        var extenions = [ String ]()
        var contents  = [ String ]()
        
        for item in items as! [ DiagnosticReport ]
        {
            let ext = ( item.path as NSString ).pathExtension 
            
            extenions.append( ext )
            contents.append( item.contents )
        }
        
        if( extenions.count > 0 )
        {
            pboard.setPropertyList( extenions, forType: .filePromise )
            pboard.setString( contents.joined( separator: "\n\n--------------------------------------------------------------------------------\n\n" ), forType: .string )
            
            return true
        }
        
        return false
    }
    
    func tableView( _ tableView: NSTableView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedRowsWith indexSet: IndexSet ) -> [ String ]
    {
        if( tableView != self.reportsTableView )
        {
            return []
        }
        
        guard let items = ( self.reportsController?.arrangedObjects as? NSArray )?.objects( at: indexSet ) else
        {
            return []
        }
        
        self.saveReports( items as! [ DiagnosticReport ], to: dropDestination )
        
        return []
    }
}
