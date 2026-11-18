# Compiler

A small compiler for a toy programming language, written in C++20.
It turns source into x86-64 NASM assembly, then assembles and links it into a native Linux executable.

```
source.hy ──► Tokenizer ──► Parser (AST) ──► Generator ──► out.asm ──► nasm ──► ld ──► ./out
```

## Language at a glance

```
// single-line comments
/* and multi-line comments */

let x = 7;            // declare a variable
x = (x + 3) * 2 / 4;  // reassign it

if (0) {
  x = 1;
} elif (x - 5) {
  x = 2;
} else {
  x = 3;
}

{
  let y = 10;         // scoped: y is freed at the end of the block
}

exit(x);              // exit the program with x as the exit code
```

Supported right now:

| Feature             | Syntax                                     |
| ------------------- | ------------------------------------------ |
| Integer literals    | `42`                                       |
| Variables           | `let name = expr;`                         |
| Reassignment        | `name = expr;`                             |
| Arithmetic          | `+`, `-`, `*`, `/` with the usual precedence |
| Grouping            | `( expr )`                                 |
| Scopes              | `{ ... }`                                  |
| Conditionals        | `if (expr) { } elif (expr) { } else { }` (non-zero is true) |
| Exit                | `exit(expr);`                              |
| Comments            | `// ...` and `/* ... */`                   |

The full grammar is in [`docs/grammar.md`](docs/grammar.md). Reading material that shaped the parser is in [`docs/resources.md`](docs/resources.md).

## Building

### Requirements

- A C++20 compiler (GCC or Clang)
- CMake ≥ 3.20 and Make
- [NASM](https://www.nasm.us/) and GNU `ld` (binutils)
- Linux on x86-64 (the output uses Linux syscalls directly)

With Nix, `nix develop` drops you into a shell that has all of these.

### Make targets

```sh
make build   # configure CMake into ./build
make out     # build the compiler -> ./build/hydro
make asm     # compile ./test.hy -> out.asm, out.o, out
make run     # do all of the above, run ./out and print its exit code
```

### Using the compiler directly

```sh
./build/hydro path/to/program.hy
./out
echo $?   # the value passed to exit()
```

`hydro` always writes `out.asm`, `out.o` and `out` into the current directory.

## Project layout

```
src/
  main.cpp           entry point: reads the file, runs each stage, calls nasm + ld
  tokenization.hpp   Tokenizer: source text -> tokens (with line numbers)
  parser.hpp         AST node types + recursive-descent parser
                     (precedence climbing for binary expressions)
  generation.hpp     Generator: AST -> x86-64 NASM assembly (stack-based)
  arena.hpp          bump/arena allocator used for AST nodes
docs/
  grammar.md         language grammar
  resources.md       references (precedence climbing, dangling else)
test.hy              sample program used by `make run` and CI
```

### How code generation works

The generator uses the stack for everything. Each expression pushes its result. Variables are stack slots, found by their offset from `rsp`. A scope records how many variables existed when it opened and pops the extra ones when it closes. `if`/`elif`/`else` turn into `test` plus `jz`/`jmp` to generated `labelN` labels. The program ends with an `exit` syscall (`rax = 60`).

## CI

There are GitHub Actions (`.github/workflows/ci.yml`) and GitLab CI (`.gitlab-ci.yml`) pipelines. Both build the compiler and compile `test.hy`. Neither checks the program's exit code yet (see TODO).

## TODO

### Error reporting
- [ ] "Invalid token" should show the line number and the bad character.
- [ ] "Undeclared identifier" / "Identifier already used" should show the line number. The token already stores it.
- [ ] Better usage message in `main.cpp` (the current one ends with "Correct usage is...").

### Language features
- [ ] Comparison operators `<`, `<=`, `>`, `>=`, `==`, `!=`. They're in `docs/grammar.md` but not in the tokenizer, parser or generator yet.
- [ ] Logical operators `&&`, `||`, `!`.
- [ ] Unary minus / negative literals (`-5`, `-x`).
- [ ] Modulo `%`.
- [ ] Loops (`while`, maybe `for`) plus `break` / `continue`.
- [ ] Functions: definitions, calls, arguments, `return`.
- [ ] Printing output (e.g. a `print` built-in using the `write` syscall).
- [ ] Types beyond 64-bit ints (bool, char, strings).

### Tooling & quality
- [ ] Command-line flags: output file name (`-o`), keep/emit only assembly (`-S`).
- [ ] Write build artifacts somewhere other than the current directory.
- [ ] Test suite: a `tests/` folder of `.hy` files, each with its expected exit code, plus a script that runs them all. Have CI fail when a code doesn't match. Right now CI always passes.
- [ ] Make `docs/grammar.md` match the code (the precedence numbers differ: the grammar says `*`/`/` = 3 and `+`/`-` = 2, but `bin_prec` uses 1 and 0).
- [ ] Add `asm` to `.PHONY` in the Makefile. Consider renaming the `build` target to `configure`.
- [ ] Optimizations: skip redundant `push`/`pop` pairs and fold constants.

### Known Bugs (will do it at some point)
- [ ] `if (...) {} elif (...) {}` with **no trailing `else`** emits a `jz labelN` whose label is never defined, so NASM fails. In `gen_if_pred`, emit `label:` even when `elif->pred` is empty.
- [ ] Multi-line `/* */` comments don't advance `line_count`, so errors after them report the wrong line.
- [ ] `hydro` exits with 0 even when `nasm`/`ld` fail. Check the return values of `system()`.
- [ ] No error if the input file can't be opened (it compiles an empty program instead).
- [ ] `error_expected` calls `peek(-1).value()`. If an error happens on the very first token, that's an empty optional, and the compiler crashes instead of printing an error.
- [ ] `tokenization.hpp` uses `assert`, `std::optional` and `std::cerr` without including `<cassert>`, `<optional>` or `<iostream>`. It only builds thanks to include order.
