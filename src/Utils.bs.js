// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Webapi__Dom__Document from "rescript-webapi/src/Webapi/Dom/Webapi__Dom__Document.bs.js";

var body = Belt_Option.flatMap(Webapi__Dom__Document.asHtmlDocument(document), (function (prim) {
        return Caml_option.nullable_to_opt(prim.body);
      }));

function style(dom, prop) {
  return window.getComputedStyle(dom).getPropertyValue(prop);
}

function mactchScrollable(dom) {
  var regex = /(auto|scroll)/;
  return regex.test(style(dom, "overflow") + style(dom, "overflow-y") + style(dom, "overflow-x"));
}

function make(_dom) {
  while(true) {
    var dom = _dom;
    if (dom === undefined) {
      return body;
    }
    var el = Caml_option.valFromOption(dom);
    if (mactchScrollable(el)) {
      return el;
    }
    _dom = Caml_option.nullable_to_opt(el.parentElement);
    continue ;
  };
}

var FindParentScroller = {
  body: body,
  style: style,
  mactchScrollable: mactchScrollable,
  make: make
};

export {
  FindParentScroller ,
}
/* body Not a pure module */
