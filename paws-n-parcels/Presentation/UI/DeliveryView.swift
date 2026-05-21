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
    @State private var unlockedItem: Collectible? = nil
    
    @State private var hasPickedUp: Bool = false
    @State private var pendingNextLevel: Bool = false
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
            
            ZStack{
                if showPickUpSuccessAlert || showDeliverySuccessAlert || showNewCollectibleAlert {
                    Color.black.opacity(0.3).ignoresSafeArea().transition(.opacity).zIndex(1)
                    
                    ZStack {
                        if showPickUpSuccessAlert {
                            PickUpSuccessAlertView(message: req.sender.pickupDialog)
                        }
                        
                        if showDeliverySuccessAlert {
                            DeliverySuccessAlertView()
                        }
                        
                        if showNewCollectibleAlert, let itemToShow = unlockedItem {
                            NewCollectibleAlertView(isPresented: $showNewCollectibleAlert, item: itemToShow)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .zIndex(2)
                }
            }
            .onTapGesture { closeAllModals() }
            
            if showRelationshipPointsAlert {
                RelationshipPointsAlertView(points: pointsEarned) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRelationshipPointsAlert = false
                    }
                }
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
            
            if result.isLevelUp {
                pendingNextLevel = true
                unlockedItem = result.unlockedItem
            }
            
        }
    }
    
    private func closeAllModals() {
        withAnimation(.easeInOut) {
            showPickUpSuccessAlert = false
            if showDeliverySuccessAlert{
                showDeliverySuccessAlert = false
                showRelationshipPointsAlert = false
                
                if pendingNextLevel{
                    withAnimation(.spring()) {
                        showNewCollectibleAlert = true
                    }
                }
                pendingNextLevel = false
            }
        }
    }
}


#Preview {
    let makePreview = { () -> AnyView in
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Animal.self, AnimalRelationship.self, Collectible.self, Request.self, configurations: config)
        let context = container.mainContext
        
        let kelinci = Animal(name: "Kelinci", assetName: "rabbit", pickupDialog: "Oh, you're here! I’ve been waiting to get this moving. Please deliver it in a flash, okay? Merci—now hop to it!")
        let beruang = Animal(name: "Beruang", assetName: "bear", pickupDialog: "Thanks for picking this up! Make sure it arrives safely.")
        let relasiPalsu = AnimalRelationship(friendOne: kelinci, friendTwo: beruang)
        let letterPalsu = PackageLetter(sender: "Kelinci", recipient: "Beruang", messageBody: "Oh, you're here! I’ve been waiting to get this moving.")
        let requestPalsu = Request(sender: kelinci, receiver: beruang, letter: letterPalsu)
        
        context.insert(kelinci)
        context.insert(beruang)
        context.insert(relasiPalsu)
        context.insert(requestPalsu)
        
        let dummyGoldie = PlayerEntity(node: SKNode())
        let dummySystem = DeliverySystem()
        
        return AnyView(
            DeliveryView(playerEntity: dummyGoldie, deliverySystem: dummySystem, req: requestPalsu, activeRelationship: relasiPalsu)
                .modelContainer(container)
        )
    }
    
    return makePreview()
}
