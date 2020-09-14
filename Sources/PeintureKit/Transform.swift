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
        view.layoutIfNeeded()
        setupAfterLayout(for: views)
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
    result.alpha = CGFloat(str: widget.alpha)
    if !widget.color.isEmpty {
        result.backgroundColor = UIColor(str: widget.color)
    }
    if let some = widget.transform {
        result.layer.anchorPoint = CGPoint(x: CGFloat(str: some.pivot.0), y: CGFloat(str: some.pivot.1))
        result.transform.apply(transform: some)
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

func setupAfterLayout(for views: [(Widget, UIView)]) {
    views.forEach { widget, view in
        let path: UIBezierPath
        switch widget.shape {
        case "oval":
            path = UIBezierPath(ovalIn: view.bounds)
        default:
            path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: UIRectCorner(corners: widget.corners),
                    cornerRadii: CGSize(tuple: widget.cornerRadii))
        }
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        view.layer.mask = shape
        view.layer.masksToBounds = true
        if !widget.borderColor.isEmpty {
            let border = CAShapeLayer()
            border.path = path.cgPath
            border.strokeColor = UIColor(str: widget.borderColor).cgColor
            border.lineWidth = CGFloat(str: widget.borderWidth)
            border.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(border)
        }

        if let some = widget.gradient {
            let gradient = CAGradientLayer()
            gradient.frame = view.bounds
            gradient.type = some.type.isEmpty ? .axial : CAGradientLayerType(rawValue: some.type)
            gradient.colors = some.colors.map { color in
                UIColor(str: color).cgColor
            }
            gradient.startPoint = CGPoint(tuple: some.orientation[0])
            gradient.endPoint = CGPoint(tuple: some.orientation[1])
            view.layer.addSublayer(gradient)
        }
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

func findCommonSuperview(_ a: UIView, _ b: UIView) -> UIView {
    var (x, y) = (a, b)
    while x != y {
        x = x.superview ?? b
        y = y.superview ?? a
    }
    return x
}

extension CGFloat {
    init(str: String) {
        self.init(Float(str) ?? 0)
    }
}

extension CGSize {
    init(tuple: (String, String)) {
        self.init(width: CGFloat(str: tuple.0), height: CGFloat(str: tuple.1))
    }
}

extension CGPoint {
    init(tuple: (String, String)) {
        self.init(x: CGFloat(str: tuple.0), y: CGFloat(str: tuple.1))
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
        let rotation = CGFloat(Float.pi) * CGFloat(str: transform.rotation) / 180
        let (scaleX, scaleY) = transform.scale
        let (translationX, translationY) = transform.translation
        self = self.rotated(by: rotation)
                .scaledBy(x: CGFloat(str: scaleX), y: CGFloat(str: scaleY))
                .translatedBy(x: CGFloat(str: translationX), y: CGFloat(str: translationY))
    }
}

extension UIRectCorner {
    init(corners: [String]) {
        if corners.isEmpty {
            self.init(rawValue: UIRectCorner.allCorners.rawValue)
            return
        }
        var rawCorners: UInt = 0
        corners.forEach { corner in
            switch corner {
            case "topLeft":
                rawCorners |= UIRectCorner.topLeft.rawValue
            case "topRight":
                rawCorners |= UIRectCorner.topRight.rawValue
            case "bottomRight":
                rawCorners |= UIRectCorner.bottomRight.rawValue
            case "bottomLeft":
                rawCorners |= UIRectCorner.bottomLeft.rawValue
            default:
                break
            }
        }
        self.init(rawValue: rawCorners)
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
