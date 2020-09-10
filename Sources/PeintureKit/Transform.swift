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

import UIKit

enum TransformError: Error {
    case unknownWidget
}

extension Widget {
    func transformIntoView(with drawer: Drawer) throws -> UIView {
        var views = [(Widget, UIView)]()
        let view = try transformWidgetIntoView(widget: self, drawer: drawer, views: &views)
        makeConstraint(views: views)
        return view
    }
}

func transformWidgetIntoView(widget: Widget, drawer: Drawer, views: inout [(Widget, UIView)]) throws -> UIView {
    let result: UIView
    if let composite = widget as? Composite {
        let view = UIView()
        try composite.widgets.forEach { widget in
            let subview = try transformWidgetIntoView(widget: widget, drawer: drawer, views: &views)
            view.addSubview(subview)
        }
        result = view
    } else if let text = widget as? Text {
        let view = UITextView()
        view.isScrollEnabled = false
        view.text = text.text
        if !text.textColor.isEmpty {
            view.textColor = UIColor(str: text.textColor)
        }
        if !text.textSize.isEmpty {
            view.font = UIFont.systemFont(ofSize: CGFloat(str: text.textSize))
        }
        result = view
    } else if let image = widget as? Image {
        let view = UIImageView()
        drawer.imageLoader(image.src, view)
        result = view
    } else {
        throw TransformError.unknownWidget // reachable only while debugging
    }
    result.translatesAutoresizingMaskIntoConstraints = false
    if !widget.color.isEmpty {
        result.backgroundColor = UIColor(str: widget.color)
    }
    views.append((widget, result))
    return result
}

extension CGFloat {
    init(str: String) {
        self.init(Float(str) ?? 0)
    }
}

extension UIColor {
    convenience init(str: String) {
        var chars = Array(str)
        if str.starts(with: "#") {
            chars.removeFirst()
        } else if str.starts(with: "0x") || str.starts(with: "0X") {
            chars.removeFirst(2)
        }
        var components = stride(from: 0, to: chars.count, by: 2).map { index in
            String(chars[index..<index + 2])
        }.map {
            Int($0, radix: 16) ?? 0
        }.map {
            CGFloat(Float($0) / Float(255.0))
        }
        components.reverse()
        let b = components[0]
        let g = components[1]
        let r = components[2]
        let a = components.count > 3 ? components[3] : 1
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

func makeConstraint(views: [(Widget, UIView)]) {
    let viewDict: [String: UIView] = views.filter { widget, _ in
        !widget.id.isEmpty
    }.reduce(into: [:]) { result, element in
        result[element.0.id] = element.1
    }
    views.forEach { widget, view in
        let constraints = widget.constraints.map { constraint in
            constraint.standardised
        }
        constraints.forEach { constraint in
            let attr = NSLayoutConstraint.Attribute(attr: constraint.attr)
            let to = NSLayoutConstraint.Attribute(attr: constraint.to)
            let relation = NSLayoutConstraint.Relation(relation: constraint.relation)
            var toItem: UIView? = nil
            if constraint.val[0] == parent {
                toItem = view.superview
            } else if let some = viewDict[constraint.val[0]] {
                toItem = some
            }
            let const = CGFloat(str: constraint.val[1])
            let multiplier = CGFloat(str: constraint.val[2])
            let target = view.superview ?? view
            target.addConstraint(NSLayoutConstraint(item: view, attribute: attr,
                    relatedBy: relation, toItem: toItem, attribute: to,
                    multiplier: multiplier, constant: const))
        }
    }
}

private let parent = "parent"
private let zero = "0"
private let once = "1"
private let noId = "-1"

extension Constraint {
    var isDimension: Bool {
        get {
            self.attr == .width || self.attr == .height
        }
    }

    var isSingle: Bool {
        get {
            self.to == .unspecific
        }
    }

    var standardised: Constraint {
        get {
            var result = self
            if result.isSingle {
                result.to = result.attr
                if result.val[0] != parent {
                    if result.isDimension {
                        result.to = .unspecific
                        result.val = [noId, result.val[0]]
                    } else {
                        result.val = [parent, result.val[0]]
                    }
                }
            }
            if result.val.count == 1 {
                result.val.append(zero)
            }
            if result.val.count == 2 {
                result.val.append(once)
            }
            return result
        }
    }
}

extension NSLayoutConstraint.Attribute {
    init(attr: ConstraintAttr) {
        switch attr {
        case .unspecific:
            self = .notAnAttribute
        case .left:
            self = .left
        case .right:
            self = .right
        case .top:
            self = .top
        case .bottom:
            self = .bottom
        case .leading:
            self = .leading
        case .trailing:
            self = .trailing
        case .width:
            self = .width
        case .height:
            self = .height
        case .centerX:
            self = .centerX
        case .centerY:
            self = .centerY
        case .lastBaseline:
            self = .lastBaseline
        case .firstBaseline:
            self = .firstBaseline
        }
    }
}

extension NSLayoutConstraint.Relation {
    init(relation: Relation) {
        switch relation {
        case .equal:
            self = .equal
        case .lequal:
            self = .lessThanOrEqual
        case .gequal:
            self = .greaterThanOrEqual
        }
    }
}
