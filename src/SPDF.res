
open PDF
open Promise
open Webapi.Dom
open Belt 

type size = {
  scale: float,
  width: float,
  height: float,
  viewport: PDF.viewport
}

type pdfView = {
  page: PDF.page,
  scale: float,
  width: float,
  height: float,
  viewport: PDF.viewport,
  id: int
}

type element = Dom.element
type pageList = array<PDF.page>

external unsafeToVirtualizedItem : array<pdfView> => array<VirtualizedList.item> = "%identity"

let spfdId = "spdf-Id"
let canvasClassName = "pdf-canvas"

let downloadPDF = (url: string) => {
  let pdfjs = pdfjsLib.getDocument(.url)
  pdfjs.promise
}

let createCanvas = (id: int) => {
  let canvas = document -> Document.createElement("canvas")
  canvas -> Element.setAttribute(spfdId, id -> Int.toString)
  canvas -> Element.setClassName(canvasClassName)
  canvas
}

let setCanvasSize = (~width:float, ~height:float, canvas: Dom.element) => {
  canvas -> Element.setAttribute("width", width -> Float.toString)
  canvas -> Element.setAttribute("height", height -> Float.toString)
  canvas
}

let getRenderContext = (viewport: PDF.viewport, canvas) => {
  let canvasContext = canvas-> Webapi.Canvas.CanvasElement.getContext2d
  {
    canvas,
    viewport,
    canvasContext
  }
}

let getDivWidth = (root: Dom.element) => {
  let wrapperComputedStyle = window -> Window.getComputedStyle(root)
  let left:float = wrapperComputedStyle -> CssStyleDeclaration.paddingLeft -> Float.fromString -> Option.getExn
  let right = wrapperComputedStyle -> CssStyleDeclaration.paddingRight -> Float.fromString -> Option.getExn
  let width = root -> Element.clientWidth -> Int.toFloat -. left -. right
  width
}

let getSize =  (root: Dom.element, page: PDF.page) => {
  let width = getDivWidth(root)
  let scale = width /. page.getViewport(. { scale: 1.0 }).width
  let viewport = page.getViewport(. { scale: scale }) 
  {
    scale: scale,
    width: viewport.width,
    height: viewport.height,
    viewport
  }
}

let setScale = (el: Dom.element, scale) => {
  el -> HtmlElement.ofElement -> Option.getExn -> HtmlElement.style -> CssStyleDeclaration.setPropertyValue("transform-origin", "0 0")
  el -> HtmlElement.ofElement -> Option.getExn -> HtmlElement.style -> CssStyleDeclaration.setPropertyValue("transform", `scale(${scale -> Float.toString})`)
  el
}

let setWillChange = (el: Dom.element, value: bool) => {
  let style = el -> HtmlElement.ofElement -> Option.getExn -> HtmlElement.style
  if (value) {
    style -> CssStyleDeclaration.setPropertyValue("will-change", "auto")
  } else {
    style -> CssStyleDeclaration.removeProperty("will-change") -> ignore
  }
  el
}

let initPages = (pdf) => {
  Array.makeBy(pdf.numPages, i => pdf.getPage(. i + 1)) -> all
}

let getId = (el) => {
  el -> Element.getAttribute("v-id") -> Option.flatMap(Int.fromString)
}

let makeView = (. root, id, page) => {
  let { scale, height, width, viewport } = getSize(root, page)
  {
    scale, 
    height,
    width,
    viewport,
    page,
    id
  }
}

let makeViewList = (pdfArray, root) => {
  pdfArray -> Array.mapWithIndexU((. index, page) => makeView(. root, index, page))
}

let make = async (~url: string, ~root: element) => {
  let pdf = await downloadPDF(url)
  let pageList = await initPages(pdf)
  let pdfViewList = pageList -> makeViewList(root) -> ref
  let rerenderTimer = ref(None)

  let getView = (el) => {
    let id = el -> getId
    switch id {
      | Some(id) => pdfViewList.contents -> Array.get(id) 
      | None => None
    }
  }

  let renderPDF = (el) => {
    el -> getView -> Option.flatMap((view) => {
      let rect = el -> Element.getBoundingClientRect
      let { id, page, viewport } = view

      let width = rect -> DomRect.width
      let height = rect -> DomRect.height
      let canvas = createCanvas(id) -> setCanvasSize(~width=width, ~height=height) 

      let renderContext = viewport -> getRenderContext(canvas)
      page.cleanupAfterRender = true 
      let task = page.render(. renderContext)
      task.promise -> thenResolve((_) => {
        %raw("el.replaceChildren(canvas)") -> ignore
      }) -> catch((_e) => resolve())  -> ignore
      Some(task) 
    }) 
  }

  let removePDF = (el) => {
    %raw("el.replaceChildren()") -> ignore
    let view = el -> getView -> Option.getExn
    view.page._destroy(.)
    view.page.cleanup(.)
    el
  }
 
  let onVisible = (. el) => { 
    el -> renderPDF -> ignore 
    ()
  }
  let onHidden = (. el) => {
    el -> removePDF -> ignore
    ()
  } 

  let onResize = (. el) => {
    setWillChange(el, true) -> ignore

    let canvasParentList = el -> Element.querySelectorAll("." ++ canvasClassName) -> Webapi.Dom.NodeList.toArray -> Array.mapU((. canvas) => {
      let parentNode = canvas -> Node.parentElement -> Option.getExn
      let divWidth = parentNode -> Element.getBoundingClientRect -> DomRect.width
      let canvasWidth = canvas -> Element.ofNode -> Option.flatMap(Element.getAttribute(_, "width")) -> Option.flatMap(Float.fromString) -> Option.getExn
      let scale = divWidth /. canvasWidth
      canvas -> Element.ofNode -> Option.getExn -> setScale(scale) -> ignore
      parentNode
    })

    el -> Element.querySelectorAll("." ++ VirtualizedList.divClassName) -> Webapi.Dom.NodeList.toArray -> Array.forEachWithIndexU((. i, div) => {
      let view = div -> Element.ofNode -> Option.flatMap(getView) -> Option.getExn
      let result = makeView(. el, i, view.page)

      pdfViewList.contents -> Array.setExn(i, result)
    })


    let _ = switch rerenderTimer.contents {
      | Some(timerId) => Js.Global.clearTimeout(timerId)
      | _ => ()
    }
    rerenderTimer := Js.Global.setTimeout(() => {
      canvasParentList -> Array.forEachU((. div) => {
        renderPDF(div) -> ignore
        ()
      }) -> ignore
      setWillChange(el, false) -> ignore
      ()
    }, 300) -> Some

    ()
  }

  VirtualizedList.make(~dom=root, ~list=pdfViewList.contents -> unsafeToVirtualizedItem, ~onHidden=onHidden, ~onVisible=onVisible, ~onResize=onResize)
} 