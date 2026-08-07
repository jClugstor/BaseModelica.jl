# BaseModelica.jl

[![Join the chat at https://julialang.zulipchat.com #sciml-bridged](https://img.shields.io/static/v1?label=Zulip&message=chat&color=9558b2&labelColor=389826)](https://julialang.zulipchat.com/#narrow/stream/279055-sciml-bridged)
[![Global Docs](https://img.shields.io/badge/docs-SciML-blue.svg)](https://docs.sciml.ai/BaseModelica/stable/)

[![codecov](https://codecov.io/gh/SciML/BaseModelica.jl/branch/main/graph/badge.svg)](https://app.codecov.io/gh/SciML/BaseModelica.jl)
[![Build Status](https://github.com/SciML/BaseModelica.jl/workflows/CI/badge.svg)](https://github.com/SciML/BaseModelica.jl/actions?query=workflow%3ACI)

[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor%27s%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

A parser for the [Base Modelica](https://github.com/modelica/ModelicaSpecification/tree/MCP/0031/RationaleMCP/0031) format. Contains utilities to parse Base Modelica model files into Julia objects, and to convert Base Modelica models to [ModelingToolkit](https://docs.sciml.ai/ModelingToolkit/stable/) systems ready for simulation.

Base Modelica is still a proposal (MCP-0031) without a finalized specification, so the grammar and features of the language are subject to change.

## Features

### Parsing backends

Two parser backends are available:

  - `:antlr` (default): uses the official Base Modelica ANTLR grammar via a bundled Python parser. The Python dependencies are managed automatically through CondaPkg, so no manual setup is required.
  - `:julia`: a pure-Julia parser built on ParserCombinator.jl.

Select a backend with the `parser` keyword argument, e.g. `parse_basemodelica("model.bmo", parser = :julia)`.

### Supported language features

  - `Real`, `Integer`, `Boolean`, and `String` parameters and variables
  - Equations with first-order derivatives (`der`), initial equations, and declaration equations
  - Parameter and variable modifiers such as `start`, `fixed`, `min`, `max`, and `unit`. Start values with `fixed = true` become initial conditions, `fixed = false` becomes guesses, and free parameters (`fixed = false`) are solved during initialization
  - If-equations and inline if-expressions, including `elseif` chains, nesting, and Boolean variable conditions
  - When-equations, translated to ModelingToolkit continuous and discrete events, including discrete variables
  - Boolean expressions and relational operators
  - Built-in Modelica functions:
      + Elementary math: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `sinh`, `cosh`, `tanh`, `exp`, `log`, `log10`
      + Numeric: `abs`, `sign`, `sqrt`, `min`, `max`
      + Event-triggering: `div`, `mod`, `rem`, `ceil`, `floor`, `integer`
      + Special operators: `semiLinear`, `homotopy`
      + Event-related: `noEvent`, `smooth`
      + `assert` and `terminate` (assert statements are parsed and skipped during translation)
  - `annotation(experiment(...))` blocks for automatic simulation setup (see below)

This is sufficient to import nontrivial models — the test suite includes Base Modelica flattenings of Modelica Standard Library examples such as the Cauer low-pass filters, the Chua circuit, ideal diode circuits, op-amp circuits, and a triac circuit.

### Not yet supported

Records, custom types, custom functions, arrays and array indexing, and functions with tuple returns are not yet supported.

## Installation

Assuming that you already have Julia correctly installed, it suffices to import
BaseModelica.jl in the standard way:

```julia
import Pkg;
Pkg.add("BaseModelica");
```

## Example

Suppose the file `ExampleFirstOrder.bmo` contains a Base Modelica model specifying a simple first-order linear differential equation:

```
package 'FirstOrder'
  model 'FirstOrder'
    parameter Real 'x0' = 0 "Initial value for 'x'";
    Real 'x' "Real variable called 'x'";
  initial equation
    'x' = 'x0' "Set initial value of 'x' to 'x0'";
  equation
    der('x') = 1.0 - 'x';
  end 'FirstOrder';
end 'FirstOrder';
```

To parse the model into a compiled ModelingToolkit `System`, use the `parse_basemodelica` function:

```julia
using BaseModelica

sys = parse_basemodelica("path/to/ExampleFirstOrder.bmo")
```

To go straight to an `ODEProblem` ready for simulation, use `create_odeproblem`:

```julia
using BaseModelica, OrdinaryDiffEq

prob = create_odeproblem("path/to/ExampleFirstOrder.bmo")

sol = solve(prob)
```

### Experiment annotations

If the model contains an experiment annotation like:

```modelica
annotation(experiment(StartTime = 0, StopTime = 2.0, Tolerance = 1e-06, Interval = 0.004))
```

then `create_odeproblem` automatically sets the time span from `StartTime`/`StopTime`, `reltol` from `Tolerance`, and `saveat` from `Interval`. Keyword arguments passed to `create_odeproblem` override the annotation values:

```julia
prob = create_odeproblem("path/to/model.bmo", reltol = 1e-8, saveat = 0.01)
```
