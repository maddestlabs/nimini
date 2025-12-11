# Lambda Expressions in Nimini

## Overview

Nimini now has full support for lambda expressions (anonymous procedures), allowing you to create functions without names that can be assigned to variables, passed as arguments, and used inline. Lambda support includes full closure semantics, meaning lambdas can access variables from their enclosing scope.

## Basic Syntax

### Lambda Declaration

```nim
proc(parameters): body
```

### With Type Annotations

```nim
proc(param1: Type1, param2: Type2): returnType:
  # multi-line body
  statements...
```

### Inline Single Statement

```nim
proc(x: int, y: int): return x + y
```

## Features

### 1. Lambda Assignment

Lambdas can be assigned to variables:

```nim
var square = proc(x: int):
  return x * x

echo($square(5))  # Outputs: 25
```

### 2. Multi-Statement Bodies

Lambdas support full statement blocks:

```nim
var compute = proc(a: int, b: int):
  var sum = a + b
  var product = a * b
  echo("Sum: " & $sum)
  echo("Product: " & $product)
  return product

var result = compute(3, 4)
```

### 3. Lambdas as Arguments

Lambdas can be passed directly to functions:

```nim
proc runTwice(fn: int):
  fn()
  fn()

runTwice(proc():
  echo("Hello!")
)
```

Output:
```
Hello!
Hello!
```

### 4. Closures

Lambdas capture variables from their enclosing scope:

```nim
var name = "World"

var greet = proc():
  echo("Hello, " & name & "!")

greet()  # Outputs: Hello, World!
```

### 5. Conditional Logic

Lambdas can contain any valid Nimini statements:

```nim
var checkEven = proc(n: int):
  if n % 2 == 0:
    echo($n & " is even")
  else:
    echo($n & " is odd")

checkEven(4)  # Outputs: 4 is even
checkEven(7)  # Outputs: 7 is odd
```

### 6. Loops

Lambdas can use loops:

```nim
var countDown = proc(n: int):
  var i = n
  while i > 0:
    echo($i)
    i = i - 1
  echo("Blast off!")

countDown(3)
```

Output:
```
3
2
1
Blast off!
```

### 7. Return Values

Lambdas can return values:

```nim
var add = proc(a: int, b: int): return a + b
var multiply = proc(x: int, y: int): return x * y

var result = multiply(add(2, 3), add(4, 1))
echo($result)  # Outputs: 25
```

## Do Notation

Nimini supports "do notation" - a syntactic sugar for passing lambdas as the last argument to a function call.

### Syntax

```nim
functionName():
  # lambda body
```

This is equivalent to:

```nim
functionName(proc():
  # lambda body
)
```

### Example

```nim
proc withBlock(callback: int):
  echo("Before")
  callback()
  echo("After")

withBlock():
  echo("Inside the do block!")
```

Output:
```
Before
Inside the do block!
After
```

### Multi-Statement Do Blocks

Do blocks can contain multiple statements:

```nim
proc withContext(callback: int):
  echo("--- Begin Context ---")
  callback()
  echo("--- End Context ---")

withContext():
  echo("Statement 1")
  echo("Statement 2")
  echo("Statement 3")
```

## Implementation Details

### AST Representation

Lambdas are represented as `ekLambda` expression nodes with:
- `lambdaParams`: sequence of parameter definitions (name, type, var modifier)
- `lambdaBody`: sequence of statements forming the body
- `lambdaReturnType`: optional return type annotation

### Runtime Behavior

1. When a lambda expression is evaluated, it creates a `FunctionVal` object
2. The function value stores the parameter names and body statements
3. When called, a new environment is created with the parameters bound
4. The body statements are executed in this environment
5. Return values are propagated back to the caller
6. Closures work through the environment chain

### Code Generation

Lambdas are translated to the target language's lambda syntax:

**Nim:**
```nim
proc(x: int, y: int) =
  return x + y
```

**JavaScript:**
```javascript
(x, y) => {
  return x + y;
}
```

**Python:**
```python
lambda x, y: x + y  # For single expressions
# Multi-line requires function definition
```

## Limitations

1. Parameter types must be explicitly declared (no type inference yet)
2. No support for generic lambda parameters
3. No support for default parameter values in lambdas
4. Python backend has limited support for multi-statement lambdas

## Examples

See the comprehensive test suite in `test_lambda_comprehensive.nim` for 10 complete examples demonstrating all lambda features.

## Future Enhancements

Potential improvements for lambda support:
- Type inference for lambda parameters
- Generic lambda parameters
- Default parameter values
- Lambda type annotations (`var fn: proc(int, int): int`)
- Better Python multi-line lambda generation
- Lambda expression return type inference
