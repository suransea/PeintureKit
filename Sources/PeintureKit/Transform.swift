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
        let view = try transformWidgetIntoView(widget: self, drawer: drawer)
        makeConstraint([(self, view)])
        return view
    }
}

func transformWidgetIntoView(widget: Widget, drawer: Drawer) throws -> UIView {
    let result: UIView
    if let composite = widget as? Composite {
        let view = UIView()
        var views = [(Widget, UIView)]()
        try composite.widgets.forEach { widget in
            let subview = try transformWidgetIntoView(widget: widget, drawer: drawer)
            views.append((widget, subview))
            view.addSubview(subview)
        }
        makeConstraint(views)
        result = view
    } else if let text = widget as? Text {
        let view = UITextView()
        view.text = text.text
        result = view
    } else if let image = widget as? Image {
        let view = UIImageView()
        drawer.imageLoader(image.src, view)
        result = view
    } else {
        throw TransformError.unknownWidget // reachable only while debugging
    }
    result.translatesAutoresizingMaskIntoConstraints = false
    return result
}

func makeConstraint(_ views: [(Widget, UIView)]) {
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
            var toItem: UIView? = nil
            if constraint.val[0] == parent {
                toItem = view.superview
            } else if let some = viewDict[constraint.val[0]] {
                toItem = some
            }
            let const = CGFloat(Float(constraint.val[1]) ?? 0)
            let multiplier = CGFloat(Float(constraint.val[2]) ?? 0)
            let item = view.superview ?? view
            item.addConstraint(NSLayoutConstraint(item: view, attribute: attr,
                    relatedBy: .equal, toItem: toItem, attribute: to,
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
