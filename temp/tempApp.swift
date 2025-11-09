//
//  tempApp.swift
//  temp
//
//  Created by Norbert on 08/11/2025.
//

import SwiftUI
import SwiftData

@available(iOS 17, *)
@main
struct tempApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            
            TabView {
                
                UserMapWithPolygons()
                    .tabItem {
                    Label("Map", systemImage: "map")
                }
                
//                ContentView()
//                    .tabItem {
//                    Label("", systemImage: "map")
//                }
                UserView()
                    .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
                
                
                
                
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

