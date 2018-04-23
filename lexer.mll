{
open Lexing
open Parser

exception SyntaxError of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { pos with pos_bol = lexbuf.lex_curr_pos;
               pos_lnum = pos.pos_lnum + 1
    }
}

let id = ['a'-'z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*

let var = ['A'-'Z']

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"


rule read =
  parse
  | white { read lexbuf }
  | newline  { next_line lexbuf; read lexbuf }
  | "axiom" { AXIOM }
  | "goal" { GOAL }
  | "proof" { PROOF }
  | "end." { END }
  | '(' { LPAREN }
  | ')' { RPAREN }
  | id { GOAL_ID (Lexing.lexeme lexbuf) }
  | ':' { COLON }
  | 'T' { TRUE }
  | 'F' { FALSE }
  | var { VAR (Lexing.lexeme lexbuf) }
  | '~' { NEG }
  | "/\\" { AND }
  | "\\/" { OR } 
  | "<=>" { EQ }
  | "=>" { IMPL }
  | ';' { SEMICOLON }
  | '[' { LPAREN_SQ }
  | ']' { RPAREN_SQ }
  | eof { EOF }