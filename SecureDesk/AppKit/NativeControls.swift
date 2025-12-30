//
//  NativeControls.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI
import AppKit

// MARK: - Native Search Field

/// Native NSSearchField wrapped for SwiftUI
struct NativeSearchField: NSViewRepresentable {
    
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = placeholder
        searchField.delegate = context.coordinator
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: NativeSearchField
        
        init(_ parent: NativeSearchField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let searchField = obj.object as? NSSearchField {
                parent.text = searchField.stringValue
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit?()
                return true
            }
            return false
        }
    }
}

// MARK: - Native Text View (Multi-line)

/// Native NSTextView for multi-line text editing
struct NativeTextView: NSViewRepresentable {
    
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 13)
    var isEditable: Bool = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        if let textView = scrollView.documentView as? NSTextView {
            textView.delegate = context.coordinator
            textView.font = font
            textView.isEditable = isEditable
            textView.isSelectable = true
            textView.isRichText = false
            textView.allowsUndo = true
            textView.textColor = .textColor
            textView.backgroundColor = .textBackgroundColor
            textView.textContainerInset = NSSize(width: 8, height: 8)
        }
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeTextView
        
        init(_ parent: NativeTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
    }
}

// MARK: - Native Path Control

/// Native NSPathControl for file/folder path display
struct NativePathControl: NSViewRepresentable {
    
    let url: URL
    var style: NSPathControl.Style = .standard
    
    func makeNSView(context: Context) -> NSPathControl {
        let pathControl = NSPathControl()
        pathControl.pathStyle = style
        pathControl.url = url
        pathControl.isEditable = false
        return pathControl
    }
    
    func updateNSView(_ nsView: NSPathControl, context: Context) {
        nsView.url = url
    }
}

// MARK: - Native Level Indicator

/// Native NSLevelIndicator for progress/rating display
struct NativeLevelIndicator: NSViewRepresentable {
    
    @Binding var value: Double
    var minValue: Double = 0
    var maxValue: Double = 10
    var style: NSLevelIndicator.Style = .continuousCapacity
    var warningValue: Double = 7
    var criticalValue: Double = 9
    
    func makeNSView(context: Context) -> NSLevelIndicator {
        let indicator = NSLevelIndicator()
        indicator.levelIndicatorStyle = style
        indicator.minValue = minValue
        indicator.maxValue = maxValue
        indicator.warningValue = warningValue
        indicator.criticalValue = criticalValue
        indicator.target = context.coordinator
        indicator.action = #selector(Coordinator.valueChanged(_:))
        return indicator
    }
    
    func updateNSView(_ nsView: NSLevelIndicator, context: Context) {
        nsView.doubleValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativeLevelIndicator
        
        init(_ parent: NativeLevelIndicator) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: NSLevelIndicator) {
            parent.value = sender.doubleValue
        }
    }
}

// MARK: - Native Color Well

/// Native NSColorWell for color picking
struct NativeColorWell: NSViewRepresentable {
    
    @Binding var color: Color
    
    func makeNSView(context: Context) -> NSColorWell {
        let colorWell = NSColorWell()
        colorWell.target = context.coordinator
        colorWell.action = #selector(Coordinator.colorChanged(_:))
        return colorWell
    }
    
    func updateNSView(_ nsView: NSColorWell, context: Context) {
        nsView.color = NSColor(color)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativeColorWell
        
        init(_ parent: NativeColorWell) {
            self.parent = parent
        }
        
        @objc func colorChanged(_ sender: NSColorWell) {
            parent.color = Color(nsColor: sender.color)
        }
    }
}

// MARK: - Native Date Picker

/// Native NSDatePicker with custom style
struct NativeDatePicker: NSViewRepresentable {
    
    @Binding var date: Date
    var style: NSDatePicker.Style = .textFieldAndStepper
    var elements: NSDatePicker.ElementFlags = [.yearMonthDay, .hourMinute]
    
    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = style
        picker.datePickerElements = elements
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }
    
    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        nsView.dateValue = date
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativeDatePicker
        
        init(_ parent: NativeDatePicker) {
            self.parent = parent
        }
        
        @objc func dateChanged(_ sender: NSDatePicker) {
            parent.date = sender.dateValue
        }
    }
}

// MARK: - Native Progress Indicator

/// Native NSProgressIndicator (spinning or bar)
struct NativeProgressIndicator: NSViewRepresentable {
    
    var style: NSProgressIndicator.Style = .spinning
    var isIndeterminate: Bool = true
    @Binding var value: Double
    var maxValue: Double = 100
    
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = style
        indicator.isIndeterminate = isIndeterminate
        indicator.maxValue = maxValue
        
        if isIndeterminate {
            indicator.startAnimation(nil)
        }
        
        return indicator
    }
    
    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        if !isIndeterminate {
            nsView.doubleValue = value
        }
    }
}
