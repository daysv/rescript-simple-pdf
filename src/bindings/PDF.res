type canvas = Dom.element
type canvasContext = Webapi__Canvas.Canvas2d.t

type pdfDoc

type renderTask = {
  promise: Js.Promise.t<pdfDoc>,
  cancel: () => unit
}

type viewporOptions = {
  scale: float
}

type viewport = {
  height: float,
  width: float
}

type renderContext = {
  canvas,
  canvasContext,
  viewport
}
type page = {
  getViewport: (. viewporOptions) => viewport,
  render: (. renderContext) => renderTask,
  cleanup: (. unit) => unit,
  _destroy: (. unit) => unit,
  view: array<float>,
  mutable cleanupAfterRender: bool
}
type pdf = {
  getPage: (. int) => Js.Promise.t<page>,
  numPages: int 
}
type pdfjs = { 
  promise: Js.Promise.t<pdf>
}
type pdfjsLib = {
  getDocument: (. string) => pdfjs,
}

@scope("window")
external pdfjsLib: pdfjsLib = "pdfjsLib"