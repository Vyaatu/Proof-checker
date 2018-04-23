all:
	make compile
	make run

compile:
	ocamlbuild -use-menhir -r -tag thread -use-ocamlfind -pkg core main.native

run:
	./run_test.sh

clean:
	rm -f main.native result.txt
	rm -rf _build