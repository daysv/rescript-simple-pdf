open Webapi.Dom

module FindParentScroller = {
  let body =
    document
    ->Document.asHtmlDocument
    ->Belt.Option.flatMap(HtmlDocument.body)
    ->Belt.Option.getUnsafe

  let style = (dom: Dom.element, prop: string) => {
    window -> Window.getComputedStyle(dom) -> CssStyleDeclaration.getPropertyValue(prop)
  }

  let mactchScrollable = (dom: Dom.element) => {
    let regex = %re("/(auto|scroll)/") 
    regex -> Js.Re.test_(
        style(dom, "overflow") ++
        style(dom, "overflow-y") ++ 
        style(dom, "overflow-x")
      ) 
  }

  let rec make = (dom: option<Dom.element>) => { 
    switch dom {
      | Some(el) => { 
        if el -> mactchScrollable { 
          el
        } else { 
          make(el -> Element.asNode -> Node.parentElement)
        }
      } 
      | _ => body
    }
  }    
}