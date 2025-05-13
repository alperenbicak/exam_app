    //
    //  AppDelegate.swift
    //  ExamApp
    //
    //  Created by SARIÇELİK on 8.05.2025.
    //

    import UIKit
    import CoreData
    import RealmSwift   // 🟢 RealmSwift ekledik

    @main
    class AppDelegate: UIResponder, UIApplicationDelegate {

        // MARK: - Uygulama Başlatma

        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

            let config = Realm.Configuration(
                schemaVersion: 2,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: "Exam") { oldObject, newObject in
                            newObject!["id"] = UUID().uuidString
                        }
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = config

            return true
        }


        // MARK: UISceneSession Lifecycle

        func application(_ application: UIApplication,
                         configurationForConnecting connectingSceneSession: UISceneSession,
                         options: UIScene.ConnectionOptions) -> UISceneConfiguration {
            return UISceneConfiguration(name: "Default Configuration",
                                        sessionRole: connectingSceneSession.role)
        }

        func application(_ application: UIApplication,
                         didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
            // Scene oturumları atıldığında temizleme işlemleri yapılabilir
        }

        // MARK: - Core Data stack

        lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "ExamApp")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
                }
            })
            return container
        }()

        // MARK: - Core Data Saving support

        func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved Core Data error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
