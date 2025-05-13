//
//  User.swift
//  ExamApp
//
//  Created by SARIÇELİK on 8.05.2025.
//

import Foundation
import RealmSwift

class User: Object {
    @objc dynamic var email: String = ""
    @objc dynamic var password: String = ""
}
