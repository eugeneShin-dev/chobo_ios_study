import SwiftUI
import Combine

public typealias Effect<Action> = () -> Action?

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

public final class Store<Value, Action>: ObservableObject {
    @Published public private(set) var value: Value
    private var cancellable: Cancellable?
    
    let reducer: Reducer<Value, Action>
    public init(initialValue: Value, reducer: @escaping Reducer<Value, Action>) {
      self.value = initialValue
      self.reducer = reducer
    }
    
    public func send(_ action: Action) {
      let effects = self.reducer(&self.value, action)
      effects.forEach { effect in
        if let action = effect() {
          self.send(action)
        }
      }
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            }
        )
        localStore.cancellable = self.$value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        return localStore
    }
}

public func combine<Value, Action>(
  _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {

  return { value, action in
    let effects = reducers.flatMap { $0(&value, action) }
    return effects
//    return { () -> Action? in
//        var finalAction: Action?
//        for effect in effects {
//            let action = effect()
//            if let action = action {
//                finalAction = action
//            }
//        }
//        return finalAction
//    }
  }
}

public func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
  _ reducer: @escaping Reducer<LocalValue, LocalAction>,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {

  return { globalValue, globalAction in
    guard let localAction = globalAction[keyPath: action] else { return [] }
    let localEffects = reducer(&globalValue[keyPath: value], localAction)
    return localEffects.map { localEffect in
      return { () -> GlobalAction? in
        guard let localAction = localEffect() else { return nil }
        var globalAction = globalAction
        globalAction[keyPath: action] = localAction
        return globalAction
      }
    }
//    return effect
  }
}

public func logging<Value, Action>(
  _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    return { value, action in
      let effects = reducer(&value, action)
      let newValue = value
      return [{
        print("Action: \(action)")
        print("Value:")
        dump(newValue)
        print("---")
        return nil
      }] + effects
    }
}
