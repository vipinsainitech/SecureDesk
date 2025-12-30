//
//  ItemDetailView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Detailed view for viewing and editing an item
struct ItemDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let item: Item
    let onSave: (ItemEditData) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var title: String
    @State private var description: String
    @State private var status: ItemStatus
    @State private var priority: ItemPriority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var tags: String
    @State private var showingDeleteAlert = false
    @State private var isSaving = false
    
    init(item: Item, onSave: @escaping (ItemEditData) -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state
        _title = State(initialValue: item.title)
        _description = State(initialValue: item.description)
        _status = State(initialValue: item.status)
        _priority = State(initialValue: item.priority)
        _dueDate = State(initialValue: item.dueDate)
        _hasDueDate = State(initialValue: item.dueDate != nil)
        _tags = State(initialValue: item.tags.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    if isEditing {
                        editingView
                    } else {
                        detailView
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 600, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(item.title)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Edit Item" : "Item Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Created \(item.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
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
    
    // MARK: - Detail View
    
    private var detailView: some View {
        VStack(spacing: 20) {
            // Status Badge
            HStack {
                statusBadge(for: item.status)
                priorityBadge(for: item.priority)
                Spacer()
            }
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Description
            if !item.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(item.description)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Due Date
            if let dueDate = item.dueDate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(dueDate, style: .date)
                        Text(dueDate, style: .time)
                        
                        if dueDate < Date() {
                            Text("(Overdue)")
                                .foregroundStyle(.red)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Tags
            if !item.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Metadata
            VStack(spacing: 12) {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Updated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.updatedAt, style: .relative)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Created")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.createdAt, style: .date)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
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
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
            
            // Status
            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Status", selection: $status) {
                    ForEach(ItemStatus.allCases, id: \.self) { status in
                        HStack {
                            Image(systemName: status.iconName)
                            Text(status.displayName)
                        }
                        .tag(status)
                    }
                }
                .pickerStyle(.segmented)
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
                
                Text("Separate multiple tags with commas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            if isEditing {
                Button("Cancel") {
                    cancelEditing()
                }
                .keyboardShortcut(.cancelAction)
            } else {
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
            
            Spacer()
            
            if isEditing {
                Button {
                    saveChanges()
                } label: {
                    HStack(spacing: 6) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Text(isSaving ? "Saving..." : "Save Changes")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid || !hasChanges || isSaving)
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Edit") {
                    isEditing = true
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("e", modifiers: .command)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func statusBadge(for status: ItemStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
            Text(status.displayName)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(colorForStatus(status).opacity(0.2), in: Capsule())
        .foregroundStyle(colorForStatus(status))
    }
    
    private func priorityBadge(for priority: ItemPriority) -> some View {
        HStack(spacing: 4) {
            Image(systemName: priority.iconName)
            Text(priority.displayName)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(colorForPriority(priority).opacity(0.2), in: Capsule())
        .foregroundStyle(colorForPriority(priority))
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        title != item.title ||
        description != item.description ||
        status != item.status ||
        priority != item.priority ||
        (hasDueDate ? dueDate : nil) != item.dueDate ||
        parsedTags != item.tags
    }
    
    private var parsedTags: [String] {
        tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Actions
    
    private func cancelEditing() {
        title = item.title
        description = item.description
        status = item.status
        priority = item.priority
        dueDate = item.dueDate
        hasDueDate = item.dueDate != nil
        tags = item.tags.joined(separator: ", ")
        isEditing = false
    }
    
    private func saveChanges() {
        guard isFormValid && hasChanges else { return }
        
        isSaving = true
        
        let data = ItemEditData(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            tags: parsedTags
        )
        
        onSave(data)
        
        // Dismiss after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
    
    private func colorForStatus(_ status: ItemStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .secondary
        }
    }
    
    private func colorForPriority(_ priority: ItemPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Item Edit Data

/// Data transfer object for editing an item
struct ItemEditData {
    let title: String
    let description: String
    let status: ItemStatus
    let priority: ItemPriority
    let dueDate: Date?
    let tags: [String]
}

// MARK: - Flow Layout

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    ItemDetailView(
        item: Item.preview,
        onSave: { data in
            print("Saving: \(data.title)")
        },
        onDelete: {
            print("Deleting item")
        }
    )
}
