//
//  StereoPair.swift
//
//  Created by Hal Mueller on 06/03/24.
//

import Foundation

struct StereoPair: Codable, Identifiable {
    let id: String
    let leftImageName: String
    let rightImageName: String
    let comment: String
    
    init(id: String, leftImageName: String, rightImageName: String, comment: String) {
        self.id = id
        self.leftImageName = leftImageName
        self.rightImageName = rightImageName
        self.comment = comment
    }
    
    static func == (lhs: StereoPair, rhs: StereoPair) -> Bool {
        lhs.id == rhs.id
    }
        
    // Source: https://vision.middlebury.edu/stereo/data/. Specifically, https://vision.middlebury.edu/stereo/data/scenes2021/.
    // Paper:
    // D. Scharstein, H. Hirschmüller, Y. Kitajima, G. Krathwohl, N. Nesic, X. Wang, and P. Westling. High-resolution stereo datasets with subpixel-accurate ground truth. http://www.cs.middlebury.edu/~schar/papers/datasets-gcpr2014.pdf
    // In German Conference on Pattern Recognition (GCPR 2014), Münster, Germany, September 2014.
    static let artRoom = StereoPair(id: "Art Room", leftImageName: "artroom2im0", rightImageName: "artroom2im1", comment: "Art room")
    static let chess = StereoPair(id: "Chess", leftImageName: "chess2im0", rightImageName: "chess2im1", comment: "Chess")
    static let curule = StereoPair(id: "Curule", leftImageName: "curule1im0", rightImageName: "curule1im1", comment: "Curule")
    static let nasaAmes = StereoPair(id: "Ames", leftImageName: "amesLeft", rightImageName: "amesRight", comment: "NASA Ames Stereo Pipeline synthetic image")
}
