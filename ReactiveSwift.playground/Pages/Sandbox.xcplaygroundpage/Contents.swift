/*:
 > # IMPORTANT: To use `ReactiveSwift.playground`, please:
 
 1. Retrieve the project dependencies using one of the following terminal commands from the ReactiveSwift project root directory:
    - `git submodule update --init`
 **OR**, if you have [Carthage](https://github.com/Carthage/Carthage) installed
    - `carthage checkout --no-use-binaries`
 1. Open `ReactiveSwift.xcworkspace`
 1. Build `Result-Mac` scheme
 1. Build `ReactiveSwift-macOS` scheme
 1. Finally open the `ReactiveSwift.playground`
 1. Choose `View > Show Debug Area`
 */

import Result
import ReactiveSwift
import Foundation

/*:
 ## Sandbox
 
 A place where you can build your sand castles 🏖.
*/

// Feedback setup

enum Feedbacks {

    static func newPrintFeedback(for printRequest: Signal<String, NoError>) -> Feedback<State, Event> {
        return Feedback(effects: { _ -> Signal<Event, NoError> in
            return printRequest.map {
                print("Scheduling printing of \"\($0)\"")

                return Event.schedulePrint($0)
            }
            .logEvents(identifier: "Feedbacks.newPrintFeedback.printRequest.map",
                       events: LoggingEvent.Signal.allEvents,
                       logger: feedbackEventLog)
        })
    }

    static func printFeedback() -> Feedback<State, Event> {
        return Feedback(query: { $0.nextPrint },
                        effects: { text -> SignalProducer<Event, NoError> in

                            return SignalProducer { observer, _ in
                                print("Printing -> \"\(text)\" 🎉")
                                observer.send(value: Event.didPrint(text))
                            }
        })
    }
}

// Feedback types

enum State {
    case initial
    case newPrint(String)
    case printCompleted(String)

    var nextPrint: String? {
        switch self {
        case .newPrint(let string): return string
        default: return nil
        }
    }

    static func reduce(state: State, event: Event) -> State {
        switch event {
        case .schedulePrint(let string): return .newPrint(string)
        case .didPrint(let string): return .printCompleted(string)
        }
    }
}

enum Event {
    case schedulePrint(String)
    case didPrint(String)
}

// Feedback system Property

let (printRequestSignal, printRequestObserver) = Signal<String, NoError>.pipe()

let feedbacks = [
    Feedbacks.newPrintFeedback(for: printRequestSignal),
    Feedbacks.printFeedback()
]

let property = Property(initial: State.initial,
                        scheduler: UIScheduler(), // comment this line to observe issue 😢
                        reduce: State.reduce,
                        feedbacks: feedbacks)

printRequestObserver.send(value: "🍺")
