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

protocol Node {
}

struct Root: Node {
    let decl: Decl
    let vars: [Var]
}

protocol Rhs: Node {
}

struct ValueRhs: Rhs {
    let value: String
}

struct ArrayRhs: Rhs {
    let items: [Rhs]
}

struct TupleRhs: Rhs {
    let items: [Rhs]
}

struct Decl: Node {
    let type: String
    let arg: TupleRhs
    let decls: [Decl]
    let props: [Prop]
}

struct Prop: Node {
    let name: String
    let value: Rhs
    let relation: Relation
}

enum Relation {
    case equal, lequal, gequal
}

struct Var: Node {
    let name: String
    let decl: Decl
}
