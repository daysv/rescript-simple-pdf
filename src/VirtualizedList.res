open Belt
open Webapi.Dom

type item = {
  height: float,
  width: float
}

type t = {
  visibleObserver: Dom.intersectionObserver,
  resizeObserver: Webapi.ResizeObserver.t, 
  dom: Dom.element,
  root: Dom.element
}

let divClassName = "pdf-page"
let divId = "v-id"

let makeVisibleObserver = (onVisible: (. Dom.element) => unit, onHidden: (. Dom.element) => unit, dom: Dom.element) => {
  let handler = (entries, _observer) => {
    entries -> Array.forEachU((. entry) => {
      let target = entry -> Webapi.IntersectionObserver.IntersectionObserverEntry.target 
      if entry -> Webapi.IntersectionObserver.IntersectionObserverEntry.isIntersecting {
        onVisible(. target)
      } else {
        onHidden(. target)
      }
      ()
    }) -> ignore
    ()
  }
  let parentElement = Some(dom) -> Utils.FindParentScroller.make
  let marginHeight = (parentElement -> Element.clientHeight) / 2
  let marginHeight = marginHeight -> Int.toString
  let config = Webapi.IntersectionObserver.makeInit(~root=parentElement, ~rootMargin=`${marginHeight}px 0px ${marginHeight}px 0px`, ())
  Webapi.IntersectionObserver.makeWithInit(handler, config)
}


let setDomSize = (~width: float, ~height: float, dom) => { 
  let style =  dom -> HtmlElement.ofElement -> Option.getExn -> HtmlElement.style
  style -> CssStyleDeclaration.setPropertyValue("width", width -> Float.toString ++ "px")
  style -> CssStyleDeclaration.setPropertyValue("height", height -> Float.toString ++ "px")
  style -> CssStyleDeclaration.setPropertyValue("overflow", "hidden")
  style
} 

let makeResizeObserver = (onResize: (. Dom.element) => unit) => {
  let handler = (entries) => {
    entries -> Array.forEach(entry => {
      let contentRect = entry -> Webapi.ResizeObserver.ResizeObserverEntry.contentRect
      let target = entry -> Webapi.ResizeObserver.ResizeObserverEntry.target

      let rootWidth = contentRect -> DomRect.width

      target -> Element.querySelectorAll("." ++ divClassName) -> Webapi.Dom.NodeList.toArray -> Array.forEachU((. el) => {
        let style = el -> Element.ofNode -> Option.flatMap(HtmlElement.ofElement) -> Option.getExn -> HtmlElement.style
        let width = style -> CssStyleDeclaration.width -> Float.fromString -> Option.getExn
        let height = style -> CssStyleDeclaration.height -> Float.fromString -> Option.getExn
        let scale = width /. rootWidth
        let height = height /. scale
        el -> Element.ofNode -> Option.getExn -> setDomSize(~width=rootWidth, ~height=height) -> ignore
        ()
      }) -> ignore
      onResize(. target)
      ()
    })
  }
  Webapi.ResizeObserver.make(handler)
}

let createDiv = (~width: float, ~height: float, ~id: string) => {
  let div = document -> Document.createElement("div") 
  div -> setDomSize(~width=width, ~height=height) -> ignore
  div -> Element.setAttribute(divId, id)
  div -> Element.setClassName(divClassName)
  div
}

let make = (~dom: Dom.element, ~list: array<item>, ~onVisible: (. Dom.element) => unit, ~onHidden: (. Dom.element) => unit, ~onResize: (. Dom.element) => unit): t => {
  let visibleObserver = makeVisibleObserver(onVisible, onHidden, dom)
  let resizeObserver = makeResizeObserver(onResize)
  let root = document -> Document.createElement("div")
  list -> Array.mapWithIndexU((. index, item) => {
    let div = createDiv(~width=item.width, ~height=item.height, ~id=index -> Int.toString)
    visibleObserver -> Webapi.IntersectionObserver.observe(div)
    root -> Element.appendChild(~child=div)
  }) -> ignore
  dom -> Element.appendChild(~child=root)
  resizeObserver -> Webapi.ResizeObserver.observe(dom)
  {
    visibleObserver,
    resizeObserver,
    dom,
    root,
  }
}

let destroy = ({ visibleObserver, resizeObserver, dom, root }) => {
  visibleObserver -> Webapi.IntersectionObserver.disconnect
  resizeObserver -> Webapi.ResizeObserver.disconnect
  dom -> Element.asNode -> Node.removeChild(~child=root)
}
