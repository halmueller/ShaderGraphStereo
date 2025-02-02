//
//  StereoView.swift
//  Apollo
//
//  Created by Hal Mueller on 4/12/24.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct StereoView: View {
    var imagePair: StereoPair
    
    @State private var stereoMaterial: ShaderGraphMaterial?
    @State private var leftTexture: TextureResource?
    @State private var rightTexture: TextureResource?
    
    @Environment(\.openWindow) var openWindow
    
    /// empirically determined
    let planeSideLength = Float(0.352800)
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(imagePair.comment)
                    .font(.title)
                let _ = Self._printChanges()
                RealityView { content in // this closure is asynchronus
                    print("\(#function) make \(imagePair.id)")
                    do {
                        stereoMaterial = try await ShaderGraphMaterial(named: "/Root/StereoImage",
                                                               from: "StereoMaker.usda",
                                                               in: realityKitContentBundle)
                        updateStereo(content: content)
                    } catch {
                        print("\(#function) unhandled error \(error.localizedDescription) \(imagePair.id)")
                    }
                } update: { content in // this closure is synchronous
                    print("\(#function) update \(imagePair.id)")
                    updateStereo(content: content)
                }
            }
        }
    }
}

extension StereoView {
    func updateStereo(content: RealityViewContent) {
        do {
            if var stereoMaterial {
                let leftTexture = try TextureResource.load(named: imagePair.leftImageName)
                try stereoMaterial.setParameter(name: "LeftImage", value: .textureResource(leftTexture))
                
                let rightTexture = try TextureResource.load(named: imagePair.rightImageName)
                try stereoMaterial.setParameter(name: "RightImage", value: .textureResource(rightTexture))
                
                // TODO: This locks us in to one aspect ratio, that of the first image viewed. Hardcode this, or perhaps tweak the Plane's transform to match varying aspect ratios.
                let planeWidth: Float
                let planeHeight: Float
                let aspectRatio =  Float(rightTexture.height)/Float(rightTexture.width)
                if aspectRatio < 1 {
                    planeWidth = planeSideLength
                    planeHeight = planeSideLength * aspectRatio
                } else {
                    planeWidth = planeSideLength * aspectRatio
                    planeHeight = planeSideLength
                }
                print("aspectRatio \(aspectRatio) texture w/h: \(rightTexture.width) \(rightTexture.height) plane w/h \(planeWidth) \(planeHeight)")
                
                // In an even earlier version, I was removing the imagePlane and recreating it. On each pass. Ouch.
                if let imagePlane = content.entities.first as? ModelEntity {
                    // !!!: Replacing the materials array leaks memory. It leaks more on device.
                    imagePlane.model?.materials = [stereoMaterial]
                } else {
                    // FIXME: we keep this Plane Entity around for duration of the View, without resizing, even if images vary in size.
                    let newPlane = ModelEntity(mesh: .generatePlane(width: planeWidth, height: planeHeight))
                    newPlane.model?.materials = [stereoMaterial]
                    // TODO: try adjusting the transform to match image aspect.
                    // Z value of 0 produces terrible Z fighting
                    newPlane.transform.translation = [0, 0, 0.01]
                    content.add(newPlane)
                }
            } else {
                print("\(#function) no stereo material \(imagePair.id)")
            }
        } catch {
            print("\(#function) unhandled error \(error.localizedDescription) \(imagePair.id)")
        }
    }
}

#Preview {
    StereoView(imagePair: StereoPair.chess)
}
