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
    
    @State private var stereo: ShaderGraphMaterial?
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
                        stereo = try await ShaderGraphMaterial(named: "/Root/StereoImage",
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
        // !!!: Saved state in the RV Content is an ugly hack that saves a bunch of memory leakage.
        if let imagePlane = content.entities.first as? ModelEntity,
           imagePlane.name == imagePair.id { return }
        do {
            // Each pass through this closure leaks memory. Don't do it if we don't have to. This function is called for every
            // Window resize event. Don't reload the textures if it's the same one as last time.
            if var stereo {
                let leftTexture = try TextureResource.load(named: imagePair.leftImageName)
                try stereo.setParameter(name: "LeftImage", value: .textureResource(leftTexture))
                
                let rightTexture = try TextureResource.load(named: imagePair.rightImageName)
                try stereo.setParameter(name: "RightImage", value: .textureResource(rightTexture))
                
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
                
                if let imagePlane = content.entities.first as? ModelEntity {
                    // !!!: Replacing the materials array leaks memory. It leaks more on device.
                    imagePlane.model?.materials = [stereo]
                    imagePlane.name = imagePair.id
                } else {
                    // FIXME: we keep this Plane Entity around for duration of the View, without resizing, even if images vary in size.
                    let newPlane = ModelEntity(mesh: .generatePlane(width: planeWidth, height: planeHeight))
                    newPlane.name = imagePair.id
                    newPlane.model?.materials = [stereo]
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
