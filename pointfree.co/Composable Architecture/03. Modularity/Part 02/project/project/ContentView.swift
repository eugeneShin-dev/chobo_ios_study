//
//  ContentView.swift
//  project
//
//  Created by Choi SeungHyuk on 2020/11/02.
//

import SwiftUI
import ComposableArchiteture
import FavoritePrimes
import Counter
import PrimeModal

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                  "Counter demo",
                  destination: CounterView(
                    store: self.store
                      .view { ($0.count, $0.favoritePrimes) }
                  )
                )
                NavigationLink(
                  "Favorite primes",
                  destination: FavoritePrimesView(
                    store: self.store.view { $0.favoritePrimes }
                  )
                )
            }
            .navigationBarTitle("State management")
        }
    }
}

//class AppState: ObservableObject {
//    @Published var count: Int = 0
//    @Published var favoritePrimes: [Int] = []
//    @Published var loggedInUser: User?
//    @Published var activityFeed: [Activity] = []
//
//    struct Activity {
//      let timestamp: Date
//      let type: ActivityType
//
//      enum ActivityType {
//        case addedFavoritePrime(Int)
//        case removedFavoritePrime(Int)
//      }
//    }
//
//    struct User {
//      let id: Int
//      let name: String
//      let bio: String
//    }
//}
struct AppState {
  var count = 0
  var favoritePrimes: [Int] = []
  var activityFeed: [Activity] = []
  var loggedInUser: User? = nil

  struct Activity {
    let type: ActivityType
    let timestamp = Date()

    enum ActivityType {
      case addedFavoritePrime(Int)
      case removedFavoritePrime(Int)
    }
  }

  struct User {
    let id: Int
    let name: String
    let bio: String
  }
}

extension AppState {
    var primeModal: PrimeModalState {
        get {
            PrimeModalState(
                count: self.count,
                favoritePrimes: self.favoritePrimes
            )
        }
        set {
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
        }
    }
}

//extension AppState {
//  var favoritePrimesState: FavoritePrimesState {
//    get {
//      return FavoritePrimesState(
//        favoritePrimes: self.favoritePrimes,
//        activityFeed: self.activityFeed
//      )
//    }
//    set {
//      self.activityFeed = newValue.activityFeed
//      self.favoritePrimes = newValue.favoritePrimes
//    }
//  }
//}


enum AppAction {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
  case favoritePrimes(FavoritePrimesAction)

    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }
    
    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
    
    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }
}

func activityFeed(
  _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {

  return { state, action in
    switch action {
    case .counter:
      break

    case .primeModal(.removeFavoritePrimeTapped):
      state.activityFeed.append(
        .init(type: .removedFavoritePrime(state.count))
      )

    case .primeModal(.saveFavoritePrimeTapped):
      state.activityFeed.append(
        .init(type: .addedFavoritePrime(state.count))
      )

    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
      for index in indexSet {
        state.activityFeed.append(
          .init(type: .removedFavoritePrime(state.favoritePrimes[index]))
        )
      }
    }
    reducer(&state, action)
  }
}

struct _KeyPath<Root, Value> {
  let get: (Root) -> Value
  let set: (inout Root, Value) -> Void
}

//let action = AppAction.favoritePrimes(.deleteFavoritePrimes([1]))
//let favoritePrimes: FavoritePrimesAction?
//switch action {
//case let .favoritePrimes(action):
//    favoritePrimes = action
//default:
//    favoritePrimes = nil
//}

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.primeModal, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)

let appReducer = pullback(_appReducer, value: \.self, action: \.self)

typealias CounterViewState = (count: Int, favoritePrimes: [Int])

struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, AppAction>
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: PrimeAlert?
    @State var isNthPrimeButtonDisabled = false
    
    var body: some View {
        VStack {
            HStack {
                Button("-") { self.store.send(.counter(.decrTapped)) }
                Text("\(self.store.value.count)")
                Button("+") { self.store.send(.counter(.incrTapped)) }
            }
            Button(action: { self.isPrimeModalShown = true }) {
                Text("Is this prime?")
            }
            Button(action: nthPrimeButtonAction) {
              Text("What's the \(ordinal(self.store.value.count)) prime?")
            }
            .disabled(isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationBarTitle("Counter demo")
        .sheet(isPresented: $isPrimeModalShown) {
//            IsPrimeModalView(
//              store: self.store.view { ($0.count, $0.favoritePrimes) }
//            )
            IsPrimeModalView(store: self.store)
        }
        .alert(item: self.$alertNthPrime) { alert in
          Alert(
            title: Text("The \(ordinal(self.store.value.count)) prime is \(alert.prime)"),
            dismissButton: .default(Text("Ok"))
          )
        }
    }
    
    private func ordinal(_ n: Int) -> String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .ordinal
      return formatter.string(for: n) ?? ""
    }
    
    func nthPrimeButtonAction() {
        self.isNthPrimeButtonDisabled = true
        nthPrime(self.store.value.count) { prime in
            self.alertNthPrime = prime.map{PrimeAlert(prime: $0)}
            self.isNthPrimeButtonDisabled = false
        }
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var store: Store<PrimeModalState, AppAction>
  var body: some View {
    VStack {
      if isPrime(self.store.value.count) {
        Text("\(self.store.value.count) is prime 🎉")
        if self.store.value.favoritePrimes.contains(self.store.value.count) {
          Button("Remove from favorite primes") {
            self.store.send(.primeModal(.removeFavoritePrimeTapped))
          }
        } else {
          Button("Save to favorite primes") {
            self.store.send(.primeModal(.saveFavoritePrimeTapped))
          }
        }
      } else {
        Text("\(self.store.value.count) is not prime :(")
      }
    }
  }
}

//struct FavoritePrimesState {
//  var favoritePrimes: [Int]
//  var activityFeed: [AppState.Activity]
//}

struct FavoritePrimesView: View {
    @ObservedObject var store: Store<[Int], AppAction>

    var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { prime in
                Text("\(prime)")
            }.onDelete { indexSet in
             self.store.send(.favoritePrimes(.deleteFavoritePrimes(indexSet)))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
    
}

private func isPrime (_ p: Int) -> Bool {
  if p <= 1 { return false }
  if p <= 3 { return true }
  for i in 2...Int(sqrtf(Float(p))) {
    if p % i == 0 { return false }
  }
  return true
}

struct WolframAlphaResult: Decodable {
  let queryresult: QueryResult

  struct QueryResult: Decodable {
    let pods: [Pod]

    struct Pod: Decodable {
      let primary: Bool?
      let subpods: [SubPod]

      struct SubPod: Decodable {
        let plaintext: String
      }
    }
  }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) -> Void {
    let wolframAlphaApiKey = "6H69Q3-828TKQJ4EP"
  var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
  components.queryItems = [
    URLQueryItem(name: "input", value: query),
    URLQueryItem(name: "format", value: "plaintext"),
    URLQueryItem(name: "output", value: "JSON"),
    URLQueryItem(name: "appid", value: wolframAlphaApiKey),
  ]

  URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
    callback(
      data
        .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
    )
    }
    .resume()
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) -> Void {
  wolframAlpha(query: "prime \(n)") { result in
    callback(
      result
        .flatMap {
          $0.queryresult
            .pods
            .first(where: { $0.primary == .some(true) })?
            .subpods
            .first?
            .plaintext
      }
      .flatMap(Int.init)
    )
  }
}

struct PrimeAlert: Identifiable {
  let prime: Int

  var id: Int { self.prime }
}
