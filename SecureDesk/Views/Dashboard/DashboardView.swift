//
//  DashboardView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Main dashboard showing items
struct DashboardView: View {
    
    @State private var viewModel: DashboardViewModel
    @State private var selectedItem: Item?
    @State private var showingNewItemSheet = false
    
    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            contentSection
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refreshItems()
        }
        .sheet(isPresented: $showingNewItemSheet) {
            NewItemView { data in
                Task {
                    await viewModel.createItem(data: data)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(
                item: item,
                onSave: { data in
                    Task {
                        await viewModel.updateItem(item, with: data)
                    }
                },
                onDelete: {
                    Task {
                        await viewModel.deleteItem(item)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .newItemRequested)) { _ in
            showingNewItemSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task {
                await viewModel.refreshItems()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearFiltersRequested)) { _ in
            viewModel.clearFilter()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let user = viewModel.currentUser {
                        Text("Welcome back, \(user.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // New Item Button
                Button {
                    showingNewItemSheet = true
                } label: {
                    Label("New Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Filter Bar
            filterBar
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search items...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            
            // Status Filter
            Picker("Status", selection: $viewModel.selectedFilter) {
                Text("All")
                    .tag(nil as ItemStatus?)
                
                ForEach(ItemStatus.allCases, id: \.self) { status in
                    Label(status.displayName, systemImage: status.iconName)
                        .tag(status as ItemStatus?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            
            // Stats
            Spacer()
            
            ForEach(ItemStatus.allCases, id: \.self) { status in
                HStack(spacing: 4) {
                    Image(systemName: status.iconName)
                        .font(.caption)
                    Text("\(viewModel.itemCounts[status] ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(colorForStatus(status))
            }
        }
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LoadingView(message: "Loading items...")
        } else if let error = viewModel.errorMessage {
            ErrorView(
                message: error,
                retryAction: {
                    Task { await viewModel.loadData() }
                },
                dismissAction: {
                    viewModel.dismissError()
                }
            )
        } else if viewModel.filteredItems.isEmpty {
            if viewModel.items.isEmpty {
                EmptyStateView.noItems {
                    showingNewItemSheet = true
                }
            } else {
                EmptyStateView.noSearchResults {
                    viewModel.clearFilter()
                }
            }
        } else {
            itemsList
        }
    }
    
    // MARK: - Items List
    
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredItems) { item in
                    ItemCard(item: item) {
                        selectedItem = item
                    } onStatusChange: { newStatus in
                        Task {
                            await viewModel.updateStatus(for: item, to: newStatus)
                        }
                    } onDelete: {
                        Task {
                            await viewModel.deleteItem(item)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Helpers
    
    private func colorForStatus(_ status: ItemStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .secondary
        }
    }
}

// MARK: - Item Card

struct ItemCard: View {
    
    let item: Item
    let onTap: () -> Void
    let onStatusChange: (ItemStatus) -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            Menu {
                ForEach(ItemStatus.allCases, id: \.self) { status in
                    Button {
                        onStatusChange(status)
                    } label: {
                        Label(status.displayName, systemImage: status.iconName)
                    }
                    .disabled(status == item.status)
                }
            } label: {
                Image(systemName: item.status.iconName)
                    .font(.title2)
                    .foregroundStyle(colorForStatus(item.status))
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                    
                    if item.priority == .high || item.priority == .urgent {
                        Image(systemName: item.priority.iconName)
                            .font(.caption)
                            .foregroundStyle(item.priority == .urgent ? .red : .orange)
                    }
                }
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Tags
                    ForEach(item.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                    
                    Spacer()
                    
                    // Due Date
                    if let dueDate = item.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate, style: .date)
                        }
                        .font(.caption)
                        .foregroundStyle(dueDate < Date() ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            if isHovering {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.1 : 0.05), radius: isHovering ? 8 : 4, y: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onTap()
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
}

// MARK: - Preview

#Preview {
    DashboardView(viewModel: .preview)
        .frame(width: 800, height: 600)
}
