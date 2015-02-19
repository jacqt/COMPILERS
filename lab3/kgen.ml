(* lab3/kgen.ml *)

open Tree 
open Dict 
open Keiko 
open Print 

let optflag = ref false

let level = ref 0

let slink = 12

let get_slink d = 
  let rec get_slink_h lvl d = 
    if lvl = d.d_level -1 then SEQ []
    else
      SEQ [CONST slink; BINOP Plus; LOADW; get_slink_h (lvl-1) d] in
    SEQ [LOCAL 0; get_slink_h (!level) d;]

(*|gen_addr| -- generate code to push address of a variable *)
let gen_addr d = 
  if d.d_level = 0 || d.d_off = 0 then
    GLOBAL d.d_lab
  else
    let rec gen_addr_h lvl d=
      if lvl  = d.d_level then
        CONST d.d_off
      else
        SEQ [CONST slink; BINOP Plus; LOADW; gen_addr_h (lvl-1) d; ] in 
    SEQ [LOCAL  0; gen_addr_h (!level) d; BINOP Plus; ]

(* |gen_expr| -- generate code for an expression *)
let rec gen_expr =
  function
      Variable x ->
        let d = get_def x in
        begin
          match d.d_kind with
              VarDef ->
                SEQ [LINE x.x_line; gen_addr d; LOADW]
            | ProcDef nargs -> 
                SEQ [LINE x.x_line; 
                get_slink d;
                gen_addr d;
                PACK]
        end
    | Number x ->
        CONST x
    | Monop (w, e1) ->
        SEQ [gen_expr e1; MONOP w]
    | Binop (w, e1, e2) ->
        SEQ [gen_expr e1; gen_expr e2; BINOP w]
    | Call (p, args) ->
        let gen_list_expr builtup = function e -> SEQ [builtup; gen_expr e] in
        let get_instr d =
          match d.d_kind with 
              VarDef -> SEQ [gen_addr d; LOADW; UNPACK]
            | ProcDef nargs ->  SEQ [get_slink d; gen_addr d;] in
            SEQ [LINE p.x_line;
                List.fold_left gen_list_expr (SEQ[]) (List.rev args); 
                get_instr (get_def p);
                PCALLW (List.length args)]

(* |gen_cond| -- generate code for short-circuit condition *)
let rec gen_cond tlab flab e =
  (* Jump to |tlab| if |e| is true and |flab| if it is false *)
  match e with
      Number x ->
        if x <> 0 then JUMP tlab else JUMP flab
    | Binop ((Eq|Neq|Lt|Gt|Leq|Geq) as w, e1, e2) ->
        SEQ [gen_expr e1; gen_expr e2;
          JUMPC (w, tlab); JUMP flab]
    | Monop (Not, e1) ->
        gen_cond flab tlab e1
    | Binop (And, e1, e2) ->
        let lab1 = label () in
        SEQ [gen_cond lab1 flab e1; LABEL lab1; gen_cond tlab flab e2]
    | Binop (Or, e1, e2) ->
        let lab1 = label () in
        SEQ [gen_cond tlab lab1 e1; LABEL lab1; gen_cond tlab flab e2]
    | _ ->
        SEQ [gen_expr e; JUMPB (true, tlab); JUMP flab]

(* |gen_stmt| -- generate code for a statement *)
let rec gen_stmt =
  function
      Skip -> NOP
    | Seq ss ->
        SEQ (List.map gen_stmt ss)
    | Assign (v, e) ->
        let d = get_def v in
        begin
          match d.d_kind with
              VarDef ->
                SEQ [gen_expr e; gen_addr d; STOREW]
           | _ -> failwith "assign"
        end
    | Print e ->
        SEQ [gen_expr e; CONST 0; GLOBAL "Lib.Print"; PCALL 1]
    | Newline ->
        SEQ [CONST 0; GLOBAL "Lib.Newline"; PCALL 0]
    | IfStmt (test, thenpt, elsept) ->
        let lab1 = label () and lab2 = label () and lab3 = label () in
        SEQ [gen_cond lab1 lab2 test; 
          LABEL lab1; gen_stmt thenpt; JUMP lab3;
          LABEL lab2; gen_stmt elsept; LABEL lab3]
    | WhileStmt (test, body) ->
        let lab1 = label () and lab2 = label () and lab3 = label () in
        SEQ [LABEL lab1; gen_cond lab2 lab3 test;
          LABEL lab2; gen_stmt body; JUMP lab1; LABEL lab3]
    | Return e ->
            SEQ [gen_expr e; RETURNW]

(* |gen_proc| -- generate code for a procedure *)
let rec gen_proc (Proc (p, formals, Block (vars, procs, body))) =
  let d = get_def p in
  level := d.d_level;
  let code = gen_stmt body in
  printf "PROC $ $ 0 0\n" [fStr d.d_lab; fNum (4 * List.length vars)];
  Keiko.output (if !optflag then Peepopt.optimise code else code);
  printf "ERROR E_RETURN 0\n" [];
  printf "END\n\n" [];
  List.iter gen_proc procs

(* |translate| -- generate code for the whole program *)
let translate (Program (Block (vars, procs, body))) =
  level := 0;
  printf "PROC MAIN 0 0 0\n" [];
  Keiko.output (gen_stmt body);
  printf "RETURN\n" [];
  printf "END\n\n" [];
  List.iter gen_proc procs;
  List.iter (function x -> printf "GLOVAR _$ 4\n" [fStr x]) vars
