(*
    File : brainfuck.ml
    Version : 1.0
    Author : Max D3
*)



(** GUI **)

#load "graphics.cma" ;;

open Graphics ;;
Graphics.open_graph "" ;;
Graphics.set_window_title "BrainF*ck Code Eval!" ;;



(** TYPES **)

(* I/O mode *)
type mode = ASCII | Decimal



(** BASIC FUNCTIONS AND SOHRTCUTS **)

let hd = List.hd
let tl = List.tl

let (+=) a b = (a := (!a + b))
let (-=) a b = (a := (!a - b))

let (@@) = Array.append

let rec ( *@) arr n = if n <= 0 then [||] else arr @@ (arr *@ (n-1)) 
let rec ( *^) str n = if n <= 0 then ""   else str  ^ (str *^ (n-1))

let pause secs =
    let t = Sys.time () in
    while Sys.time () < (t +. secs) do
        ()
    done



(** GRAPHICS **)

let white = rgb 248 248 242
let dark = rgb 39 40 34
let lighter_gray = rgb 200 200 200
let light_red = rgb 249 38 114


let traceText g =
    set_color dark ; fill_rect 0 0 600 500 ;
    set_color (rgb 60 60 60) ;
    fill_rect g 208 (598 - 2*g) 0 ;
    fill_rect g 191 (598 - 2*g) 0 ;
    moveto 174 380 ;
    set_color white ;
    set_font "-*-fixed-medium-r-semicondensed--25-*-*-*-*-*-iso8859-1" ;
    draw_string "BrainF*ck Code Eval" ;
    moveto 8 430 ;
    set_font "9x15" ;
    set_color lighter_gray ;
    draw_string "version 1.0"


let traceColumn g pos valeur =
    set_color white ;
    if valeur > 0 then
        fill_rect (g + 17*pos) 209 15 (valeur - 1)
    else if valeur < 0 then
        fill_rect (g + 17*pos) (191 + valeur) 15 (-valeur - 1)


let clearColumn g pos valeur =
    set_color dark ;
    if valeur > 0 then
        fill_rect (g + 17*pos) 209 15 (valeur - 1)
    else if valeur < 0 then
        fill_rect (g + 17*pos) (191 + valeur) 15 (-valeur - 1)


(* edits the column vith a variation delta \in {-1 , 1} *)
let editeColone g pos val_init delta =
    let g' = g + 17*pos in
    if (abs delta) > 1 then
        (clearColumn g pos val_init ; traceColumn g pos (val_init + delta))
    else if val_init > 0 then
        if delta > 0 then
            fill_rect g' (209 + val_init) 15 0
        else
            (set_color dark ; fill_rect g' (209 + val_init - 1) 15 0)
    else if val_init < 0 then
        if delta = (-1) then
            fill_rect g' (191 + val_init - 1) 15 0
        else
            (set_color dark ; fill_rect g' (191 + val_init) 15 0)
    else begin (* cas ou val_init = 0 *)
        traceColumn g pos delta
    end


let tracePtr g pos couleur =
    set_color couleur ;
    fill_rect (g + 17*pos) 192 15 15 


let traceInstant mem ptr =
    let g = (600 - ((Array.length mem) * 17)) / 2 in (
    clear_graph () ;
    traceText g ;
    let len = Array.length mem in
    for i = 0 to (len -1) do
        traceColumn g i mem.(i)
    done ; tracePtr g ptr light_red
    )


let traceVariation mem1 mem2 ptr_i ptr_f =
    set_color white ;
    let g = (600 - ((Array.length mem1) * 17)) / 2 in (
    let len = Array.length mem2 in
    for i = 0 to (len -1) do
        if mem1.(i) == mem2.(i) then () else
        editeColone g i mem1.(i) (mem2.(i) - mem1.(i))
    done ;
    if ptr_f = ptr_i then ()
    else (tracePtr g ptr_i dark ; tracePtr g ptr_f light_red)
    )



(* EVALUATION *)

let rec jump code i c = match code.[i] with
    | '[' -> jump code (i+1) (c+1)
    | ']' -> if c = 1 then i else jump code (i+1) (c-1)
    |  _  -> jump code (i+1) c


let input mode =
    print_string "Input a value: " ;
    int_of_string (Bytes.extend (read_line ()) 0 (-2))


let output i mode =
    if mode = Decimal then
        (print_string ("Output: " ^ (string_of_int i)) ; print_newline ())
    else
        print_char (Char.chr i)


let brainfuck code size mode secs =
    let t = Sys.time () in
    let mem = [|0|] *@ (size) in
    let len = String.length code in
    traceInstant mem 0 ; pause 0.3 ;
    let exec code p i l = match code.[i] with
        | '>' -> (p + 1, i + 1, l)
        | '<' -> (p - 1, i + 1, l)
        | '+' -> (mem.(p) <- mem.(p) + 1 ; (p, i+1, l))
        | '-' -> (mem.(p) <- mem.(p) - 1 ; (p, i + 1, l))
        | ',' -> (mem.(p) <- input mode ; (p, i + 1, l))
        | '.' -> (output mem.(p) mode ;
                 (p, i + 1, l))
        | '[' -> if mem.(p) = 0 then (p, 1 + (jump code i 0), l)
                 else (p, i + 1, (i+1)::l)
        | ']' -> if mem.(p) = 0 then (p, i + 1, (tl l))
                 else (p, (hd l), l)
        |  _  -> (p, i + 1, l)
    in let rec eval_etape cycle p i l =
        if Sys.time () > (20.0 +. t) then failwith "Timeout"
        else if i = len then 0
        else
            let mem_i, p_i = Array.copy mem, p in
            let (p, i, l) = exec code p i l in
            traceVariation mem_i mem p_i p ;
            pause secs ;
            if p < 0 (* || p > 29 *) then 0
            else eval_etape (cycle + 1) p i l
    in eval_etape 0 0 0 []
