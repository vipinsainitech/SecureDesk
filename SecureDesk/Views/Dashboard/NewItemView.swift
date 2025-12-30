//
//  NewItemView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Form for creating a new item
struct NewItemView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (ItemCreationData) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: ItemPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var tags = ""
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Form
            ScrollView {
                VStack(spacing: 20) {
                    formFields
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 500, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("New Item")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Form Fields
    
    private var formFields: some View {
        VStack(spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter item title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: $description)
                    .font(.body)
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
            
            // Priority
            VStack(alignment: .leading, spacing: 6) {
                Text("Priority")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Priority", selection: $priority) {
                    ForEach(ItemPriority.allCases, id: \.self) { priority in
                        HStack {
                            Image(systemName: priority.iconName)
                            Text(priority.displayName)
                        }
                        .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Due Date
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Set Due Date", isOn: $hasDueDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if hasDueDate {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.field)
                }
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 6) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter tags separated by commas", text: $tags)
                    .textFieldStyle(.roundedBorder)
                
                Text("Separate multiple tags with commas (e.g., work, urgent, finance)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button {
                saveItem()
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Text(isSaving ? "Creating..." : "Create Item")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isSaving)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var parsedTags: [String] {
        tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Actions
    
    private func saveItem() {
        guard isFormValid else { return }
        
        isSaving = true
        
        let data = ItemCreationData(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            tags: parsedTags
        )
        
        onSave(data)
        
        // Dismiss after a brief delay to show saving state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Item Creation Data

/// Data transfer object for creating a new item
struct ItemCreationData {
    let title: String
    let description: String
    let priority: ItemPriority
    let dueDate: Date?
    let tags: [String]
}

// MARK: - Preview

#Preview {
    NewItemView { data in
        print("Creating item: \(data.title)")
    }
}
