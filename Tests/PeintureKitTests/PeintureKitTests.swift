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
}

let testVl = """
             // Use keyword "let" to declare a custom view
             let Custom = Composite {
                 Text('Hello') {
                     width = 'wrap'
                     height = 'wrap'
                     id = 1
                     textSize = '12dp'
                     textColor = '#333333'
                     Margin {
                         top = '10dp'
                     }
                     Constraint {
                         ll = 'parent'
                         rr = 'parent'
                         tt = 'parent'
                     }
                 }
                 Image {
                     width = 'match'
                     height = 'wrap'
                     src = 'https://w.wallhaven.cc/full/6k/wallhaven-6k3oox.jpg'
                     Margin {
                         top = '10dp'
                     }
                     Constraint {
                         ll = 'parent'
                         rr = 'parent'
                         tb = 1
                     }
                 }
             }

             /*
              * There can only be one top-level declaration
              */
             Composite {
                 // size = '300dp'  // width = height = '300dp'
                 width = '300dp'
                 height = 'wrap'
                 Custom {
                     color = '#F6F6F6'
                     width = 'match'
                     height = 'wrap'
                     Constraint {
                         ll = 'parent'
                         rr = 'parent'
                         tt = 'parent'
                         bb = 'parent'
                     }
                 }
             }
             """
