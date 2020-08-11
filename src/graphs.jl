# adapted from Petri.jl
# https://github.com/mehalter/Petri.jl

graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

function edgify(δ, i, reverse::Bool)
    attr = Attributes()
    return map(δ) do p
        val = String(p[1].op.name)
      weight = "$(p[2])"
      attr = Attributes(:label=>weight, :labelfontsize=>"6")
      return Edge(reverse ? ["rx_$i", "$val"] :
                            ["$val", "rx_$i"], attr)
    end
end

# make distinguished edge based on rate constant
function edgifyrates(rxs, specs)    
    es = Edge[]
    for (i,rx) in enumerate(rxs)
        deps = rx.rate isa Operation ? get_variables(rx.rate, specs) : Operation[]        
        for dep in deps
            val = String(dep.op.name)
            attr = Attributes(:color => "#d91111", :style => "dashed")
            e = Edge(["$val", "rx_$i"], attr)
            push!(es, e)
        end
    end
    es
end

"""
    Graph(rn::ReactionSystem)

Converts a [`ReactionSystem`](@ref) into a
[Catlab.jl](https://github.com/AlgebraicJulia/Catlab.jl/) Graphviz graph.
Reactions correspond to small green circles, and species to blue circles. 

Notes:
- Black arrows from species to reactions indicate reactants, and are labelled
  with their input stoichiometry. 
- Black arrows from reactions to species indicate products, and are labelled
  with their output stoichiometry. 
- Red arrows from species to reactions indicate that species is used within the
  rate expression. For example in the reaction `k*A, B --> C`, there would be a
  red arrow from `A` to the reaction node. In `k*A, A+B --> C` there would be
  red and black arrows from `A` to the reaction node.
"""
function Graph(rn::ReactionSystem)
    rxs   = reactions(rn)
    specs = species(rn)
    statenodes = [Node(string(s.name), Attributes(:shape=>"circle", :color=>"#6C9AC3")) for s in specs]
    transnodes = [Node(string("rx_$i"), Attributes(:shape=>"point", :color=>"#E28F41", :width=>".1")) for (i,r) in enumerate(rxs)]

    stmts = vcat(statenodes, transnodes)
    edges = map(enumerate(rxs)) do (i,r)
      vcat(edgify(zip(r.substrates,r.substoich), i, false),
           edgify(zip(r.products,r.prodstoich), i, true))
    end
    es = edgifyrates(rxs, specs)
    (!isempty(es)) && push!(edges, es)

    stmts = vcat(stmts, collect(flatten(edges)))
    g = Graphviz.Digraph("G", stmts; graph_attrs=graph_attrs, node_attrs=node_attrs, edge_attrs=edge_attrs)
    return g
end


"""
    savegraph(g::Graph, fname, fmt="png")

Given a [Catlab.jl](https://github.com/AlgebraicJulia/Catlab.jl/) `Graph`
generated by [`Graph`](@ref), save the graph to the file with name `fname` and
extension `fmt`. 

Notes:
- `fmt="png"` is the default output format.
"""
function savegraph(g::Graph, fname, fmt="png")
    open(fname, "w") do io
        run_graphviz(io, g, format=fmt)
    end 
    nothing
end