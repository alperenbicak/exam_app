//
//  AppState.swift
//  ExamApp
//
//  Created by SARIÇELİK on 10.05.2025.
//

import Foundation

class AppState {
    static let shared = AppState()
    var currentUserEmail: String?
    private init() {}
}
