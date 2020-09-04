//
// PeintureKit
//
// Copyright (c) 2020 sea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

enum Token: Equatable {
    case symbol(Symbol)
    case keyword(Keyword)
    case special(Special)
    case literals(Literals)

    static func ==(lhs: Token, rhs: Token) -> Bool {
        lhs.literals == rhs.literals
    }
}

enum Symbol: String {
    case lparen = "("
    case rparen = ")"
    case lbrack = "["
    case rbrack = "]"
    case lbrace = "{"
    case rbrace = "}"
    case assign = "="
    case comma = ","
}

enum Keyword: String {
    case `let`
}

enum Special {
    case end, illegal
    case comment(String)
}

enum Literals {
    case ident(String)
    case value(Value)
}

enum Value {
    case int(String)
    case float(String)
    case bool(String)
    case string(String)
}

extension Token {
    var literals: String {
        get {
            switch self {
            case .keyword(let keyword):
                return keyword.rawValue
            case .special(let special):
                return special.literals
            case .symbol(let symbol):
                return symbol.rawValue
            case .literals(let literals):
                return literals.literals
            }
        }
    }
}

extension Special {
    var literals: String {
        get {
            switch self {
            case .illegal:
                return "illegal"
            case .end:
                return "end"
            case .comment(let literals):
                return literals
            }
        }
    }
}

extension Literals {
    var literals: String {
        get {
            switch self {
            case .ident(let literals):
                return literals
            case .value(let value):
                return value.literals
            }
        }
    }
}

extension Value {
    var literals: String {
        get {
            switch self {
            case .int(let literals):
                return literals
            case .float(let literals):
                return literals
            case .bool(let literals):
                return literals
            case .string(let literals):
                return literals
            }
        }
    }
}
