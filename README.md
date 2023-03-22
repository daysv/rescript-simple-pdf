# ReScript Simple PDF


## Installation

```
npm install rescript-simple-pdf rescript-webapi --save
```

Add `rescript-simple-pdf` and `rescript-webapi` as dependencies in your `bsconfig.json`


## Usage

### Import pdf.js

```html
<script src="https://cdn.bootcdn.net/ajax/libs/pdf.js/3.3.122/pdf.min.js"></script>
```

### ReScript version

```rescript
open Webapi.Dom
let el = document -> Document.querySelector("div") -> Belt.Option.getExn
let _ = RescriptSimplePdf.SPDF.make(
    ~url="https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/examples/learning/helloworld.pdf", 
    ~root=el
) 
```

### JavaScript version

```javascript
import { make } from "rescript-simple-pdf"
make("https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/examples/learning/helloworld.pdf", document.getElementById("root"))
```

See the examples folder.
