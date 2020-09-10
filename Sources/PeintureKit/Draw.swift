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

public typealias ImageLoader = (_ src: String, _ imageView: UIImageView) -> Void

public let defaultImageLoader: ImageLoader = { (src, imageView) in
    guard let url = URL(string: src) else {
        return
    }
    guard let data = try? Data(contentsOf: url) else {
        return
    }
    let image = UIImage(data: data)
    imageView.image = image
}

public class Drawer {
    public var imageLoader: ImageLoader

    public init(imageLoader: @escaping ImageLoader = defaultImageLoader) {
        self.imageLoader = imageLoader
    }

    public func drawImage(vl: String) throws -> UIImage? {
        let view = try drawView(vl: vl)
        view.layoutIfNeeded()
        UIGraphicsBeginImageContext(view.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    public func drawView(vl: String) throws -> UIView {
        let widget = try Analyzer(vl: vl).analyze()
        return try widget.transformIntoView(with: self)
    }
}
