type t =
    | True
    | False
    | Var of string
    | And of t * t
    | Or of t * t
    | Impl of t * t
    | Eq of t * t
    | Neg of t
    | Box of t * (t list)

let assm = 
    function
      | (Box (a, b)) -> a
      | _ -> failwith "not a box"

let content = 
    function
      | (Box (a, b)) -> b
      | _ -> failwith "not a box"

let in_box elem box =
    match box with
      | Box (a, b) -> List.mem elem b
      | _ -> failwith "not a box"

let cont_nobox a =
    let fn = (fun v -> match v with | Box (_, _) -> false | _ -> true) in
    List.filter fn (content a)

let rec map f l =
    match l with
      | [] -> []
      | x :: xs -> f x :: map f xs


let rec print_list l =
    match l with
      | [] -> "empty"
      | x :: [] -> x
      | x1 :: x2 :: [] -> x1 ^ "; " ^ x2
      | x :: xs -> x ^ "; " ^ print_list xs


let rec print_body =
    function
      | True -> "True"
      | False -> "False"
      | Var a -> a
      | And (a, b) -> "(" ^ (print_body a) ^ " /\\ " ^ (print_body b) ^ ")"
      | Or (a, b) -> "(" ^ (print_body a) ^ " \\/ " ^ (print_body b) ^ ")"
      | Impl (a, b) -> "(" ^ (print_body a) ^ " => " ^ (print_body b) ^ ")"
      | Eq (a, b) -> "(" ^ (print_body a) ^ " <=> " ^ (print_body b) ^ ")"
      | Neg a -> "~" ^ (print_body a)
      | Box (a, b) -> "[" ^ (print_body a) ^ ": " ^ 
              (print_list (List.map (fun v -> print_body v) b)) ^ "]"


let rec parse_and_print_msg outc ((id, body), proof, axiom) =
    let proof_value =
        if axiom
        then ", proof: n/a (axiom)"
        else ", proof: " ^ print_list (map (fun v -> print_body v) proof) in
    let res = "id: " ^ id ^ ", body: " ^ print_body body ^ proof_value 
    in
        Core.Out_channel.output_string outc res

