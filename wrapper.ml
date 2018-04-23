open Expr_ast
open Axioms
open Checker

let wrapper ((id, goal), proof, is_axiom) env =
    if is_axiom
    then ("-> " ^ id ^ " assumed as an axiom.\n\n", 
         env @ [new_axiom goal])
    else 
        let (msg, res) = check_proof id goal proof env in
        if res 
        then (msg, new_axiom goal :: env)
        else (msg, env)

let run input = 
    let rec iterate input env = 
      match input with
        | [] -> []
        | x :: xs -> 
          let (msg, new_env) = wrapper x env
          in msg :: iterate xs new_env
    in 
        Core.printf "Starting...\n\n";
        List.iter (fun v -> print_string v) (iterate input []);
        Core.printf "Done.\n";