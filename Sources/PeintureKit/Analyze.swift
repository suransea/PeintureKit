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

    func asStringTupleTwo() throws -> (String, String) {
        let array = try self.asStringArray()
        return (array[0], array[1])
    }

    func asBool() throws -> Bool {
        let value = try self.asString()
        return Bool(value) ?? false
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
            if self.count == 0 {
                return ""
            }
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
        try decl.props.forEach { prop in
            let value = prop.value
            switch prop.name {
            case "textColor":
                result.textColor = try value.asString()
            case "textSize":
                result.textSize = try value.asString()
            case "textStyle":
                result.textStyle = try value.asString()
            case "textWeight":
                result.textWeight = try value.asString()
            case "underLine":
                result.underLine = try value.asBool()
            case "deleteLine":
                result.deleteLine = try value.asBool()
            default:
                break
            }
        }
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
            case "contentMode":
                widget.contentMode = try value.asString()
            case "cornerRadius":
                widget.cornerRadius = try value.asString()
            default:
                break
            }
        }
        widget.constraints = try obtainConstraints(decl: decl)
        widget.transform = try obtainTransform(decl: decl)
    }

    private func obtainConstraints(decl: Decl) throws -> [Constraint] {
        var result = [Constraint]()
        let constraint = decl.decls.last(where: { $0.type == "Constraint" })
        try constraint?.props.forEach { prop in
            let value = prop.value
            let (first, second) = prop.name.twoComponents(separatedBy: "To")
            if let attr = ConstraintAttr(rawValue: first) {
                let toAttr = ConstraintAttr(rawValue: second.firstLetterLowercased) ?? .unspecific
                result.append(
                        Constraint(attr: attr, toAttr: toAttr, val: try value.asStringArray(), relation: prop.relation)
                )
            }
        }
        return result
    }

    private func obtainTransform(decl: Decl) throws -> Transform? {
        guard let transform = decl.decls.last(where: { $0.type == "Transform" }) else {
            return nil
        }
        var result = Transform()
        try transform.props.forEach { prop in
            let value = prop.value
            switch prop.name {
            case "pivot":
                result.pivot = try value.asStringTupleTwo()
            case "translation":
                result.translation = try value.asStringTupleTwo()
            case "scale":
                result.scale = try value.asStringTupleTwo()
            case "rotation":
                result.rotation = try value.asString()
            case "alpha":
                result.alpha = try value.asString()
            default:
                break
            }
        }
        return result
    }
}
