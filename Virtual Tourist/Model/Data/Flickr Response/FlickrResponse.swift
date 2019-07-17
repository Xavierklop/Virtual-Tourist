//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import Foundation

struct FlickrResponse: Decodable {
    let photos: PublicPhotos
    let stat: String
}
