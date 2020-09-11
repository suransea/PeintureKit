# PeintureKit

A DSL drawing toolkit.

## Example

The DSL:

```javascript
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
        src = 'https://w.wallhaven.cc/full/6k/wallhaven-6k3oox.jpg'
        contentMode = 'scaleAspectFit'
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
```

The usage:

```swift
let drawer = Drawer()
let image = try drawer.drawImage(vl: dsl)
```

you can also get the view with:

```swift
let drawer = Drawer()
let view = try drawer.drawView(vl: dsl)
```

The image loader is "defaultImageLoader" by default, blocking and no cache.
A blocking image loader required to output a image, 
but not to output a view to be displayed. 
You can also customize the image loader.


The result:

![example](https://i.loli.net/2020/09/11/PuRYEIS8xZzrFbg.png)

## Widgets

### Common
```
id           // integer
color        // background color, ex: '#FFFFFF'
constraint   // declaration
transform    // declaration
contentMode  // 'scaleToFill'
                'scaleAspectFit'
                'scaleAspectFill'
                'redraw'
                'center'
                'top'
                'bottom'
                'left'
                'right'
                'topLeft'
                'topRight'
                'bottomLeft'
                'bottomRight'
cornerRadius // float
```

#### Declaration

##### Constraint
```
The standard constraint:
<attr>To<attr> =|<=|>= (<id>, <constant>, <multiplier>)

ex:
topToBottom = (1, 100, 1)

could be omitted if constant is 0, multiplier is 1:
topToTop = 1            <=>  topToTop = (1, 0, 1)
leftToRight = (1, 100)  <=>  leftToRight = (1, 100, 1)

The "to" attribute could be omitted, for dimemsion(width or height):
width = 'parent'  <=>  widthToWidth = ('parent', 0, 1)
width = 100       <=>  widthToUnspecific = (-1, 100, 1)

for others:
top = 'parent'    <=>  topToTop = ('parent', 0, 1)
top = 100         <=>  topToTop = ('parent', 100, 1)

Attrbutes:
unspecific,
width, height,
left, right, top, bottom, leading, trailing,
firstBaseline, lastBaseline, centerX, centerY
```

##### Transform 
```
pivot        // ex: (0.5, 0.5)
translation  // (x, y)
scale        // (x, y)
rotation     // angle
alpha        // float in [0, 1], 0 is transparent
```

### Text
```
text       // the main argument
textSize   // ex: '16sp'
textColor  // ex: '#333333'
textStyle  // 'bold'
              'italic'
              'normal'
textWeight // 'thin'
              'regular'
              'black'
              'bold'
              'heavy'
              'light'
              'medium'
              'semibold'
              'ultraLight'
deleteLine // boolean
underLine  // boolean
```

### Image
```
src        // image url, also as the main argument
```

### Empty
No specific arguments.

## License

[MIT License](https://www.mit-license.org)
