open Expr_ast
open Axioms
open List


let rec pmatch axiom vars =
    let f v = pmatch v vars in
    match axiom with
      | T -> True
      | F -> False
      | V a -> nth vars a
      | A (a, b) -> And (f a, f b)
      | O (a, b) -> Or (f a, f b)
      | I (a, b) -> Impl (f a, f b)
      | E (a, b) -> Eq (f a, f b)
      | N a -> Neg (f a)

let rec permute n lst =
        let aux a b = flatten (map a b) in
            if n <= 0
            then [[]]
            else aux 
                 (fun acc -> map (fun x -> x::acc) lst) 
                 (permute (n-1) lst)

let deduct_from_axioms axioms env = 
    let (axioms_no_val, lengths) = (split axioms) in
    flatten (map2 (fun a b -> map (fun v -> pmatch a v) (permute b env)) axioms_no_val lengths)


let rec inter l1 l2 =
    (* https://github.com/benjaminTaubenblatt/Ocaml-Intersection *)
    let rec contains i l =
        match l with
          | [] -> false
          | h::t -> if i = h then true else contains i t 
        in
            match l1 with
              | [] -> []
              | h::t -> if (contains h l2) then h::(inter t l2) else inter t l2


let deduct env =
    let box_filter v = match v with | Box  (_, _) -> true | _ -> false in
    let and_filter v = match v with | And  (_, _) -> true | _ -> false in
    let or_filter  v = match v with | Or   (_, _) -> true | _ -> false in
    let im_filter  v = match v with | Impl (_, _) -> true | _ -> false in
    let eq_filter  v = match v with | Eq   (_, _) -> true | _ -> false in


    let swap v = 
        match v with 
          | Or (a, b) -> [v; Or(b,a)] 
          | _ -> [] in

    let perm2_to_pair v = 
        match v with 
          | [a;b] -> (a,b) 
          | _ -> failwith "???" in

    let unwrap_or v = 
        match v with 
          | Or (a, b) -> (a, b) 
          | _ -> failwith "not or" in

    let unwrap_im v =
        match v with
          | Impl (a, b) -> (a, b)
          | _ -> failwith "not impl" in

    let eq_to_impl v = 
        match v with 
          | Eq (a, b) -> [Impl (a,b); Impl (b,a)] 
          | _ -> failwith "not eq" in

    let list_and v =
        match v with
          | And (a, b) -> [a;b]
          | _ -> failwith "not and" in


    let concatmap a b = flatten (map a b) in
    let sortmap a b = sort_uniq compare (concatmap a b) in
    let flat_uniq a = sort_uniq compare (flatten a) in

    let boxes = filter box_filter env in
    let and_lst = filter and_filter env in
    let or_lst = filter or_filter env in
    let swapped_ors = sortmap swap or_lst in
    let or_pairs = map unwrap_or swapped_ors in
    let box_perm = map perm2_to_pair (permute 2 boxes) in 
    let impl_lst = filter im_filter env in
    let eq_lst = filter eq_filter env in

    let implI_hlpr a = map (fun b -> Impl (assm a, b)) (cont_nobox a) in
    let negI_hlpr v = 
        if mem False (content v)
        then [Neg(assm v)]
        else [] in

    let andI =  concatmap (fun a -> map (fun b -> And (a, b)) env) env in 
    let implI = concatmap implI_hlpr boxes in 
    let negI =  concatmap negI_hlpr boxes in
    let eqI = concatmap (fun v -> 
        let (a,b) = unwrap_im v in
            if mem (Impl (b, a)) impl_lst
            then [Eq (a, b); Eq (b, a)]
            else [v]) impl_lst in

    let andE = concatmap list_and and_lst in

    let orE =
        let comp_fst a b = fst a = assm (fst b) in
        let comp_snd a b = snd a = assm (snd b) in
        let fn a = filter (fun b -> comp_fst a b && comp_snd a b) box_perm in
        let eligible_boxes = concatmap fn or_pairs in
            let lst1 v = cont_nobox (fst v) in
            let lst2 v = cont_nobox (snd v) in
              concatmap (fun v -> inter (lst1 v) (lst2 v)) eligible_boxes in

    let implE_hlpr v = 
        let (a,b) = unwrap_im v in
        if mem a env
        then b
        else v in

    let implE = map implE_hlpr impl_lst in
    let eqE = concatmap (fun v -> eq_to_impl v) eq_lst in
    let negE = map (fun v -> if mem (Neg(v)) env then False else v) env in

        flat_uniq [env; andI; implI; negI; eqI; andE; orE; implE; eqE; negE]
