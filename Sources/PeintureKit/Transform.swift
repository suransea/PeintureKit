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

extension Widget {
    func transformIntoView(with drawer: Drawer) throws -> UIView {
        var views = [(Widget, UIView)]()
        let view = try transformWidgetIntoView(widget: self, drawer: drawer, views: &views)
        makeConstraints(for: views)
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
        result = transformText(text: text)
    } else if let image = widget as? Image {
        let view = UIImageView()
        drawer.imageLoader(image.src, view)
        result = view
    } else if widget is Empty {
        result = UIView()
    } else {
        fatalError("unknown widget") // reachable only while debugging
    }
    views.append((widget, result))
    result.tag = Int(widget.id) ?? 0
    result.translatesAutoresizingMaskIntoConstraints = false
    result.contentMode = UIView.ContentMode(str: widget.contentMode)
    if !widget.color.isEmpty {
        result.backgroundColor = UIColor(str: widget.color)
    }
    if !widget.cornerRadius.isEmpty {
        result.layer.cornerRadius = CGFloat(str: widget.cornerRadius)
        result.clipsToBounds = true
    }
    if let some = widget.transform {
        result.layer.anchorPoint = CGPoint(x: CGFloat(str: some.pivot.0), y: CGFloat(str: some.pivot.1))
        result.transform.apply(transform: some)
        result.alpha = CGFloat(str: some.alpha)
    }
    return result
}

func transformText(text: Text) -> UITextView {
    let result = UITextView()
    result.isScrollEnabled = false
    var attr = [NSAttributedString.Key: Any]()
    if text.underLine {
        attr[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
    }
    if text.deleteLine {
        attr[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }
    let attrText = NSMutableAttributedString(string: text.text, attributes: attr)
    result.attributedText = attrText
    if !text.textColor.isEmpty {
        result.textColor = UIColor(str: text.textColor)
    }
    var textSize = UIFont.systemFontSize
    if !text.textSize.isEmpty {
        textSize = CGFloat(str: text.textSize)
    }
    let weight = UIFont.Weight(str: text.textWeight)
    switch text.textStyle {
    case "bold":
        result.font = UIFont.boldSystemFont(ofSize: textSize)
    case "italic":
        result.font = UIFont.italicSystemFont(ofSize: textSize)
    default:
        result.font = UIFont.systemFont(ofSize: textSize, weight: weight)
    }
    return result
}

extension CGFloat {
    init(str: String) {
        self.init(Float(str) ?? 0)
    }
}

extension UIView.ContentMode {
    init(str: String) {
        switch str {
        case "scaleToFill":
            self = .scaleToFill
        case "scaleAspectFit":
            self = .scaleAspectFit
        case "scaleAspectFill":
            self = .scaleAspectFill
        case "redraw":
            self = .redraw
        case "center":
            self = .center
        case "top":
            self = .top
        case "bottom":
            self = .bottom
        case "left":
            self = .left
        case "right":
            self = .right
        case "topLeft":
            self = .topLeft
        case "topRight ":
            self = .topRight
        case "bottomLeft ":
            self = .bottomLeft
        case "bottomRight ":
            self = .bottomRight
        default:
            self = .scaleToFill
        }
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

extension UIFont.Weight {
    init(str: String) {
        switch str {
        case "thin":
            self = .thin
        case "regular":
            self = .regular
        case "black":
            self = .black
        case "bold":
            self = .bold
        case "heavy":
            self = .heavy
        case "light":
            self = .light
        case "medium":
            self = .medium
        case "semibold":
            self = .semibold
        case "ultraLight":
            self = .ultraLight
        default:
            self = .regular
        }
    }
}

extension CGAffineTransform {
    mutating func apply(transform: Transform) {
        self = self.rotated(by: CGFloat(Float.pi) * CGFloat(str: transform.rotation) / 180)
                .scaledBy(x: CGFloat(str: transform.scale.0), y: CGFloat(str: transform.scale.1))
                .translatedBy(x: CGFloat(str: transform.translation.0), y: CGFloat(str: transform.translation.1))
    }
}

func makeConstraints(for views: [(Widget, UIView)]) {
    views.filter { widget, _ in
        !widget.constraints.isEmpty
    }.forEach { widget, view in
        let constraints = widget.constraints.map { constraint in
            constraint.standardised
        }
        linkConstraints(constraints, to: view, root: views.last!.1)
    }
}

func linkConstraints(_ constraints: [Constraint], to item: UIView, root: UIView) {
    constraints.forEach { constraint in
        let superview = item.superview
        let toItem: UIView?, target: UIView?
        let toId = constraint.val[0]
        if toId == parent {
            (toItem, target) = (superview, superview)
        } else {
            let id = Int(toId) ?? -1
            if id != -1 {
                toItem = root.viewWithTag(id)
                if toItem == nil {
                    return  // ignore this constraint if toItem invalid
                }
                target = findCommonSuperview(item, toItem!)
            } else {
                (toItem, target) = (nil, item)
            }
        }

        if target == nil {
            return
        }

        let attr = NSLayoutConstraint.Attribute(attr: constraint.attr)
        let toAttr = NSLayoutConstraint.Attribute(attr: constraint.toAttr)
        let relation = NSLayoutConstraint.Relation(relation: constraint.relation)
        let const = CGFloat(str: constraint.val[1])
        let multiplier = CGFloat(str: constraint.val[2])
        target!.addConstraint(NSLayoutConstraint(item: item, attribute: attr,
                relatedBy: relation, toItem: toItem, attribute: toAttr,
                multiplier: multiplier, constant: const))
    }
}

func findCommonSuperview(_ a: UIView, _ b: UIView) -> UIView? {
    var visited = Set<UIView>()
    var (x, y) = (Optional.some(a), Optional.some(b))
    while true {
        if let some = x {
            if !visited.insert(some).inserted {
                return some
            }
        }
        if let some = y {
            if !visited.insert(some).inserted {
                return some
            }
        }
        x = x?.superview
        y = y?.superview

        if x == nil && y == nil {
            return nil
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
            self.toAttr == .unspecific
        }
    }

    var standardised: Constraint {
        get {
            var result = self
            if result.isSingle {
                result.toAttr = result.attr
                if result.val[0] != parent {
                    if result.isDimension {
                        result.toAttr = .unspecific
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
