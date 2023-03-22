# ReScript Simple PDF


## Installation

```
npm install rescript-simple-pdf --save
```

```
Add `rescript-simple-pdf` as a dependency in your `bsconfig.json`:
```

## Usage

Import pdf.js

```html
<script src="https://cdn.bootcdn.net/ajax/libs/pdf.js/3.3.122/pdf.min.js"></script>
```


```rescript
RescriptSimplePdf.SPDF.make(~url="https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/examples/learning/helloworld.pdf", ~root=el -> Element.querySelector -> Option.getExn)
```

```javascript
import { make } from "rescript-simple-pdf"
make("https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/examples/learning/helloworld.pdf", document.getElementById("root"))
```

See the examples folder.
