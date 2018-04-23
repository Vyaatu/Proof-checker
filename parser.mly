%{
open Expr_ast
%}

%token AXIOM

%token GOAL
%token <string> GOAL_ID
%token PROOF
%token END

%token TRUE FALSE
%token NEG
%token AND OR IMPL EQ
%token <string> VAR

%left EQ
%right IMPL
%left OR
%left AND

%token SEMICOLON
(* ; *)
%token COLON
(* : *)

%token LPAREN_SQ RPAREN_SQ
%token LPAREN RPAREN

%token EOF

%start < ((string * Expr_ast.t) * (Expr_ast.t list) * bool) list > prog
%%

prog:
  | EOF { [] }
  | AXIOM; id = GOAL_ID; COLON; body = goal_body; SEMICOLON; rest = prog 
    { ((id, body), [], true) :: rest }  
  | GOAL; id = GOAL_ID; COLON; body = goal_body;
    PROOF; p = proof; END; rest = prog
    { ((id, body), p, false) :: rest }
  ;

goal_body:
  | LPAREN; x = goal_body; RPAREN { x }
  | a = uop { a }
  | a = binop { a }
  | a = atom { a }
  ;

atom:
  | a = VAR { (Var a) }
  | TRUE { True }
  | FALSE { False }
  ;

uop:
  | NEG; LPAREN; x = goal_body; RPAREN { (Neg x) }
  | NEG; a = uop { Neg a }
  | NEG; a = atom { Neg a }
  ;

binop:
  | a = goal_body; AND; b = goal_body { (And (a, b)) }
  | a = goal_body; OR; b = goal_body { (Or (a, b)) }
  | a = goal_body; IMPL; b = goal_body { (Impl (a, b)) }
  | a = goal_body; EQ; b = goal_body { (Eq (a, b)) }
  ;

proof:
  | LPAREN_SQ; a = goal_body; COLON; b = prooflst; RPAREN_SQ; SEMICOLON; 
    r = proof { Box (a, b) :: r }
  | a = goal_body; SEMICOLON; r = proof { a :: r }
  | a = goal_body; { [a] }
  | (* empty *) { [] }
  ;

prooflst:
  | LPAREN_SQ; a = goal_body; COLON; b = prooflst; RPAREN_SQ; SEMICOLON; 
    r = prooflst { Box (a, b) :: r }
  | a = goal_body; SEMICOLON; b = prooflst { a :: b }
  | a = goal_body; { [a] }
  ;