import gleam/bool
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import gleam/yielder.{type Yielder}

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/parsec-paper-letter.pdf

pub opaque type Parser(i, v) {
  Parser(fn(State(i)) -> Consumed(i, v))
}

type State(i) {
  State(input: Yielder(i), position: Int)
}

type Consumed(i, v) {
  Consumed(fn() -> Reply(i, v))
  Empty(Reply(i, v))
}

type Reply(i, v) {
  Success(value: v, state: State(i), message: Message(i))
  Failure(message: Message(i))
}

pub type Message(i) {
  Message(position: Int, error: Option(Error(i)), labels: Set(String))
}

pub type Error(i) {
  UnexpectedEnd
  UnexpectedToken(i)
}

fn merge_reply(reply: Reply(i, v), message1: Message(i)) -> Reply(i, v) {
  case reply {
    Failure(message2) -> merge_failure(message1, message2)

    Success(value, state, message2) ->
      merge_success(value, state, message1, message2)
  }
}

fn merge_failure(message1: Message(i), message2: Message(i)) -> Reply(i, v) {
  Failure(merge_messages(message1, message2))
}

fn merge_success(
  value: v,
  state: State(i),
  message1: Message(i),
  message2: Message(i),
) -> Reply(i, v) {
  Success(value:, state:, message: merge_messages(message1, message2))
}

fn merge_messages(message1: Message(i), message2: Message(i)) -> Message(i) {
  let Message(position1, error1, labels1) = message1
  let Message(position2, error2, labels2) = message2
  let labels = set.union(labels1, labels2)

  case error1, error2 {
    Some(_), None -> Message(..message1, labels:)
    None, Some(_) -> Message(..message2, labels:)

    _other, _wise -> {
      use <- bool.guard(position1 > position2, message1)
      use <- bool.guard(position1 < position2, message2)
      Message(..message1, labels:)
    }
  }
}

fn run(parser: Parser(i, v), state: State(i)) -> Consumed(i, v) {
  let Parser(parser) = parser
  parser(state)
}

pub fn parse(input: Yielder(i), parser: Parser(i, v)) -> Result(v, Message(i)) {
  let state = State(input, 1)

  case run(parser, state) {
    Empty(reply) ->
      case reply {
        Success(value, _state, _message) -> Ok(value)
        Failure(message) -> Error(message)
      }

    Consumed(reply) ->
      case reply() {
        Success(value, _state, _message) -> Ok(value)
        Failure(message) -> Error(message)
      }
  }
}

pub fn succeed(value: v) -> Parser(i, v) {
  use State(_input, position) as state <- Parser
  let message = Message(position:, error: None, labels: set.new())
  Empty(Success(value:, state:, message:))
}

pub fn unexpected(v: v) -> Option(Error(v)) {
  Some(UnexpectedToken(v))
}

pub fn fail() -> Parser(i, v) {
  use State(_input, position) <- Parser
  let message = Message(position:, error: None, labels: set.new())
  Empty(Failure(message:))
}

pub fn expect(check: fn(i) -> Bool) -> Parser(i, i) {
  use State(input, position) <- Parser

  let failure = fn(unexpected) {
    Failure(Message(position:, error: Some(unexpected), labels: set.new()))
  }

  let success = fn(value, rest) {
    Success(
      value:,
      state: State(rest, position + 1),
      message: Message(position, error: None, labels: set.new()),
    )
  }

  case yielder.step(input) {
    yielder.Done -> Empty(failure(UnexpectedEnd))

    yielder.Next(value, rest) -> {
      case check(value) {
        True -> Consumed(fn() { success(value, rest) })
        False -> Empty(failure(UnexpectedToken(value)))
      }
    }
  }
}

pub fn do(parser: Parser(i, a), then: fn(a) -> Parser(i, b)) -> Parser(i, b) {
  use state <- Parser

  case run(parser, state) {
    Consumed(reply1) ->
      Consumed(fn() {
        case reply1() {
          Failure(message) -> Failure(message)

          Success(value, state, message1) ->
            case run(then(value), state) {
              Consumed(reply) -> reply()
              Empty(reply2) -> merge_reply(reply2, message1)
            }
        }
      })

    Empty(reply1) ->
      case reply1 {
        Failure(message) -> Empty(Failure(message))

        Success(value, state, message1) ->
          case run(then(value), state) {
            Empty(reply2) -> Empty(merge_reply(reply2, message1))

            Consumed(reply2) ->
              Consumed(fn() { merge_reply(reply2(), message1) })
          }
      }
  }
}

pub fn choice(a: Parser(i, v), b: Parser(i, v)) -> Parser(i, v) {
  use state <- Parser

  case run(a, state) {
    Consumed(reply) -> Consumed(reply)

    Empty(reply1) ->
      case run(b, state) {
        Consumed(reply2) -> Consumed(reply2)

        Empty(reply2) ->
          Empty(case reply1, reply2 {
            Failure(message1), Failure(message2) ->
              merge_failure(message1, message2)

            Failure(message1), Success(value, state, message2)
            | Success(value, state, message1), Failure(message2)
            | Success(value, state, message1), Success(_value, _state, message2)
            -> merge_success(value, state, message1, message2)
          })
      }
  }
}

pub fn label(parser: Parser(i, v), label: String) -> Parser(i, v) {
  use state <- Parser

  case run(parser, state) {
    Consumed(reply) -> Consumed(reply)

    Empty(reply) ->
      Empty(case reply {
        Failure(message) ->
          put_label(message, label)
          |> Failure

        Success(value:, state:, message:) ->
          put_label(message, label)
          |> Success(value:, state:, message: _)
      })
  }
}

fn put_label(message: Message(i), label: String) -> Message(i) {
  let Message(position, error, _labels) = message
  Message(position:, error:, labels: set.from_list([label]))
}

pub fn try(parser: Parser(i, v)) -> Parser(i, v) {
  use state <- Parser

  case run(parser, state) {
    Empty(reply) -> Empty(reply)

    Consumed(reply) ->
      case reply() {
        Failure(message) -> Empty(Failure(message))
        _success -> Consumed(reply)
      }
  }
}

pub fn lazy(parser: fn() -> Parser(i, v)) -> Parser(i, v) {
  use state <- Parser
  run(parser(), state)
}
