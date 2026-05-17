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
    var req: Request
    
    @Bindable var activeRelationship: AnimalRelationship
    
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
                    Text("Relationship Points: \(activeRelationship.friendshipPoint)")
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
                    PickUpSuccessAlertView(message: req.sender.pickupDialog)
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
        let result = deliverySystem.deliverPackage(for: playerEntity, relationships: [activeRelationship])
        
        if result.pointsAdded > 0 {
            self.pointsEarned = result.pointsAdded
            
            withAnimation(.spring()) {
                showRelationshipPointsAlert = true
                showDeliverySuccessAlert = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) {
                    showRelationshipPointsAlert = false
                    showDeliverySuccessAlert = false
                }
                
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Animal.self, AnimalRelationship.self, Collectible.self, Request.self, configurations: config)
    let context = container.mainContext
    
    let kelinci = Animal(name: "Kelinci", assetName: "rabbit", pickupDialog: "Wow, thanks a ton! Please deliver it in a flash!")
    let beruang = Animal(name: "Beruang", assetName: "bear", pickupDialog: "Thanks for picking this up! Make sure it arrives safely.")
    let suratPalsu = PackageLetter(
        sender: kelinci.name,
        recipient: beruang.name,
        messageBody: "Hai Beruang, ini ada sedikit madu hutan segar untukmu. Semoga kamu suka ya!"
    )
    let relasiPalsu = AnimalRelationship(friendOne: kelinci, friendTwo: beruang)
    let requestPalsu = Request(sender: kelinci, receiver: beruang, letter: suratPalsu)
    
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
