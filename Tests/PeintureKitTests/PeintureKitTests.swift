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
                     color = '#00FFFFFF'
                     textSize = 180
                     textColor = '#333333'
                     Constraint {
                         centerX = 'parent'
                         top = 100
                     }
                 }
                 Image {
                     id = 2
                     contentMode = 'scaleAspectFit'
                     src = 'https://w.wallhaven.cc/full/6k/wallhaven-6k3oox.jpg'
                     Constraint {
                         width = 'parent'
                         heightToWidth = (2, 0, 0.5625)
                         topToBottom = (1, 100)
                     }
                 }
             }

             /*
              * There can only be one top-level declaration
              */
             Custom {
                 color = '#F6F6F6'
                 Constraint {
                     width = 1200
                     bottomToBottom = 2
                 }
             }
             """
