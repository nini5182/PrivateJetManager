//
//  RemarkTagPicker.swift
//  PrivateJetManager
//
//  Created by charles chauve on 25/01/2026.
//

import SwiftUI

struct RemarkTagPicker: View {
    @Binding var selectedTag: RemarkTag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priorité de la remarque")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(RemarkTag.allCases, id: \.self) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTag == tag,
                        action: { selectedTag = tag }
                    )
                }
            }
        }
    }
}

struct TagButton: View {
    let tag: RemarkTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                    .font(.caption)
                
                Text(tag.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? tag.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? tag.color : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? tag.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RemarkTagPicker(selectedTag: .constant(.info))
        .padding()
}
