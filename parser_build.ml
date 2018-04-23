open Core
open Lexer
open Lexing
open Expr_ast

let print_position outx lexbuf =
    let pos = lexbuf.lex_curr_p in
    fprintf outx "%s:%d:%d" pos.pos_fname
        pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let parse_with_error lexbuf =
    try 
        Parser.prog Lexer.read lexbuf 
    with
        | SyntaxError msg ->
            fprintf stderr "%a: %s\n" print_position lexbuf msg;
            []
        | Parser.Error ->
            fprintf stderr "%a: syntax error\n" print_position lexbuf;
            exit (-1)

let rec parse_and_print lexbuf =
    match parse_with_error lexbuf with
      | (x :: xs) as lst ->
        let rec print_list l =
            match l with
              | [] -> printf "\n"
              | x :: xs -> 
                printf "%a\n" parse_and_print_msg x;
                print_list xs 
        in print_list lst; parse_and_print lexbuf
      | [] -> ()

let parse_and_evaluate p filename () =
    let inx = In_channel.create filename in
    let lexbuf = Lexing.from_channel inx in
    lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };

    if p
    then parse_and_print lexbuf
    else Wrapper.run (parse_with_error lexbuf)
    ;
    
    In_channel.close inx
