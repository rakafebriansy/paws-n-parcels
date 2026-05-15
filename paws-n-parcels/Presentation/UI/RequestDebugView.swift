////
////  RequestDebugView.swift
////  paws-n-parcels
////
////  Created by Felicia Joshlyn Purnomo on 12/05/26.
////
//
//import SwiftUI
//import SwiftData
//import GameplayKit
//
//struct RequestDebugView: View {
//    @ObservedObject var system: RequestSystem
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("System Metrics") {
//                    LabeledContent("Next Spawn", value: String(format: "%.1f s", system.spawnTimer))
//                    LabeledContent("Active Letters", value: "\(system.requestComponentSystem.components.count)/\(system.maxRequests)")
//                    
//                    Button(action: { system.generateAndSpawnRequest() }) {
//                        HStack {
//                            if system.isGenerating { ProgressView().padding(.trailing, 5) }
//                            Text(system.isGenerating ? "AI is writing..." : "Force Manual Spawn")
//                        }
//                    }
//                    .disabled(system.isGenerating || system.requestComponentSystem.components.count >= system.maxRequests)
//                }
//                
//                Section("Main 5 House Status") {
//                    ForEach(system.allHouses.filter { $0.characterName != nil }, id: \.characterName) { house in
//                        HStack {
//                            VStack(alignment: .leading) {
//                                Text(house.characterName ?? "Unknown")
//                                    .font(.headline)
//                                
//                                if let req = house.component(ofType: RequestComponent.self)?.requestData {
//                                    Text("Recipient: \(req.receiver.name)")
//                                        .font(.caption).foregroundStyle(.blue)
//                                } else {
//                                    Text("Status: Waiting").font(.caption).foregroundStyle(.secondary)
//                                }
//                            }
//                            Spacer()
//                            Image(systemName: house.component(ofType: RequestComponent.self) != nil ? "envelope.fill" : "house")
//                                .foregroundStyle(house.component(ofType: RequestComponent.self) != nil ? .yellow : .gray.opacity(0.5))
//                        }
//                    }
//                }
//                
//                Section("Database Commands") {
//                    Button("Sync (Save State)") { system.syncToDatabase() }
//                    Button("Wipe All", role: .destructive) {
//                        system.allHouses.forEach { $0.removeComponent(ofType: RequestComponent.self) }
//                        system.refreshID = UUID()
//                    }
//                }
//            }
//            .navigationTitle("P&P Inspector")
//            .id(system.refreshID) // IMPORTANT: This forces the list to redraw
//        }
//    }
//}
