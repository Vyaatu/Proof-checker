
Proof-checker
=============

A purely functional natural deduction proof checker and parser for propositional logic

- [INSTALLATION](#installation)
- [DEPENDENCIES](#dependencies)
- [OPTIONS](#options)
- [SYNTAX](#syntax)
- [DEVELOPER INFO](#developer-info)
- [A NOTE ON ISOMORPHISMS](#a-note-on-isomorphisms)
- [EDGE CASES](#edge-cases)
- [EXAMPLES OF INFERRENCE RULES AND TESTS](#examples-of-inferrence-rules-and-tests)
- [ADDITIONAL INFO](#additional-info)

INSTALLATION
------------

Simply follow the `makefile`.

Compile and run tests from `test.txt`:
```
$ make all
```

Compile:
```
$ make compile
```

Run tests from `test.txt`:
```
$ make test
```

Delete the compiled program:
```
$ make clean
```

DEPENDENCIES
------------

The only dependency is the Core library, which can be installed via OPAM by running:
```
$ opam install core
```

OPTIONS
-------

The `main.ml` file takes one argument, which is the name of the input file. It can also accept an optional flag, namely `-print`, which prints out parsed input and stops.

The program prints all the information to stdout and stderr, meaning it can be intercepted and written to files.

For user convenience, run_test.sh simplifies that process, by accepting up to two optional arguments:  
1. Input file's name (default: `test.txt`)  
2. Output file's name (default: `stdout.txt`)

Sample usage:
```
$ ./test.sh input output 
```
(reads input from input and sends it to output)

```
$ ./test.sh test_file
```
(reads input from test_file and sends it to `stdout.txt`)

```
$ ./test.sh
```
(reads input from test.txt and sends it to `stdout.txt`)

SYNTAX
------
    
Axioms are declared as following:
```
axiom ID: BODY;
```

Proofs are defined similarly:
```
goal ID: BODY
proof
    PROOF_LIST
end.
```

`ID`s begin with a small letter, followed by an arbitrary amount of capital letters, underscores and numbers.

`BODY` is an expression that consists of parentheses, atoms (single capital letters, with `T` and `F` reserved for True and False, respectively), binary operators: `/\` (and), `\/` (or), `=>` (implication), `<=>` (equality), and unary operators: `~` (not).

`PROOF_LIST` is a list of `BODIES`, separated with semicolons, with the last expression not requiring a semicolon. In addition to `BODY` expressions, a `PROOF_LIST` can also contain `BOXES`.

`BOXES` are created as following:
```
[ BODY : PROOF_LIST ]
```

Examples can be found in `test.txt` (provided with the project).

DEVELOPER INFO
------------------------------

`expr_ast.ml`, `axioms.ml`  
Definitions of abstract types used throughout the program, along with some basic operations, such as printing and converting from `Expr_ast.t` to `Axioms.axiom`.


`lexer.mll`, `parser.mly`  
These files are responsible for the lexing and parsing processess.


`main.ml`  
The `main` function accepts an argument that specifies input's filename, and an optional `-print` flag, then invokes `Parser_build.parse_and_evaluate`.


`parser_build.ml`  
The file contains useful functions utilizing `lexer.mll` and `parser.mly`, as well as a function called `parse_and_evaluate`, which either prints out the parsed input and stops, or passes it to `Wrapper.run`.


`wrapper.ml`  
This file handles an incoming list of proofs and evaluates them. If a proof happens to be correct, the wrapper function assumes it as an axiom for possible future use. The correctness is checked by `Checker.check_proof`. When the evaluation is complete, the output is printed to stdout.


`checker.ml`  
The check_proof function accepts a single proof, validates it through `eval` function and prints an appropriate message about the proof's correctness. `eval` takes a proof and iterates through all of its components, making sure that all of them can be logically inferred by using `Infer.can_derive`.


`infer.ml`  
The file contains only one function - `can_derive`. It accepts an expression, its environment (that was already checked to be correct), and a list of axioms. If, according to `Deduction_rules.deduct_from_axioms`, an expression is isomorphic to one of the axioms (see: [a note on isomporphisms](#a-note-on-isomorphisms)), or if the expression can be derived from the environment by using `Deduction_rules.deduct`, the search is finished. If none of the above techniques work, a contingency plan takes place. Each of the items from `Deduction_rules.deduct` is added sequentially to the environment in attempt to fill in parts of proof the user might have forgotten to add (see: [edge cases](#edge-cases)). If it works, a warning is issued and the user is encouraged to rethink his/her awful behaviour, while the proof checking continues. If none of the above works, the proof is deemed invalid, and the expression that could not be inferred is printed out in an error message.  

Note that this function handles the orI rule separately from `Deduction_rules` by unwrapping Or (a, b) into a pair (a, b) and trying to derive either a or b, whilst suppressing error messages. If it succeeds, the proof continues. If it fails, the program goes on and tries to infer the whole Or. The orI rule is separated from `Deduction_rules.deduct`, because the function can only infer expressions from an already proven environment, thus it is unable to create `A \/ B` if `A` has been proven and `B` did not exist up until that point of the proof.


`deduction_rules.ml`  
`deduct_from_axioms` iterates over a list of axioms and creates all the possible expressions that can be derived from them using the environment. The deduct function uses rules of natural deduction, such as conjunction elimination or implication introduction, and creates all the possible expressions that can be inferred from the current environment.

A NOTE ON ISOMORPHISMS
----------------------

The isomorphism of axioms can be a little tricky: they are unique up to atomic expressions. This means that `P \/ Q` is **NOT** isomorphic to `(A => B) \/ (C => D)`, although the program will try to insert valid expressions in place of atoms as the last resort.
Consider the following example:

```
axiom doubleNeg: ~~A => A;
axiom exclMiddleHelper: ~~(A \/ ~A) => (A \/ ~A);

goal exclMiddle: P \/ ~P
proof
  [ ~(P \/ ~P) :
    [ P :
      P \/ ~P;
      F ];
    ~P;
    P \/ ~P;
    F ];
  ~~(P \/ ~P);
  ~~(P \/ ~P) => (P \/ ~P);
  P \/ ~P;
end.
```

Even though `doubleNeg` has been assumed as an axiom, it is not enough to satisfy the `exclMiddle`'s penultimate statement. The program tries to match `A` from `~~A => A` with expressions already known to be true. There is only one such expression, namely `~~(P \/ ~P)`. However, `~~(~~(P \/ ~P)) => ~~(P \/ ~P)` does not quite solve the problem. This is why `exclMiddleHelper` has been introduced - it is perfectly isomorphic to `~~(P \/ ~P) => (P \/ ~P)`, and thus requires no further proof. This lets us conclude the `exclMiddle`'s goal.

It should also be noted that in an expression such as `P => Q`, both `P` and `Q` are assumed to be **NOT EQUAL**, thus an axiom `P => Q` is isomorphic to `A => B`, but not to `P => P`.

EDGE CASES
----------

Even though the program tries its best to fill in parts of the proof that the user might have omitted, it cannot fix everything. 
Consider the following example:

```
goal modusPonens: A /\ (A => B) => B
proof
  [ A /\ (A => B) :
    A;
    A => B;
    B ];
  A /\ (A => B) => B
end.
```

If we were to remove `A => B` from the proof, it would easily be detected by the program, and a warning would be issued. However, removing `B` would render the proof invalid, because the implI rule would not hold anymore - if by assuming `P` in a box we can conclude `Q`, then `P => Q` holds. However, our box does not contain `B`, thus making the last line incorrect.

EXAMPLES OF INFERRENCE RULES AND TESTS
------------------------------------

Examples of inferrence rules that can be found in `test.txt`:

```
orI   ->  exclMiddle                (line 9)
andI  ->  andIntrTest               (line 95)
implI ->  hypotheticalSyllogism     (line 32)
negI  ->  exclMiddle                (line 11)
eqI   ->  eqIntrTest                (line 80)

orE   ->  claviusLaw                (line 71)
andE  ->  modusPonens               (line 47)
implE ->  modusPonens               (line 48)
negE  ->  exclMiddle                (line 10)
eqE   ->  eqElimTest                (line 86)
```

ADDITIONAL INFO
---------------

The project was tested on macOS 10.13.2 High Sierra  
OCaml compiler: `v4.05.0`  
Core library: `v0.9.1 [4.05.0]`
