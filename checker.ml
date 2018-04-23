open Expr_ast
open Axioms
open Infer

let rec eval proof axioms env msg =
    match proof with
      | [] -> (msg, true, env)
      | (x :: xs) -> 
        match x with 
          | Box (a, b) -> 
            let (new_msg, is_valid, _) = eval b axioms (a :: env) msg in
              if is_valid
              then eval xs axioms ((Box (a, b)) :: env) (msg ^ new_msg)
              else ((msg ^ new_msg), false, [])
          | _ -> 
            let (new_msg, res) = can_derive x env axioms false in
            if res
            then eval xs axioms (x :: env) (msg ^ new_msg)
            else (msg ^ new_msg, false, [])


let check_proof id goal proof axioms =
    let good_news = "-> " ^ id ^
      " proven correctly, assuming as an axiom.\n\n" in
    let bad_news = "-X " ^ id ^ 
      "'s proof ended unexpectedly, skipping.\n\n" in
    let axiom_msg =  "-> " ^ id ^ 
      "'s goal isomorphic to an axiom, skipping proof.\n\n" in

    if List.mem (new_axiom goal) axioms
    then (axiom_msg, true)
    else 
        let (msg, conclusion, env) = eval proof axioms [True] "" in
          if conclusion && List.mem goal env
          then (msg ^ good_news, true)
          else (msg ^ bad_news, false)
