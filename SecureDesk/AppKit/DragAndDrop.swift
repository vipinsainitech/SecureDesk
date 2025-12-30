//
//  DragAndDrop.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Drag Source

/// Makes a view draggable with custom data
struct DraggableItem: ViewModifier {
    
    let item: Item
    
    func body(content: Content) -> some View {
        content
            .onDrag {
                // Create provider with item data
                let provider = NSItemProvider()
                
                // Add as JSON
                if let data = try? JSONEncoder().encode(item) {
                    provider.registerDataRepresentation(
                        forTypeIdentifier: UTType.json.identifier,
                        visibility: .all
                    ) { completion in
                        completion(data, nil)
                        return nil
                    }
                }
                
                // Add as plain text (title)
                provider.registerObject(item.title as NSString, visibility: .all)
                
                return provider
            }
    }
}

extension View {
    func draggable(item: Item) -> some View {
        modifier(DraggableItem(item: item))
    }
}

// MARK: - Drop Target

/// Makes a view accept drops
struct DropTarget: ViewModifier {
    
    let acceptedTypes: [UTType]
    let onDrop: ([NSItemProvider]) -> Bool
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: acceptedTypes, isTargeted: nil) { providers in
                onDrop(providers)
            }
    }
}

extension View {
    func dropTarget(
        types: [UTType] = [.json, .text],
        onDrop: @escaping ([NSItemProvider]) -> Bool
    ) -> some View {
        modifier(DropTarget(acceptedTypes: types, onDrop: onDrop))
    }
}

// MARK: - File Drop Zone

/// A view that accepts file drops
struct FileDropZone: View {
    
    let allowedTypes: [UTType]
    let onFilesDrop: ([URL]) -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundStyle(isTargeted ? .blue : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.blue.opacity(0.1) : Color.clear)
                )
            
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 32))
                    .foregroundStyle(isTargeted ? .blue : .secondary)
                
                Text("Drop files here")
                    .font(.headline)
                    .foregroundStyle(isTargeted ? .blue : .secondary)
                
                Text("Supported: \(allowedTypes.compactMap { $0.localizedDescription }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 150)
        .onDrop(of: allowedTypes, isTargeted: $isTargeted) { providers in
            loadFiles(from: providers)
            return true
        }
    }
    
    private func loadFiles(from providers: [NSItemProvider]) {
        for provider in providers {
            for type in allowedTypes where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
                    if let url = url {
                        // Copy to temp location if needed
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                        try? FileManager.default.copyItem(at: url, to: tempURL)
                        
                        DispatchQueue.main.async {
                            onFilesDrop([tempURL])
                        }
                    }
                }
                break
            }
        }
    }
}

// MARK: - Export Service

/// Handles exporting items to files
struct ExportService {
    
    /// Export items to JSON file
    static func exportItems(_ items: [Item]) async -> Bool {
        guard let url = await NativeFileDialog.showSavePanel(
            title: "Export Items",
            allowedTypes: ["json"],
            suggestedName: "securedesk_export_\(dateString())"
        ) else {
            return false
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(items)
            try data.write(to: url)
            
            // Show in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])
            
            return true
        } catch {
            print("[Export] Failed: \(error)")
            return false
        }
    }
    
    /// Import items from JSON file
    static func importItems() async -> [Item]? {
        let urls = await NativeFileDialog.showOpenPanel(
            title: "Import Items",
            allowedTypes: ["json"],
            allowsMultiple: false
        )
        
        guard let url = urls.first else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode([Item].self, from: data)
        } catch {
            print("[Import] Failed: \(error)")
            return nil
        }
    }
    
    private static func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Share Service

/// Handles sharing via system share sheet
struct ShareService {
    
    /// Share items
    static func share(_ items: [Any], from view: NSView? = nil) {
        let picker = NSSharingServicePicker(items: items)
        
        if let view = view ?? NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    /// Share item as text
    static func shareItem(_ item: Item, from view: NSView? = nil) {
        let text = """
        \(item.title)
        
        \(item.description)
        
        Status: \(item.status.displayName)
        Priority: \(item.priority.displayName)
        """
        
        share([text], from: view)
    }
}
