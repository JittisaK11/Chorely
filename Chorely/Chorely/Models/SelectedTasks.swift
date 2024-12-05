//
//  SelectedTasks.swift
//  Chorely
//
//  Created by Sara Lin on 11/21/24.
//

import Foundation
import Combine

class SelectedTasks: ObservableObject {
    @Published var selectedTasks: [ChoreTask] = []
}
