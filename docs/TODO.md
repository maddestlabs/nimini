# Nimini Language Features TODO

## Recommended Implementation Order

1. **Case statements** - High utility, moderate complexity
2. **Break/continue** - Essential loop control, easy to add
3. **Tuples** - Very useful, moderate complexity
4. **Exception handling** (basic) - Important for robust scripts
5. **Enums** - Great for DSLs, moderate complexity
6. **String slicing** - High utility, low complexity
7. **Object types** (simple) - Enables structured data
8. **Sets** - Useful for collections
9. **Templates** (basic) - Aligns with your codegen goals
10. **More operators** - Incremental additions

---

## Currently Supported in Nimini ✅

- **Basic types**: int, float, string, bool, arrays, maps
- **Variables**: `var`, `let`, `const`
- **Operators**: arithmetic (`+`, `-`, `*`, `/`, `%`), comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`), logical (`and`, `or`, `not`), string concatenation (`&`)
- **Control flow**: `if`/`elif`/`else`, `case`/`of`/`elif`/`else`, `while`, `for`
- **Functions**: `proc` definitions, calls, return statements
- **Type annotations**: Basic type system with `TypeNode`
- **Pointers**: `ptr`, `addr`, dereference (`[]`)
- **Type casting**: `cast[Type](expr)`
- **Blocks**: `block` and `defer` statements
- **Arrays**: Indexing, literals
- **Range operators**: `..` and `..<`

---

## Nim Features to Add (Scripting-Relevant) 🎯

### High Priority

1. ~~**Case/Switch statements**~~ ✅ **COMPLETED** (Nim manual section on control flow)
   - ~~Case statement with of branches~~
   - ~~Multiple values per branch: `of 1, 2, 3:`~~
   - ~~Optional elif branches~~
   - ~~Optional else branch~~
   - Supports integers, floats, strings (ordinal types and strings per Nim manual)

2. **Break/continue** statements
   - `break` to exit loops early
   - `continue` to skip to next iteration
   - Loop labels for nested loops

3. **Tuples** (Nim manual section on structured types)
   - Tuple literals: `(1, "hello", true)`
   - Tuple unpacking: `let (x, y) = getTuple()`
   - Named tuples: `(name: "Bob", age: 30)`

2. **Object types** (Nim manual structured types)
   - Object definitions with fields
   - Field access: `obj.fieldName`
   - Object construction
   - *Skip*: Inheritance (too complex for scripting)

3. **Enums** (Nim manual ordinal types)
   - Enum definitions: `type Color = enum red, green, blue`
   - Enum values and comparisons
   - Useful for DSLs and configuration

4. **String operations** (from stdlib)
   - String slicing: `str[1..5]`
   - String formatting
   - Common string methods

5. **More loop constructs**
   - `break` and `continue` statements
   - Loop labels for nested loops
   - `for` with multiple variables: `for i, item in pairs(arr)`

6. **Case/Switch statements** (Nim manual control flow)
   ```nim
   case value
   of 1: echo "one"
   of 2, 3: echo "two or three"
   else: echo "other"
   ```

7. **Exception handling** (basic)
   - `try`/`except`/`finally` blocks
   - `raise` statements
   - Basic exception types
   - *Skip*: Custom exception hierarchies (too complex)

8. **Distinct types** (lightweight, useful for scripting)
   - `type UserId = distinct int`
   - Type safety without overhead

### Medium Priority

9. **Iterators** (basic form)
   - Simple `iterator` definitions
   - `yield` statements
   - Inline iterators only (closure iterators explicitly restricted per manual)

10. **Templates** (compile-time code generation)
    - Basic template definitions
    - Simple code substitution
    - Useful for DSL creation

11. **Subrange types** (Nim manual section 3.2)
    - `type Subrange = range[0..5]`
    - Runtime bounds checking

12. **Set types**
    - Set literals: `{1, 2, 3}`
    - Set operations: `in`, `+`, `-`, `*`
    - Useful for bit flags and collections

13. **Sequence operations**
    - More seq operations: `add`, `delete`, `insert`
    - Sequence slicing
    - Already have `seqops` in stdlib folder

14. **Dot operators** (method call syntax)
    - Uniform function call syntax: `obj.method(arg)` as `method(obj, arg)`
    - Makes APIs more ergonomic

15. **Multiple assignment**
    - `var a, b, c = getValue()`
    - Tuple unpacking in assignments

### Lower Priority

16. **Generics** (basic form only)
    - Generic type parameters for functions/types
    - Simple `[T]` syntax
    - *Skip*: Advanced constraints, concepts

17. **Converters** (implicit type conversion)
    - `converter` definitions for automatic conversions
    - Useful for DSLs

18. **Type aliases**
    - `type MyInt = int`
    - Simple type renaming

19. **Static blocks**
    - `static:` for compile-time execution
    - Already have some compile-time support

20. **More operators**
    - Bitwise: `shl`, `shr`, `and`, `or`, `xor`, `not`
    - Already mentioned in manual as keywords

---

## Nim Features to SKIP (Compiler-Focused) ❌

### Definitely Skip

1. **FFI** (Foreign Function Interface) - Explicitly restricted in manual for compile-time
2. **Methods** (dynamic dispatch) - Manual states not available at compile-time
3. **Closure iterators** - Explicitly restricted
4. **ref/ptr distinction** - Too low-level for scripting
5. **Memory management details** - GC, destructors, moves (manual's destructors document)
6. **Macro system** - Too complex, compiler-dependent
7. **Pragmas** (except maybe `{.nimini.}` for your autopragma feature)
8. **Module system** - Complex imports/exports
9. **Effect system** - `{.raises.}`, `{.tags.}`, etc.
10. **Compile-time flags** - `when defined()`, conditional compilation
11. **AST manipulation** - `quote`, `getAst`, etc.
12. **Advanced type features**: Concepts, type classes, formal type parameters
13. **Overflow checking modes** - Implementation detail
14. **Thread-local storage** - Threading too complex
15. **Async/await** - Too complex for basic scripting

### Maybe Later (Complex but Potentially Useful)

- **Pattern matching** - Powerful but complex
- **Interfaces/protocols** - If you add object types
- **Operator overloading** - Could be useful for DSLs
- **Properties** - `get`/`set` accessors

---

## Summary

Focus on features that enhance **scripting expressiveness** while avoiding **compiler infrastructure** concerns. Nimini should prioritize:

- **Data structures** (tuples, objects, enums, sets)
- **Control flow enhancements** (case, break/continue, exceptions)
- **String/sequence operations**
- **Simple metaprogramming** (templates)

Skip anything requiring:
- Deep compiler knowledge
- Runtime system changes
- Features that conflict with the "lightweight embeddable" philosophy

The goal is to maintain Nimini's core strengths (zero dependencies, simple API, embeddable) while expanding its expressiveness for scripting use cases.
