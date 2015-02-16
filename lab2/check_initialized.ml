module InitSet = Set.Make( String )

let get_name e = 
  match e.e_guts with
      Variable x -> 
        x.x_name
    | _ -> failwith "not a variable"

let rec check_expr_init init_set e =
    match e.e_guts with
      Variable x ->
        if not (InitSet.mem x.x_name init_set) then failwith "ERROR VARIABLE NOT INITIALIZED"
    | Number n -> ()
    | Sub (e1, e2) ->
        let _ = check_expr_init init_set e1
        and _ = check_expr_init init_set e2 in ()
    | Monop (w, e1) -> check_expr_init init_set e1 
    | Binop (w, e1, e2) -> 
        let _ = check_expr_init init_set e1
        and _ = check_expr_init init_set e2 in ()

let rec check_init_stmt init_set = 
  function
      Seq ss -> List.fold_left (check_init_stmt ) init_set  ss
    | Assign(lhs, rhs) -> 
        let _ = check_expr init_set rhs in
        InitSet.union init_set (InitSet.singleton (get_name lhs))
    | Print e -> 
        let _  = check_expr_init init_set e in
        init_set
    | IfStmt (cond, thenpt, elsept) ->
        let then_initset = check_init_stmt init_set thenpt and
        else_initset = check_init_stmt init_set elsept and 
        _ = check_expr_init init_set cond in
        InitSet.inter then_initset else_initset
    | WhileStmt (cond, body) ->
        let body_initset = check_init_stmt init_set body and
        _ = check_expr_init init_set cond in
        InitSet.union init_set body_initset
    | _ -> init_set
