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

public protocol Token {
    var literals: String { get }
}

func ==(lhs: Token, rhs: Token) -> Bool {
    lhs.literals == rhs.literals
}

func !=(lhs: Token, rhs: Token) -> Bool {
    lhs.literals != rhs.literals
}

enum Symbol: String, Token {
    case lparen = "("
    case rparen = ")"
    case lbrack = "["
    case rbrack = "]"
    case lbrace = "{"
    case rbrace = "}"
    case assign = "="
    case comma = ","
}

enum Keyword: String, Token {
    case `let`
}

enum Special: Token {
    case end, illegal
    case comment(String)
}

protocol Literals: Token {
}

struct IdentLit: Literals {
    let literals: String
}

enum ValueLit: Literals {
    case int(String)
    case float(String)
    case bool(String)
    case string(String)
}

extension Symbol {
    var literals: String {
        get {
            self.rawValue
        }
    }
}

extension Keyword {
    var literals: String {
        get {
            self.rawValue
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

extension ValueLit {
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
