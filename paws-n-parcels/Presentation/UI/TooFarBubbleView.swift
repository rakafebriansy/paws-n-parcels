import SwiftUI

struct TooFarBubbleData: Equatable {
    let text: String
    let position: CGPoint
}

struct TooFarBubbleView: View {
    let data: TooFarBubbleData
    
    var body: some View {
        ZStack {
            Image("conversation_blank")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
            
            Text(data.text)
                .font(.custom("ComicRelief", size: 14))
                .foregroundColor(Color(red: 63/255, green: 55/255, blue: 49/255))
                .multilineTextAlignment(.center)
                .frame(width: 110)
                .offset(y: -10)
        }
    }
}
