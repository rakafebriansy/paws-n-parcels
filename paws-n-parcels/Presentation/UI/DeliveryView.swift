//
//  DeliveryView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 07/05/26.
//

import SwiftUI
import SwiftData
import GameplayKit

struct DeliveryView: View {
    var playerEntity: GKEntity
    var deliverySystem: DeliverySystem
    var req: Requests
    
    @Bindable var activeRelationship: AnimalFriendRelationship
    
    @State private var showRelationshipPointsAlert: Bool = false
    @State private var showPickUpSuccessAlert: Bool = false
    @State private var showDeliverySuccessAlert: Bool = false
    @State private var showNewCollectibleAlert: Bool = false
    
    @State private var hasPickedUp: Bool = false
    
    @State private var pointsEarned: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("Paket dari: \(req.sender.name)")
                    Text("Untuk: \(req.receiver.name)")
                    Divider().padding(.vertical, 5)
                    Text("Relationship Points: \(activeRelationship.friendshipPoints)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button("Ambil Paket") {
                    deliverySystem.pickUpPackage(request: req, for: playerEntity)
                    hasPickedUp =  true
                    
                    withAnimation(.spring()) {
                        showPickUpSuccessAlert = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut) {
                            showPickUpSuccessAlert = false
                        }
                        
                    }
                }
                .disabled(hasPickedUp)
                
                Button("Antar ke Rumah") {
                    processDelivery()
                    hasPickedUp = false
                }
                .disabled(!hasPickedUp)

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showPickUpSuccessAlert || showDeliverySuccessAlert || showNewCollectibleAlert {
                Color.black.opacity(0.3).ignoresSafeArea().transition(.opacity).zIndex(1)
            }
            
            ZStack {
                if showPickUpSuccessAlert {
                    PickUpSuccessAlertView()
                }
                
                if showDeliverySuccessAlert {
                    DeliverySuccessAlertView()
                }
                
                if showNewCollectibleAlert {
                    NewCollectibleAlertView(isPresented: $showNewCollectibleAlert)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .zIndex(2)
            
            if showRelationshipPointsAlert {
                RelationshipPointsAlertView(points: pointsEarned)
                    .zIndex(3)
            }
        }
    }
    
    private func processDelivery() {
        let result = deliverySystem.deliverPackage(for: playerEntity)
        
        if result.pointsAdded > 0 {
            self.pointsEarned = result.pointsAdded
            
            // 1. Munculkan Relationship Poin dan Alert Pengantaran bersamaan
            withAnimation(.spring()) {
                showRelationshipPointsAlert = true
                showDeliverySuccessAlert = true
            }
            
            // 2. Hilangkan keduanya setelah 1.5 detik
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) {
                    showRelationshipPointsAlert = false
                    showDeliverySuccessAlert = false
                }
                
                // 3. Jika naik level, tunggu modal pengantaran hilang, baru munculkan Alert New Collectible
                if result.isLevelUp {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showNewCollectibleAlert = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    // database palsu
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AnimalFriend.self, AnimalFriendRelationship.self, Collectible.self, Requests.self, configurations: config)
    let context = container.mainContext
    
    // data hewan dan request palsu
    let kelinci = AnimalFriend(name: "Kelinci", assetName: "rabbit")
    let beruang = AnimalFriend(name: "Beruang", assetName: "bear")
    let relasiPalsu = AnimalFriendRelationship(friendOne: kelinci, friendTwo: beruang)
    let requestPalsu = Requests(sender: kelinci, receiver: beruang)
    
    context.insert(kelinci)
    context.insert(beruang)
    context.insert(relasiPalsu)
    context.insert(requestPalsu)
    
    // Entitas dan Sistem palsu
    let dummyGoldie = GoldieEntity()
    let dummySystem = DeliverySystem()
    dummySystem.setup(context: context)
    
    return DeliveryView(playerEntity: dummyGoldie, deliverySystem: dummySystem, req: requestPalsu, activeRelationship: relasiPalsu)
        .modelContainer(container)
}
