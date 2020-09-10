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

private let empty = ""
private let zero = "0"

class Widget {
    var id = empty
    var color = empty
    var constraints = [Constraint]()
}

struct Constraint {
    var attr: ConstraintAttr
    var to: ConstraintAttr
    var val: [String]
}

enum ConstraintAttr: String {
    case unspecific
    case left, right, top, bottom, leading, trailing
    case width, height, centerX, centerY
    case firstBaseline, lastBaseline
}

class Empty: Widget {
}

class Composite: Widget {
    var widgets = [Widget]()
}

class Text: Widget {
    let text: String

    init(text: String = empty) {
        self.text = text
    }
}

class Image: Widget {
    let src: String

    init(src: String) {
        self.src = src
    }
}
