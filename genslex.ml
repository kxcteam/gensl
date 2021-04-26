open Parsing
open ParserTypes

let digit = [%sedlex.regexp? '0' .. '9']
let octal = [%sedlex.regexp? '0' .. '7']
let hexalphabet = [%sedlex.regexp? '0' .. '9' | 'a' .. 'f' | 'A' .. 'F']
let hexbyte = [%sedlex.regexp? hexalphabet , hexalphabet]
let lowercase = [%sedlex.regexp? 'a' .. 'z']
let uppercase = [%sedlex.regexp? 'A' .. 'Z']
let alpha = [%sedlex.regexp? lowercase | uppercase]
let alphadigit = [%sedlex.regexp? alpha | digit]
let space = [%sedlex.regexp? ' ' | '\t' | '\n']
let base64alphabet = [%sedlex.regexp? alphadigit | '+' | '/' | '=']
let base64digit = [%sedlex.regexp? base64alphabet, base64alphabet, base64alphabet, base64alphabet]
let escape = [%sedlex.regexp?  ('\\', ('"' | '\\' | '\'' | 'n' | 'r' | 't' | 'b' | ' ' | (digit, digit, digit) | ('x', hexbyte)))]
let instring = [%sedlex.regexp? (Compl ('"' | '\\')) | escape]
let boolprefix = [%sedlex.regexp? "b:" | "bool:"]
let hexprefix = [%sedlex.regexp? "hex:"]
let base64prefix = [%sedlex.regexp? "b64:" | "base64:"]
let strbytesprefix = [%sedlex.regexp? "strbytes:"]
let csymbprefix_std = [%sedlex.regexp? "!"]
let csymbprefix_app = [%sedlex.regexp? "!!"]

let rec csymb_std buf = match%sedlex buf with
 | "toplevel" -> `Toplevel | "envelop" -> `Envelop | "metadata" -> `Metadata
 | "desc" -> `Desc | "hash" -> `Hash | "uuid" -> `Uuid | "version" -> `Version
 | "list" -> `List | "vector" -> `Vector | "set" -> `Set | "map" -> `Map
 | "int" -> `Int | "uint" -> `Uint | "float" -> `Float | "timestamp" -> `Timestamp
 | _ -> failwith "invalid tok"

and csymb_app buf = match%sedlex buf with
  | "app01" -> `Appsymb01 | "app02" -> `Appsymb02 | "app03" -> `Appsymb03
  | "app04" -> `Appsymb04 | "app05" -> `Appsymb05 | "app06" -> `Appsymb06
  | "app07" -> `Appsymb07 | "app08" -> `Appsymb08 | "app09" -> `Appsymb09
  | "app10" -> `Appsymb10 | "app11" -> `Appsymb11 | "app12" -> `Appsymb12
  | _ -> failwith "invalid tok"

and token buf =
  let lexeme = Sedlexing.Utf8.lexeme in
  let lexeme_length = Sedlexing.lexeme_length in
  let sub_lexeme = Sedlexing.Utf8.sub_lexeme in
  let lexeme_strip head tail buf =
    sub_lexeme buf head (lexeme_length buf - tail) in
  match%sedlex buf with
  | eof -> TkEof
  | Plus space -> TkSpaces (lexeme buf)
  (* token TkSymbol *)
  | lowercase, Star alphadigit -> TkSymbol (lexeme buf)
  (* token TkCodifiedSymbol *)
  | csymbprefix_std -> TkCodifiedSymbol (csymb_std buf)
  | csymbprefix_app -> TkCodifiedSymbol (csymb_app buf)
  (* token TkString *)
  | '"', Star instring, '"' ->
    TkString (Scanf.unescaped (lexeme_strip 1 1 buf))
  (* token TkBool *)
  | boolprefix, "true" -> TkBool true
  | boolprefix, "false" -> TkBool false
  (* token TkNumeric *)
  | Opt ('+' | '-'), Plus digit, ((Opt '.', Star digit) | ('/', Plus digit)),
    Opt (Plus alpha) ->
    let buf2 = Sedlexing.Utf8.from_string (lexeme buf) in
    let num = match%sedlex buf2 with
      | Opt ('+' | '-'), Plus digit, ((Opt '.', Star digit) | ('/', Plus digit)) ->
        lexeme buf2
      | _ -> failwith "impossible pattern unmatch: TkNumeric" in
    let suffix = match%sedlex buf2 with
      | Opt (Plus alpha) -> lexeme buf2
      | _ -> "" in
    TkNumeric (num, suffix)

  (* TkBytes *)
  | hexprefix, (Plus hexbyte) ->
    let buf2 = Sedlexing.Utf8.from_string (lexeme buf) in
    let () = match%sedlex buf2 with
      | hexprefix -> ()
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    let lxm = match%sedlex buf2 with
      | Plus hexbyte -> lexeme buf2
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    TkBytes (Hex.to_bytes (`Hex lxm))
  | base64prefix, (Plus base64digit) ->
    let buf2 = Sedlexing.Utf8.from_string (lexeme buf) in
    let () = match%sedlex buf2 with
      | base64prefix -> ()
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    let lxm = match%sedlex buf2 with
      | Plus base64digit -> lexeme buf2
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    TkBytes (Base64.decode_exn lxm |> Bytes.of_string)
  | strbytesprefix, '"', (Star instring), '"' ->
    let buf2 = Sedlexing.Utf8.from_string (lexeme buf) in
    let () = match%sedlex buf2 with
      | strbytesprefix -> ()
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    let lxm = match%sedlex buf2 with
      | '"', (Star instring), '"' -> lexeme_strip 1 1 buf2
      | _ -> failwith "impossible pattern unmatch: TkBytes" in
    TkBytes (Scanf.unescaped lxm |> Bytes.of_string)

  | '(' -> TkParenOpen
  | ')' -> TkParenClose
  | '[' -> TkBracketOpen
  | ']' -> TkBracketClose
  | '{' -> TkCurlyOpen
  | '}' -> TkCurlyClose

  | '#', (Opt (Plus digit)), '[' ->
    let k = (lexeme_strip 1 1 buf) in
    let k_opt = if k = "" then None else Some k in
    TkPoundBracketOpen (Option.map int_of_string k_opt)
  | "#{" -> TkPoundCurlyOpen

  | ",", (Plus digit) -> TkPickK (false, int_of_string (lexeme_strip 1 0 buf))
  | ".", (Plus digit) -> TkGrabK (false, int_of_string (lexeme_strip 1 0 buf))
  | ",", (Plus digit), "." -> TkPickK (true, int_of_string (lexeme_strip 1 1 buf))
  | ".", (Plus digit), "." -> TkGrabK (true, int_of_string (lexeme_strip 1 1 buf))
  | "," -> TkPickOne true
  | ",", space -> TkComma
  | ",," -> TkPickAll
  | ".." -> TkGrabAll
  | "." -> TkGrabOne true
  | ".", space -> TkGrabPoint

  | "=>" -> TkMapsto

  | ":" -> TkKeywordIndicator
  | "@>" -> TkAnnoNextIndicator
  | "@<" -> TkAnnoPrevIndicator
  | "@" -> TkAnnoStandaloneIndicator

  | _ -> failwith "invalid tok"

module Lexer : Lexer with
           type buffer = Sedlexing.lexbuf
       and type location = Lexing.position
  = struct
  type buffer = Sedlexing.lexbuf
  type location = Lexing.position
  type nonrec pstate = buffer pstate
  type nonrec lexresult = buffer lexresult

  type lexer_error += No_next_valid_token

  let loc _ = failwith "not implemented"
  (* let source buf = `DirectInput (Some (loc buf).pos_fname) *)
  let lexer buf =
    try
      let tok = token buf in
      Ok (tok, pstate buf)
    with Failure _ -> Error [Lexing_error No_next_valid_token]
end


(*
(*
type tmptok = [`Cat | `Dog | `Space | `SomeBool | `Eof]
[@@deriving sexp]
*)

let rec lexer buf =
(*   let open Sedlexing.Utf8 in *)
  match%sedlex buf with
  | "cat" | "dog" -> `Animal (Sedlexing.Utf8.lexeme buf)
  | "true" | "false" -> `Bool (Sedlexing.Utf8.lexeme buf)
  | white_space -> lexer buf
  | eof -> `Eof
(*
  | "dog" -> `Dog
  | ("true" | "false") -> `SomeBoole
  | white_space -> lexer buf
  | eof -> `Eof
*)
  | _ -> failwith "invalid tok"
*)