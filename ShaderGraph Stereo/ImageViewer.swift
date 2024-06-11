//
//  ImageViewer.swift
//  ShaderGraph Stereo
//
//  Created by Hal Mueller on 6/3/24.
//

import SwiftUI

struct ImageViewer: View {
    @State var selectedPair: StereoPair = .artRoom
    var body: some View {
        VStack {
            StereoView(imagePair: selectedPair)
            Spacer()
            Button("Next") {
                if selectedPair == .artRoom {
                    selectedPair = .chess
                } else if selectedPair == .chess {
                    selectedPair = .curule
                } else if selectedPair == .curule {
                    selectedPair = .nasaAmes
                } else {
                    selectedPair = .artRoom
                }
            }
        }
    }
}

#Preview {
    ImageViewer()
}
