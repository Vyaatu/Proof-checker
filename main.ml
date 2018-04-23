open Core

let () =
    Command.basic 
        ~summary:"Natural deduction proof checker"
        Command.Spec.(
            empty
            +> flag "-print" no_arg ~doc: "print parsed output and halt"
            +> anon ("filename" %: file)
        )
        Parser_build.parse_and_evaluate
        |> Command.run