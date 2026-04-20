//
//  AppDelegate.swift
//  142GenstrilbriKexzebul
//
//  Created by Roman on 4/20/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: FinanceQuickActionKind.openBudget.rawValue,
                localizedTitle: "Budget session",
                localizedSubtitle: "Open the budget activity",
                icon: UIApplicationShortcutIcon(systemImageName: "chart.pie"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: FinanceQuickActionKind.openHistoryAdd.rawValue,
                localizedTitle: "History",
                localizedSubtitle: "Review and add entries",
                icon: UIApplicationShortcutIcon(systemImageName: "clock"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: FinanceQuickActionKind.openGoals.rawValue,
                localizedTitle: "Goals",
                localizedSubtitle: "Check savings goals",
                icon: UIApplicationShortcutIcon(systemImageName: "target"),
                userInfo: nil
            )
        ]
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: .financeQuickAction, object: shortcutItem.type)
        completionHandler(true)
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
