# [Finding Steady States through Homotopy Continuation](@id homotopy_continuation)

The steady states of a dynamical system ${dx \over dt} = f(x)$ can be found by
solving $0 = f(x)$. This is typically a hard problem, and generally, there is no
method guaranteed to find all steady states for a system that has multiple ones.
However, many chemical reaction networks generate polynomial systems (for
example those which are purely mass action or have only have Hill functions with
integer Hill exponents). The roots of these can reliably be found through a
*homotopy continuation* algorithm. This is implemented in Julia through the
[HomotopyContinuation.jl](https://www.juliahomotopycontinuation.org/) package.

Catalyst contains a special homotopy continuation extension that is loaded whenever HomotopyContinuation.jl is. This exports a single function, `hc_steady_states`, that can be used to find the steady states of any `ReactionSystem` structure. If you use this in your research, please [cite the HomotopyContinuation.jl](@ref homotopy_continuation_citation) and [Catalyst.jl]() publications.

## Basic example
For this tutorial, we will use a model from Wilhem (2009)[^1] (which
demonstrates bistability in a small chemical reaction network). We declare the
model and the parameter set for which we want to find the steady states:
```@example hc1
using Catalyst
import HomotopyContinuation

wilhelm_2009_model = @reaction_network begin
    k1, Y --> 2X
    k2, 2X --> X + Y
    k3, X + Y --> Y
    k4, X --> 0
end
ps = [:k1 => 8.0, :k2 => 2.0, :k3 => 1.0, :k4 => 1.5]
nothing   # hide
```
Here, we only run `import HomotopyContinuation` as we do not require any of its functions, and just need it to be present in the current scope for the extension to be activated.

Now we can find the steady states using:
```@example hc1
hc_steady_states(wilhelm_2009_model, ps)
```
The order of the species in the output vectors are the same as in `species(wilhelm_2009_model)`.

It should be noted that the steady state multivariate polynomials produced by reaction systems may have both imaginary and negative roots, which are filtered away by `hc_steady_states`. If you want the negative roots, you can use the `hc_steady_states(wilhelm_2009_model, ps; filter_negative=false)` argument.


## Systems with conservation laws
Some systems are under-determined, and have an infinite number of possible steady states. These are typically systems containing a conservation
law, e.g.
```@example hc3
using Catalyst
import HomotopyContinuation

two_state_model = @reaction_network begin
    (k1,k2), X1 <--> X2
end
```
Catalyst allows the conservation laws of such systems to be computed using the `conservationlaws` function. By using these to reduce the dimensionality of the system, as well specifying the initial amount of each species, HomotopyContinuation can again be used to find steady states. To find the steady states using the Catalyst interface to HomotopyContinuation, an initial condition must be provided (which is used to compute the system's conserved quantities, in this case `X1+X2`):
```@example hc3
ps = [:k1 => 2.0, :k2 => 1.0]
u0 = [:X1 => 1.0, :X2 => 1.0]
hc_steady_states(wilhelm_2009_model, ps; u0)

```

## Final notes
- `hc_steady_states` supports any systems where all rates are systems of rational polynomials (such as Hill functions with integer Hill coefficients).
- When providing initial conditions to compute conservation laws, values are only required for those species that are part of conserved quantities. If this set of species is unknown, it is recommended to provide initial conditions for all species. 
- Additional arguments provided to `hc_steady_states` are automatically passed to HomotopyContinuation's `solve` command. Use e.g. `show_progress=false` to disable the progress bar.
---

## [Citation](@id homotopy_continuation_citation)
If you use this functionality in your research, please cite the following paper to support the authors of the HomotopyContinuation package:
```
@inproceedings{HomotopyContinuation.jl,
  title={{H}omotopy{C}ontinuation.jl: {A} {P}ackage for {H}omotopy {C}ontinuation in {J}ulia},
  author={Breiding, Paul and Timme, Sascha},
  booktitle={International Congress on Mathematical Software},
  pages={458--465},
  year={2018},
  organization={Springer}
}
```

## References
[^1]: [Thomas Wilhelm, *The smallest chemical reaction system with bistability*, BMC Systems Biology (2009).](https://bmcsystbiol.biomedcentral.com/articles/10.1186/1752-0509-3-90)
[^2]: [Paul Breiding, Sascha Timme, *HomotopyContinuation.jl: A Package for Homotopy Continuation in Julia*, International Congress on Mathematical Software (2018).](https://link.springer.com/chapter/10.1007/978-3-319-96418-8_54)
[^3:] [Andrew J Sommese, Charles W Wampler *The Numerical Solution of Systems of Polynomials Arising in Engineering and Science*, World Scientific (2005).](https://www.worldscientific.com/worldscibooks/10.1142/5763#t=aboutBook)
[^4:] [Daniel J. Bates, Paul Breiding, Tianran Chen, Jonathan D. Hauenstein, Anton Leykin, Frank Sottile, *Numerical Nonlinear Algebra*, arXiv (2023).](https://arxiv.org/abs/2302.08585)