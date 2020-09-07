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

private let END = Character(UnicodeScalar(0x1A)) // EOF

extension Character {
    var isLetter: Bool {
        get {
            "a"..."z" ~= self.lowercased() || self == "_"
        }
    }

    var isDecimal: Bool {
        get {
            "0"..."9" ~= self
        }
    }

    var isIdentPart: Bool {
        get {
            isLetter || isDecimal
        }
    }
}

public enum LexError: Error, CustomStringConvertible {
    case unexpectedChar(Character, at: Int)
    case unterminatedChars(String, from: Int)

    public var description: String {
        get {
            switch self {
            case let .unexpectedChar(char, at):
                return "unexpected character \"\(char)\" at pos \(at)"
            case let .unterminatedChars(chars, from):
                return "expected the terminal \"\(chars)\" from pos \(from)"
            }
        }
    }
}

class Lexer {
    private let src: [Character]
    private var pos = -1
    private var ch = END

    init(src: String) {
        self.src = Array(src)
        next()
    }

    func lex() throws -> Token {
        skipWhitespace()
        if ch.isLetter {
            return lexIdentSimilar()
        }
        if ch.isDecimal {
            return try lexNumber()
        }
        switch ch {
        case "-":
            return try lexNumber()
        case "\'", "\"":
            return try lexString()
        case "/":
            return try lexComment()
        case "(":
            return lex(to: Symbol.lparen)
        case ")":
            return lex(to: Symbol.rparen)
        case "[":
            return lex(to: Symbol.lbrack)
        case "]":
            return lex(to: Symbol.rbrack)
        case "{":
            return lex(to: Symbol.lbrace)
        case "}":
            return lex(to: Symbol.rbrace)
        case "=":
            return lex(to: Symbol.assign)
        case ",":
            return lex(to: Symbol.comma)
        case END:
            return lex(to: Special.end)
        default:
            return lex(to: Special.illegal)
        }
    }

    private func lexIdentSimilar() -> Token {
        let begin = pos
        next(when: { ch.isLetter })
        let value = literals(from: begin)
        if let keyword = Keyword(rawValue: value) {
            return keyword
        }
        if "true" == value || "false" == value {
            return ValueLit.bool(value)
        }
        return IdentLit(literals: value)
    }

    private func lexNumber() throws -> Token {
        let begin = pos
        if ch == "-" {
            next()
            if !ch.isDecimal {
                throw LexError.unexpectedChar(ch, at: pos)
            }
        }
        next(when: { ch.isDecimal })
        if ch != "." {
            return ValueLit.int(literals(from: begin))
        }

        next() // consume "."
        if !ch.isDecimal {
            throw LexError.unexpectedChar(ch, at: pos)
        }
        next(when: { ch.isDecimal })
        return ValueLit.float(literals(from: begin))
    }

    private func lexString() throws -> Token {
        let beginChar = ch
        next()
        let begin = pos
        while ch != beginChar {
            if ch == "\n" {
                throw LexError.unexpectedChar(ch, at: pos)
            }
            if ch == "\\" && peek() == beginChar {
                next()
            }
            next()
        }
        if ch == END {
            throw LexError.unterminatedChars(String(beginChar), from: begin - 1)
        }
        let value = literals(from: begin)
        next() // consume terminal char
        return ValueLit.string(value)
    }

    private func lexComment() throws -> Token {
        let begin = pos
        next()
        switch ch {
        case "/":
            next(until: { ch == "\n" })
            return Special.comment(literals(from: begin))
        case "*":
            next(until: { ch == "*" && peek() == "/" })
            if ch == END {
                throw LexError.unterminatedChars("*/", from: begin)
            }
            next() // consume "*"
            next() // consume "/"
            return Special.comment(literals(from: begin))
        default:
            throw LexError.unexpectedChar(ch, at: pos)
        }
    }

    private func lex(to token: Token) -> Token {
        next()
        return token
    }

    private func literals(from begin: Int) -> String {
        String(src[begin..<pos])
    }

    private func peek() -> Character {
        let next = pos + 1
        return next >= src.count ? END : src[next]
    }

    private func next() {
        pos += 1
        ch = pos >= src.count ? END : src[pos]
    }

    private func next(when pred: () -> Bool) {
        while pred() && ch != END {
            next()
        }
    }

    private func next(until pred: () -> Bool) {
        while !pred() && ch != END {
            next()
        }
    }

    private func skipWhitespace() {
        while ch.isWhitespace {
            next()
        }
    }
}
