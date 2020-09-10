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

public enum ParseError: Error, CustomStringConvertible {
    case unexpectedToken(Token, expected: Token)
    case unexpectedTokenType(Token, expectedType: Any.Type)
    case incorrectTopDeclarationCount(Int)

    public var description: String {
        get {
            switch self {
            case .unexpectedToken(let token, expected: let expected):
                return "unexpected token: \(token), expected: \(expected)"
            case .unexpectedTokenType(let token, expectedType: let expectedType):
                return "unexpected token type: \(type(of: token)), token: \(token), expected type: \(expectedType)"
            case .incorrectTopDeclarationCount(let count):
                return "expected one top declaration, actual count is \(count)"
            }
        }
    }
}

class Parser {
    private let lexer: Lexer
    private var token: Token = Special.end

    init(src: String) throws {
        lexer = Lexer(src: src)
        try next()
    }

    func parse() throws -> Root {
        var vars = [Var]()
        var decls = [Decl]()
        while token != Special.end {
            switch token {
            case Keyword.let:
                vars.append(try parseVar())
            case is IdentLit:
                decls.append(try parseDecl(type: expect()))
            default:
                throw ParseError.unexpectedTokenType(token, expectedType: IdentLit.self)
            }
        }
        if decls.count != 1 {
            throw ParseError.incorrectTopDeclarationCount(decls.count)
        }
        return Root(decl: decls[0], vars: vars)
    }

    private func parseDecl(type: IdentLit) throws -> Decl {
        let arg = token == Symbol.lparen ? try parseTuple() : TupleRhs(items: [])
        try expect(token: Symbol.lbrace)
        var props = [Prop]()
        var decls = [Decl]()
        while token != Symbol.rbrace {
            let ident: IdentLit = try expect()
            switch token {
            case Symbol.assign, Symbol.lequal, Symbol.gequal:
                props.append(try parseProp(name: ident))
            case Symbol.lparen, Symbol.lbrace:
                decls.append(try parseDecl(type: ident))
            case is IdentLit, Symbol.rbrace:
                continue
            default:
                try expect(token: Symbol.assign)
            }
        }
        try expect(token: Symbol.rbrace)
        return Decl(type: type.literals, arg: arg, decls: decls, props: props)
    }

    private func parseVar() throws -> Var {
        try expect(token: Keyword.let)
        let name: IdentLit = try expect()
        try expect(token: Symbol.assign)
        return Var(name: name.literals, decl: try parseDecl(type: try expect()))
    }

    private func parseProp(name: IdentLit) throws -> Prop {
        let relation: Relation
        switch token {
        case Symbol.assign:
            relation = .equal
        case Symbol.lequal:
            relation = .lequal
        case Symbol.gequal:
            relation = .gequal
        default:
            throw ParseError.unexpectedToken(token, expected: Symbol.assign)
        }
        try next()
        return Prop(name: name.literals, value: try parseRhs(), relation: relation)
    }

    private func parseRhs() throws -> Rhs {
        switch token {
        case is ValueLit:
            let value: ValueLit = try expect()
            return ValueRhs(value: value.literals)
        case Symbol.lparen:
            return try parseTuple()
        case Symbol.lbrack:
            return try parseArray()
        default:
            throw ParseError.unexpectedTokenType(token, expectedType: ValueLit.self)
        }
    }

    private func parseTuple() throws -> TupleRhs {
        try expect(token: Symbol.lparen)
        var rhs = [Rhs]()
        while token != Symbol.rparen {
            rhs.append(try parseRhs())
            if token == Symbol.comma {
                try expect(token: Symbol.comma)
            }
        }
        try expect(token: Symbol.rparen)
        return TupleRhs(items: rhs)
    }

    private func parseArray() throws -> ArrayRhs {
        try expect(token: Symbol.lbrack)
        var rhs: [Rhs] = []
        while token != Symbol.rbrack {
            rhs.append(try parseRhs())
            if token == Symbol.comma {
                try expect(token: Symbol.comma)
            }
        }
        try expect(token: Symbol.rbrack)
        return ArrayRhs(items: rhs)
    }

    private func expect(token expected: Token) throws {
        let current = token
        if current != expected {
            throw ParseError.unexpectedToken(current, expected: expected)
        }
        try next()
    }

    private func expect<T>() throws -> T {
        let current = token
        guard current is T else {
            throw ParseError.unexpectedTokenType(current, expectedType: T.self)
        }
        try next()
        return current as! T
    }

    private func next() throws {
        token = try lexer.lex()
        if case Special.comment = token {
            try next() // skip comment
        }
    }
}
