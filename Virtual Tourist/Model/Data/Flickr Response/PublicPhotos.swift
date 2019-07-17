//
//  PublicPhotos.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import Foundation

struct PublicPhotos: Decodable {
    let pages: Int
    let photo: [PublicPhoto]
}
