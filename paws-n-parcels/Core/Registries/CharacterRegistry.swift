//
//  CharacterRegistry.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 16/05/26.
//
import Foundation

struct CharacterInfo {
    let name: String
    let assetName: String
    let housePosition: CGPoint
}

struct CharacterRegistry {
    
    static let all: [CharacterInfo] = [
        CharacterInfo(name: "Joko", assetName: "rabbit", housePosition: CGPoint(x: 19, y: 7)),
        CharacterInfo(name: "Susilo", assetName: "cat", housePosition: CGPoint(x: 17, y: 7)),
        CharacterInfo(name: "Santoso", assetName: "beaver", housePosition: CGPoint(x: 27, y: 9)),
        CharacterInfo(name: "Purnomo", assetName: "turtle", housePosition: CGPoint(x: 10, y: 25)),
        CharacterInfo(name: "Capybara", assetName: "capybara", housePosition: CGPoint(x: 19, y: 23))
    ]
    
    // Helper function untuk mencari nama aset berdasarkan nama hewan
    static func getAsset(for name: String) -> String? {
        return all.first(where: { $0.name == name })?.assetName
    }
}
