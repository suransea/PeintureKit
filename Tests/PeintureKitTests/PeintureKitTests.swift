import XCTest
import Foundation
@testable import PeintureKit

final class PeintureKitTests: XCTestCase {

    func testLex() throws {
        let lexer = Lexer(src: testVl)
        var tokens = [Token]()
        var token: Token

        repeat {
            token = try lexer.lex()
            tokens.append(token)
        } while token != Special.end &&
                token != Special.illegal

        tokens.forEach {
            print($0)
        }
    }

    func testParse() throws {
        let parser = try Parser(src: testVl)
        let root = try parser.parse()
        print(root)
    }

    func testAnalyze() throws {
        let analyzer = try Analyzer(vl: testVl)
        let widget = try analyzer.analyze()
        print(widget)
    }

    func testDraw() throws {
        let drawer = Drawer()
        let image = try drawer.drawImage(vl: testVl)
        print(image as Any)
    }
}

let testVl = """
             // Use keyword "let" to declare a custom view
             let Custom = Composite {
                 Text('Hello') {
                     id = 1
                     textSize = 12
                     textColor = '#333333'
                     Constraint {
                         widthToWidth = ('parent', 0, 0.8)
                         height = 100
                         centerX = 'parent'
                         top = 200
                     }
                 }
                 Image {
                     src = 'https://w.wallhaven.cc/full/6k/wallhaven-6k3oox.jpg'
                     Constraint {
                         width = 'parent'
                         height = 800
                         topToBottom = 1
                     }
                 }
             }

             /*
              * There can only be one top-level declaration
              */
             Composite {
                 Custom {
                     color = '#F6F6F6'
                     Constraint {
                         width = 'parent'
                         height = 'parent'
                     }
                 }
                 Constraint {
                     width = 1200
                     height = 1200
                 }
             }
             """
