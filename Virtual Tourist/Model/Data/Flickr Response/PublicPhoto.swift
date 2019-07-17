//
//  PublicPhoto.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import Foundation

struct PublicPhoto: Decodable {
    let id: String
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case url = "url_n"
        case title
    }
}
