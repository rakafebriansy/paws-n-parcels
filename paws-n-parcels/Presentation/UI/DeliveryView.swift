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
    @Query private var allFriends: [AnimalFriend]
    @Query private var allRelationships: [AnimalFriendRelationship]
    
    var playerEntity: GKEntity
    var deliverySystem: DeliverySystem
    var req: Request
    
    @Bindable var activeRelationship: AnimalFriendRelationship
    
    // State untuk mengontrol Tampilan UI
    @State private var showPointsToast: Bool = false
    @State private var showDeliveryModal: Bool = false
    @State private var showCollectibleModal: Bool = false
    @State private var pointsEarned: Int = 0
    
    let sageGreen = Color(red: 197/255, green: 218/255, blue: 179/255)
    let creamBackground = Color(red: 0.98, green: 0.96, blue: 0.9)
    let brownText = Color(red: 0.4, green: 0.25, blue: 0.15)
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    let senderName = allFriends.first(where: { $0.id == req.senderId })?.name ?? "Unknown"
                    let receiverName = allFriends.first(where: { $0.id == req.receiverId })?.name ?? "Unknown"
                    Text("Paket dari: \(senderName)")
                    Text("Untuk: \(receiverName)")
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
                }
                
                Button("Antar ke Rumah") {
                    processDelivery()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
            if showDeliveryModal || showCollectibleModal {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            ZStack {
                // Modal A: Pengantaran Sukses
                if showDeliveryModal {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .bold()
                        
                        Text("Package has been delivered!")
                            .font(.headline)
                            .bold()
                            .foregroundColor(brownText)
                    }
                    .padding(40)
                    .background(creamBackground)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(brownText, lineWidth: 3))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Modal B: New Collectible
                if showCollectibleModal {
                    VStack(spacing: 20) {
                        Text("New Collectible Unlocked!")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(brownText)
                        
                        Button("Tutup") {
                            withAnimation(.easeInOut) {
                                showCollectibleModal = false
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(30)
                    .background(creamBackground)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(brownText, lineWidth: 3))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .zIndex(2)
            
            
            if showPointsToast {
                Text("+\(pointsEarned) Relationship Points")
                    .font(.headline)
                    .foregroundColor(brownText)
                    .padding()
                    .background(sageGreen)
                    .cornerRadius(25)
                    .shadow(radius: 3)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(3)
            }
        }
    }
    
    private func processDelivery() {
        let result = deliverySystem.deliverPackage(for: playerEntity, allRelationships: allRelationships)
        
        if result.pointsAdded > 0 {
            self.pointsEarned = result.pointsAdded
            
            // 1. Munculkan Toast Poin dan Modal Pengantaran bersamaan
            withAnimation(.spring()) {
                showPointsToast = true
                showDeliveryModal = true
            }
            
            // 2. Hilangkan keduanya setelah 1.5 detik
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) {
                    showPointsToast = false
                    showDeliveryModal = false
                }
                
                // 3. Jika naik level, tunggu modal pengantaran hilang, baru munculkan modal New Collectible
                if result.isLevelUp {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showCollectibleModal = true
                        }
                    }
                }
            }
        }
    }
}
