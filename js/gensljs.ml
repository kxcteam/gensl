open Js_of_ocaml

[@@@ocaml.warning "-33"]

open Genslib
open Gensl
open Parsing

open Basetypes
open Parsetree

open ParserTypes

let trylex str =
  let open Sedlexing in
  let open Format in
  printf "we got %s\n" str;
  let lexbuf = Utf8.from_string str in
  let result = Genslex.token lexbuf in
  (match result with
   | TkNumeric(a,b) -> printf "%s.%s\n" a b
   | _ -> printf "idk\n");
  print_flush()

let tryparse str =
  let open Sedlexing in
  let open Format in
  let module P = Parser.Default in
  let lexbuf = Utf8.from_string str in
  P.read_top (pstate lexbuf) |> function
  | Ok (toplevel,_) ->
     asprintf "%a" ParsetreePrinter.pp_toplevel toplevel
     |> Js.string |> Js.Unsafe.coerce
  | e -> ("parse error", e) |> Json.output |> Js.Unsafe.coerce

let () =
  let api = (object%js
               method trylex str = str |> Js.to_string |> trylex
               method tryparse str = str |> Js.to_string |> tryparse
               method lex str =
                 let str = str |> Js.to_string in
                 let open Sedlexing in
                 let lexbuf = Utf8.from_string str in
                 Genslex.token lexbuf
             end) in
  Js.export "Gensl" api

let debug x =
  let msg = Json.output x
  in Js.Unsafe.(fun_call (global##.console##.log) [|msg|>coerce|]) |> ignore

let debug_string msg =
  Js.Unsafe.(fun_call (global##.console##.log) [|msg|>Js.string|>coerce|]) |> ignore

let () =
  if Array.length Sys.argv > 1
  then tryparse Sys.argv.(1) |> debug
  else ()

let add_texts texts =
  let repl_history = Dom_html.getElementById "repl-history" in
  let paragraph = Dom_html.createP Dom_html.document in
  List.iter
    (fun text ->
       Dom.appendChild paragraph (Dom_html.document##createTextNode text))
    texts;
  Dom.appendChild repl_history paragraph

let clear_input () =
  let input_field = Dom_html.getElementById "input-field" in
  Js.Unsafe.set input_field "value" ""

let () =
  let open Sedlexing in
  let open Format in
  let module P = Parser.Default in
  let input_field = Dom_html.getElementById "input-field" in
  let keypress = Dom.Event.make "keypress" in
  let _ =
    Dom.addEventListener
      input_field
      keypress
      (Dom.handler (fun e ->
           if e##.key == Js.string "Enter" then
             begin
               let input_value = Js.Unsafe.get input_field "value" in
               let parsed_value = tryparse (Js.to_string input_value) in
               add_texts [(Js.string "gensl> "); input_value];
               add_texts [parsed_value];
               clear_input ();
               Js._false
             end
           else
             Js._true))
      Js._true in
  ()
