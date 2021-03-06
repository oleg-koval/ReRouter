//
//  AppCoordinator.swift
//  ReRouterDemo
//
//  Created by Oleksii on 31/10/2017.
//  Copyright © 2017 WeAreReasonablePeople. All rights reserved.
//

import Foundation
import ReRouter

let storyboard = UIStoryboard(name: "Main", bundle: nil)

final class AppCoordinator: CoordinatorType {
    enum Key: PathKey {
        case signIn
        case list
    }
    
    func item(for key: Key) -> NavigationItem {
        switch key {
        case .signIn:
            let target = storyboard.instantiateViewController(withIdentifier: "signIn")
            return NavigationItem(self, target, push: { (animated, source, target, completion) in
                UIApplication.shared.keyWindow?.rootViewController = target
                completion()
            }, pop: { (_, _, _, completion) in
                completion()
            })
        case .list:
            return NavigationItem(self, ListCoordinator(), push: { (animated, source, target, completion) in
                UIApplication.shared.keyWindow?.rootViewController = target.controller
                completion()
            }, pop: { (_, _, _, completion) in
                completion()
            })
        }
    }
}
