(* lab1/lexer.mli *)

(* |token| -- scan a token and return its code *)
val token : Lexing.lexbuf -> Parser.token

(* |lineno| -- number of current line *)
val lineno : int ref

(* |get_vars| -- list of identifiers used in program *)
val get_vars : unit -> Tree.ident list
