import SwiftUI

struct TutorialBubbleData: Equatable {
    let text: String
    let position: CGPoint
    let isInTopZone: Bool
}

struct TutorialBubbleView: View {
    let data: TutorialBubbleData
    
    var body: some View {
        ZStack {
            Image(data.isInTopZone ? "conversation_blank_2" : "conversation_blank")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
            
            Text(data.text)
                .font(.custom("ComicRelief", size: 14))
                .foregroundColor(Color(red: 63/255, green: 55/255, blue: 49/255))
                .multilineTextAlignment(.center)
                .frame(width: 110)
                // Shift text to strictly center it inside the round body of the bubble, ignoring the tail.
                .offset(y: data.isInTopZone ? 5 : -5)
        }
    }
}
