open Expr_ast

type axiom =
    | T
    | F
    | V of int
    | A of axiom * axiom
    | O of axiom * axiom
    | I of axiom * axiom
    | E of axiom * axiom
    | N of axiom


let rec list_vars expr =
  match expr with
    | Var a -> [a]
    | And (a, b) | Or (a, b) | Impl (a, b) | Eq (a, b)
      -> list_vars a @ list_vars b
    | Neg a -> list_vars a
    | _ -> []


let new_axiom goal =
    let fn = (fun a b -> (a, b)) in
    let vars = List.mapi fn (List.sort_uniq compare (list_vars goal)) in
    let rec isomorphism expr =
        match expr with
          | True -> T
          | False -> F
          | Var a -> V (fst (List.find (fun v -> snd v = a) vars))
          | And (a, b) -> A (isomorphism a, isomorphism b)
          | Or (a, b) -> O (isomorphism a, isomorphism b)
          | Impl (a, b) -> I (isomorphism a, isomorphism b)
          | Eq (a, b) -> E (isomorphism a, isomorphism b)
          | Neg a -> N (isomorphism a)
          | _ -> failwith "error during parsing (fix the damn code already)"
    in (isomorphism goal, List.length vars)
