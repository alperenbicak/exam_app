//
//  Exam.swift
//  ExamApp
//
//  Created by SARIÇELİK on 8.05.2025.
//

import Foundation
import RealmSwift

class Exam: Object {
    @objc dynamic var id: String = UUID().uuidString  // 🔥 Bildirim için kullanılacak ID
    @objc dynamic var subject: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var ownerEmail: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}
