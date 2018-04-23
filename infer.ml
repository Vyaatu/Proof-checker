open Expr_ast
open Axioms
open Deduction_rules


let rec can_derive expr env axioms no_loop =
    let enhance_env x = 
        let symmetrical expr =
            match expr with
              | And (a, b) -> [And (a, b); And (b, a)]
              | Or (a, b) -> [Or (a, b); Or (b, a)]
              | Eq (a, b) -> [Eq (a, b); Eq (b, a)]
              | r -> [r] in
        List.flatten (List.map symmetrical x) 
    in
      let rec contingency_plan expr env axioms der =
          match der with
            | [] -> ("FATAL ERROR: could not derive " 
                    ^ (print_body expr) ^ " as valid.\n",
                    false) 
            | x :: xs -> 
              let (msg, res) = 
                  can_derive expr (x :: env) axioms true in
              if res
              then ("Warning: could not infer " ^ (print_body expr) ^
                    " from its environment. " ^ (print_body x) 
                    ^ " was missing - fixed automatically.\n",
                    true)
              else contingency_plan expr env axioms xs 
    in
      let continue () =
        let deducted1 = deduct (enhance_env env) in
          if List.mem expr deducted1
          then ("", true)
          else 
            let deducted2 = deduct_from_axioms axioms (enhance_env env) in
            if List.mem expr deducted2
            then ("", true)
            else 
                if no_loop
                then ("", false)
                else contingency_plan expr env axioms (deducted1 @ deducted2)
    in
      let axiom_form = new_axiom expr in
        if List.mem axiom_form axioms
        then ("", true)
        else
          match expr with
            | Or (a, b) -> 
              let (_, res1) = 
                can_derive a (enhance_env env) axioms no_loop in
              let (_, res2) = 
                can_derive b (enhance_env env) axioms no_loop in
                  if res1 || res2
                  then ("", true) 
                  else continue ()
            | _ -> continue ()
