//
//  ContentView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI
   
struct ContentView: View {
        @StateObject private var dataManager = FlightDataManager()
        @State private var selectedTab = 0
        @State private var showMoreMenu = false

        var body: some View {
            TabView(selection: $selectedTab) {

                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Accueil")
                    }
                    .tag(0)

                AgendaView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Agenda")
                    }
                    .tag(1)

                LogbookView()
                    .tabItem {
                        Image(systemName: "book.closed")
                        Text("Logbook")
                    }
                    .tag(2)
                
                WeightBalanceView()
                    .tabItem {
                        Image(systemName: "scalemass")
                        Text("M&C")
                    }
                    .tag(3)


                // Onglet "Plus"
                Color.clear
                    .tabItem {
                        Image(systemName: "ellipsis.circle.fill")
                        Text("Plus")
                    }
                    .tag(99)
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 99 {
                    DispatchQueue.main.async {
                        showMoreMenu = true
                        selectedTab = 0
                    }
                }
            }
            .sheet(isPresented: $showMoreMenu) {
                NavigationStack {
                    MoreMenuView()
                }
            }

            .environmentObject(dataManager)
            .accentColor(.blue)
        }
    }

// MARK: - Aviation Menu View

struct AviationMenuView: View {
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            Text("Navigation")
                .font(.headline)
                .padding(.bottom, 10)

            menuButton(
                title: "Statistiques",
                icon: "chart.bar.fill",
                tag: 4
            )

            menuButton(
                title: "Réglages",
                icon: "gearshape.fill",
                tag: 5
            )

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func menuButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
            dismiss()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }
}

struct MoreMenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            NavigationLink {
                StatsView()
            } label: {
                Label("Statistiques", systemImage: "chart.bar.fill")
            }

            NavigationLink {
                SettingsView()
            } label: {
                Label("Réglages", systemImage: "gear")
            }
        }
        .navigationTitle("Navigation")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }
}


