//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 08.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
