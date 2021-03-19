### Fetch required packages and reaction networks ###
using DiffEqBase, Catalyst, Random, Test

using StableRNGs
rng = StableRNG(12345)

### Tests various cutom made functions ###
new_hill(x, v, k, n) = v*x^n/(k^n+x^n)
new_poly(x,p1,p2) = .5*p1*x^2
new_exp(x,p) = exp(-p*x)

custom_function_network_1 = @reaction_network begin
    hill(X,v1,K1,2), X + Y --> Z1
    mm(X,v2,K2), X + Y --> Z2
    p1*X^2+p2, X + Y --> Z3
    exp(-p3*Y), X + Y --> Z4
    hillR(X,v3,K3,2), X + Y --> Z5
    mmR(X,v4,K4), X + Y --> Z6
    hillC(X,Y,v5,K5,2), X + Y --> Z7
    mmC(X,Y,v6,K6), X + Y --> Z8
end v1 K1 v2 K2 p1 p2 p3 v3 K3 v4 K4 v5 K5 v6 K6

custom_function_network_2 = @reaction_network begin
    new_hill(X,v1,K1,2), X + Y --> Z1
    v2*X/(X+K2), X + Y --> Z2
    2*new_poly(X,p1,p2)+p2, X + Y --> Z3
    new_exp(Y,p3), X + Y --> Z4
    v3*(K3^2)/(K3^2+X^2), X + Y --> Z5
    v4*K4/(X+K4), X + Y --> Z6
    v5*(X^2)/(K5^2+X^2+Y^2), X + Y --> Z7
    v6*(X)/(K6+X+Y), X + Y --> Z8
end v1 K1 v2 K2 p1 p2 p3 v3 K3 v4 K4 v5 K5 v6 K6

f1 = ODEFunction(convert(ODESystem,custom_function_network_1),jac=true)
f2 = ODEFunction(convert(ODESystem,custom_function_network_2),jac=true)
g1 = SDEFunction(convert(SDESystem,custom_function_network_1))
g2 = SDEFunction(convert(SDESystem,custom_function_network_2))
for factor in [1e-2, 1e-1, 1e0, 1e1, 1e2, 1e3]
    u0 = factor*rand(rng,length(custom_function_network_1.states))
    p = factor*rand(rng,length(custom_function_network_2.ps))
    t = rand(rng)
    @test all(abs.(f1(u0,p,t) .- f2(u0,p,t)) .< 100*eps())
    @test all(abs.(f1.jac(u0,p,t) .- f2.jac(u0,p,t)) .< 100*eps())
    @test all(abs.(g1(u0,p,t) .- g2(u0,p,t)) .< 100*eps())
end
