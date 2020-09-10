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

public enum AnalyzeError: Error, CustomStringConvertible {
    case missingArgument(String)
    case mismatchedArgument(String)
    case unrecognizedTopDeclaration(String)

    public var description: String {
        get {
            switch self {
            case .missingArgument(let arg):
                return "require the argument \(arg)"
            case .mismatchedArgument(let arg):
                return "argument \(arg) type not matched"
            case .unrecognizedTopDeclaration(let decl):
                return "unrecognized top declaration \(decl)"
            }
        }
    }
}

extension Rhs {
    func asString() throws -> String {
        guard let rhs = self as? ValueRhs else {
            throw AnalyzeError.mismatchedArgument("\(self)")
        }
        return rhs.value
    }

    func asStringArray() throws -> [String] {
        if let array = self as? ArrayRhs {
            return try array.items.map { rhs -> String in
                try rhs.asString()
            }
        } else if let tuple = self as? TupleRhs {
            return try tuple.items.map { rhs -> String in
                try rhs.asString()
            }
        } else if let value = self as? ValueRhs {
            return [value.value]
        }
        throw AnalyzeError.mismatchedArgument("\(self)")
    }
}

extension String {
    func twoComponents(separatedBy str: String) -> (String, String) {
        if let range = range(of: str) {
            let first = self[startIndex..<range.lowerBound]
            let second = self[range.upperBound..<endIndex]
            return (String(first), String(second))
        }
        return (self, "")
    }

    var firstLetterLowercased: String {
        get {
            var chars = Array(self)
            chars[0] = Character(chars[0].lowercased())
            return String(chars)
        }
    }
}

class Analyzer {
    private let root: Root
    private let varDict: [String: Decl]

    init(vl: String) throws {
        root = try Parser(src: vl).parse()
        varDict = root.vars.reduce(into: [:]) { result, v in
            result[v.name] = v.decl
        }
    }

    func analyze() throws -> Widget {
        guard let widget = try analyzeWidget(decl: root.decl) else {
            throw AnalyzeError.unrecognizedTopDeclaration(root.decl.type)
        }
        return widget
    }

    private func analyzeWidget(decl: Decl) throws -> Widget? {
        let result: Widget?
        switch decl.type {
        case "Composite":
            result = try analyzeComposite(decl: decl)
        case "Empty":
            result = Empty()
        case "Text":
            result = try analyzeText(decl: decl)
        case "Image":
            result = try analyzeImage(decl: decl)
        default:
            if let some = varDict[decl.type] {
                result = try analyzeWidget(decl: some)
            } else {
                result = nil
            }
        }
        if let some = result {
            try attachProps(widget: some, decl: decl)
        }
        return result
    }

    private func analyzeComposite(decl: Decl) throws -> Composite {
        let result = Composite()
        try decl.decls.forEach { decl in
            if let widget = try analyzeWidget(decl: decl) {
                result.widgets.append(widget)
            }
        }
        return result
    }

    private func analyzeText(decl: Decl) throws -> Text {
        guard let first = decl.arg.items.first else {
            throw AnalyzeError.missingArgument("text")
        }
        let result = Text(text: try first.asString())
        return result
    }

    private func analyzeImage(decl: Decl) throws -> Image {
        let src = decl.props.last(where: { $0.name == "src" })?.value
                ?? decl.arg.items.first
        guard let some = src else {
            throw AnalyzeError.missingArgument("src")
        }
        let result = Image(src: try some.asString())
        return result
    }

    private func attachProps(widget: Widget, decl: Decl) throws {
        try decl.props.forEach { prop in
            let value = prop.value
            switch prop.name {
            case "id":
                widget.id = try value.asString()
            case "color":
                widget.color = try value.asString()
            default:
                break
            }
        }
        widget.constraints = try obtainConstraints(decl: decl)
    }

    private func obtainConstraints(decl: Decl) throws -> [Constraint] {
        var result = [Constraint]()
        let constraint = decl.decls.last(where: { $0.type == "Constraint" })
        try constraint?.props.forEach { prop in
            let value = prop.value
            let (first, second) = prop.name.twoComponents(separatedBy: "To")
            if second.isEmpty, let attr = ConstraintAttr(rawValue: first) {
                result.append(
                        Constraint(attr: attr, to: .unspecific, val: try value.asStringArray(), relation: prop.relation)
                )
            } else if let attr = ConstraintAttr(rawValue: first),
                      let to = ConstraintAttr(rawValue: second.firstLetterLowercased) {
                result.append(
                        Constraint(attr: attr, to: to, val: try value.asStringArray(), relation: prop.relation)
                )
            }
        }
        return result
    }
}
