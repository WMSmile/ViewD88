//
//  ViewController.swift
//  D88-Cocoa
//
//  Created by Iggy Drougge on 2017-01-07.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var table: NSTableView!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var dumpFileButton: NSButton!
    var diskimage:D88Image!
    var files:[D88Image.FileEntry]!
    var fileurl:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textField.isEditable = false
        let imgpath = URL(fileURLWithPath: NSHomeDirectory()+"/Documents/d88-swift/basic.d88")
        fileurl = imgpath
        textField.stringValue = imgpath.lastPathComponent
        guard let imgdata = try? Data(contentsOf: imgpath) else { fatalError("Fel vid inläsning av fil")}
        diskimage = D88Image(data: imgdata)
        files = diskimage.getFiles()
        
        table.dataSource = self
        table.delegate = self
        table.allowsMultipleSelection = true
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return files.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //print(#function,tableColumn!.identifier)
        let cell = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        switch tableColumn?.identifier {
        case let id where id == "nr": cell.textField?.stringValue = "nr \(row)"
        case "name"?:
            let name = files[row].name
            cell.textField?.stringValue = name
        case "type"?:
            let attr:String!
            switch files[row].attributes {
            case .BAS: attr = "BASIC"
            case .ASC: attr = "ASCII"
            case .BIN: attr = "BINARY"
            case .RAW: attr = "RAW"
            case .RDP: attr = "read protect"
            case .WRP: attr = "write protect"
            case .BAD: attr = "BAD"
            }
            cell.textField?.stringValue = attr
        default: break
        }
        return cell
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        dumpFileButton.isEnabled = table.selectedRow != -1
    }
    @IBAction func didPressSelectButton(_ sender: Any) {
        print(#function)
        let dialogue = NSOpenPanel()
        dialogue.allowsMultipleSelection = false
        dialogue.canChooseDirectories = false
        dialogue.allowedFileTypes = ["d88","d77","d20"]
        guard dialogue.runModal() == NSModalResponseOK, let url = dialogue.url else { return }
        textField.stringValue = url.lastPathComponent
        guard let imgdata = try? Data(contentsOf: url) else { return }
        diskimage = D88Image(data: imgdata)
        files = diskimage.getFiles()
        table.reloadData()
        
    }
    @IBAction func didPressDumpContents(_ sender: Any) {
        guard let fileurl = fileurl else {return}
        let filename = fileurl.deletingPathExtension().appendingPathExtension("2d").lastPathComponent
        print(#function,filename)
        let savepanel = NSSavePanel()
        savepanel.title = "Save raw contents of disk"
        savepanel.nameFieldStringValue = filename
        guard savepanel.runModal() == NSModalResponseOK,
            let url = savepanel.url else { return }
        let data = diskimage.rawData
        do {
            try data.write(to: url)
        }
        catch {
            print(error)
        }
    }
    @IBAction func didPressDumpFile(_ sender: Any) {
        guard table.selectedRow != -1 else {
            print(#function, "No file selected")
            return
        }
        let file = files[table.selectedRow]
        print(#function, file.name)
        let dialogue = NSSavePanel()
        //dialogue.message = "Spara här"
        dialogue.title = "Save file from disk image"
        dialogue.nameFieldStringValue = file.name
        guard
            dialogue.runModal() == NSModalResponseOK,
            let url = dialogue.url
            else {
            return
        }
        let filedata = diskimage.getFile(file: file)
        do {
            try filedata.write(to: url)
            print("Sparade fil på \(url)")
        }
        catch {
            print(error)
        }
        
    }
}

