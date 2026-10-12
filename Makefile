.PHONY: build out run

build:
	cmake -S . -B build/

out: build
	cmake --build ./build/

asm: out
	./build/hydro ./test.hy

run: asm
	./out; echo "exit code: $$?"

