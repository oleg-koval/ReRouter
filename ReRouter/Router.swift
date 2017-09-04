//
//  Router.swift
//  ReRouter
//
//  Created by Oleksii on 04/09/2017.
//  Copyright © 2017 WeAreReasonablePeople. All rights reserved.
//

import RxSwift
import ReactiveReSwift

struct RouteChange<Root: CoordinatorType> {
    let remove: [NavigationItem]
    let add: [NavigationItem]
    let new: RouteHandler<Root>
    
    init(handler: RouteHandler<Root>, old: Path<Root.Key>, new: Path<Root.Key>) {
        let same = old.commonLength(with: new)
        remove = handler.remove(same: same)
        add = handler.add(path: new, same: same)
        self.new = RouteHandler(root:handler.root, items: handler.items[0..<same] + add)
    }
}

struct RouteHandler<Root: CoordinatorType> {
    let root: Root
    let items: [NavigationItem]
    
    func remove(same: Int) -> [NavigationItem] {
        return Array(items[same..<items.count])
    }
    
    func add(path: Path<Root.Key>, same: Int) -> [NavigationItem] {
        let initial = same > 0 ? items[same - 1].target as! AnyCoordinator : AnyCoordinator(root)
        return path
            .sequence[same..<path.sequence.count]
            .lazy
            .map(AnyIdentifier.init)
            .reduce((Optional.some(initial), [NavigationItem]()), { (item, current) in
                let new = item.0!.item(for: current)
                return (new.target as? AnyCoordinator, item.1 + [new])
            }).1
    }
}

public final class NavigationRouter<Root: CoordinatorType, State: NavigatableState> where Root.Key == State.Initial {
    let store: Store<Variable<State>>
    let disposeBag = DisposeBag()
    var handler: RouteHandler<Root>
    
    init(_ root: Root, store: Store<Variable<State>>) {
        self.store = store
        handler = RouteHandler(root: root, items: [])
    }
    
    func setupUpdate() {
        store.observable
            .asObservable()
            .map({ $0.path })
            .distinctUntilChanged()
            .scan((Path([]), Path([])), accumulator: { ($0.1, $1) })
            .map({ [unowned self] in RouteChange(handler: self.handler, old: $0.0, new: $0.1) })
            .do(onNext: { [unowned self] in self.handler = $0.new })
            .map({ change -> [Observable<Void>] in
                let remove = change.remove.reversed().map({ $0.action(for: .pop, animated: true) })
                let add = change.add.map({ $0.action(for: .push, animated: true) })
                return remove + add
            })
            .flatMap({ Observable.concat($0) })
            .subscribe()
            .disposed(by: disposeBag)
    }
}