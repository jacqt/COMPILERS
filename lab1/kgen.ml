open Tree
open Keiko

let optflag = ref false

(* |gen_expr| -- generate code for an expression *)
let rec gen_expr =
  function
      Variable x ->
        SEQ [LINE x.x_line; LDGW x.x_lab]
    | Number x ->
        CONST x
    | Monop (w, e1) ->
        SEQ [gen_expr e1; MONOP w]
    | Binop (w, e1, e2) ->
        SEQ [gen_expr e1; gen_expr e2; BINOP w]

(* |gen_cond| -- generates the opposite binop function for comparisons *)
let opposite_binop = function
    Eq -> Neq
   |Neq -> Eq
   |Lt -> Geq
   |Geq -> Lt
   |Gt -> Leq
   |Leq -> Gt
   | _ -> failwith "can't use me with that!"

(* |gen_cond| -- generate code for short-circuit condition *)
(* We pass in the truth label, false label, as well as a boolean telling us whether the code block*)
(* directly following is the 'truth' body or the 'false' body*)
let rec gen_cond tlab flab e tlab_follows=
  (* Jump to |tlab| if |e| is true and |flab| if it is false *)
  (* Also returns information regarding withether tlab or flab was used in the construction of the condition*)
  match e with
      Number x ->
        if x <> 0 then (JUMP tlab, true, false) else (JUMP flab, false, true)
    | Binop ((Eq|Neq|Lt|Gt|Leq|Geq) as w, e1, e2) ->
          if (tlab_follows) then 
        (SEQ [gen_expr e1; gen_expr e2;
              JUMPC ( opposite_binop w, flab);], false, true) else 
        (SEQ [gen_expr e1; gen_expr e2;
              JUMPC ( w, tlab);], true, false) 
    | Monop (Not, e1) ->
        let (cond, flab_used, tlab_used) = gen_cond flab tlab e1 (not tlab_follows) in
        (cond, tlab_used, flab_used)
    | Binop (And, e1, e2) ->
        let lab1 = label () in
        let (cond1, lab1_used, flab_used_1) = gen_cond lab1 flab e1 true in
        let (cond2, tlab_used, flab_used_2) = gen_cond tlab flab e2 tlab_follows in
        (SEQ [cond1 ; if (lab1_used) then LABEL lab1 else SEQ []; cond2 ], tlab_used, flab_used_1 || flab_used_2)
    | Binop (Or, e1, e2) ->
        let lab1 = label () in
        let (cond1, tlab_used_1, lab1_used) = gen_cond tlab lab1 e1 false in
        let (cond2, tlab_used_2, flab_used) = gen_cond tlab flab e2 tlab_follows in
        (SEQ [cond1 ; if (lab1_used) then LABEL lab1 else SEQ []; cond2 ], tlab_used_1 || tlab_used_2, flab_used)
    | _ ->
        if (tlab_follows) then
            (SEQ [gen_expr e; JUMPB (false, flab); ], false, true) else 
            (SEQ [gen_expr e; JUMPB (true, tlab); ], true, false) 

(* |gen_nested_body| -- generate code for a statement in a if/else statement*)
let rec gen_nested_body exit_label a =
  match a with
      Skip -> NOP
    | Seq stmts -> SEQ (List.map (gen_nested_body exit_label) stmts)
    | Assign (v, e) ->
        SEQ [LINE v.x_line; gen_expr e; STGW v.x_lab]
    | Print e ->
        SEQ [gen_expr e; CONST 0; GLOBAL "Lib.Print"; PCALL 1]
    | Newline ->
        SEQ [CONST 0; GLOBAL "Lib.Newline"; PCALL 0]
    | IfStmt (test, thenpt, elsept) ->
        let lab1 = label () and lab2 = label () in
        let (cond, lab1_used, lab2_used) = gen_cond lab1 lab2 test true in
        SEQ [cond; 
          if (lab1_used) then LABEL lab1 else SEQ []; gen_nested_body exit_label thenpt; JUMP exit_label;
          if (lab2_used) then  LABEL lab2 else SEQ []; gen_nested_body exit_label elsept;]
    | _ -> failwith "Too lazy to deal with while statements"

(* |gen_stmt| -- generate code for a statement *)
let rec gen_stmt =
  function
      Skip -> NOP
    | Seq stmts -> SEQ (List.map gen_stmt stmts)
    | Assign (v, e) ->
        SEQ [LINE v.x_line; gen_expr e; STGW v.x_lab]
    | Print e ->
        SEQ [gen_expr e; CONST 0; GLOBAL "Lib.Print"; PCALL 1]
    | Newline ->
        SEQ [CONST 0; GLOBAL "Lib.Newline"; PCALL 0]
    | IfStmt (test, thenpt, elsept) ->
        let lab1 = label () and lab2 = label () and lab3 = label () in
        let (cond, lab1_used, lab2_used) = gen_cond lab1 lab2 test true in
        SEQ [cond; 
          if (lab1_used) then LABEL lab1 else SEQ []; gen_nested_body lab3 thenpt; JUMP lab3;
          if (lab2_used) then  LABEL lab2 else SEQ []; gen_nested_body lab3 elsept; LABEL lab3]
    | _ -> failwith "Too lazy to deal with while statements"
    
(* |translate| -- generate code for the whole program *)
let translate (Program ss) =
  let code = gen_stmt ss in
  Keiko.output (if !optflag then Peepopt.optimise code else code)
