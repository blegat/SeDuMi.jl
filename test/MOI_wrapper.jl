using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

using SeDuMi

const MOIU = MOI.Utilities
MOIU.@model(ModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, MOI.SecondOrderCone,
             MOI.RotatedSecondOrderCone, MOI.PositiveSemidefiniteConeTriangle),
            (),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction,))

optimizer = MOIU.CachingOptimizer(ModelData{Float64}(),
                                  SeDuMi.Optimizer(fid=0))

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "SeDuMi"
end

@testset "supports_allocate_load" begin
    @test MOIU.supports_allocate_load(optimizer.optimizer, false)
    @test !MOIU.supports_allocate_load(optimizer.optimizer, true)
end

config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Unit" begin
    MOIT.unittest(MOIB.SplitInterval{Float64}(optimizer), config,
                  [# Quadratic functions are not supported
                   "solve_qcp_edge_cases", "solve_qp_edge_cases",
                   # Integer and ZeroOne sets are not supported
                   "solve_integer_edge_cases", "solve_objbound_edge_cases"])
end

@testset "Continuous linear problems" begin
    MOIT.contlineartest(MOIB.SplitInterval{Float64}(optimizer), config,
                        ["linear13"] # See https://github.com/blegat/SeDuMi.jl/issues/7
                       )
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(MOIB.SquarePSD{Float64}(MOIB.RootDet{Float64}(MOIB.GeoMean{Float64}(optimizer))),
                       config, ["rootdets", "exp", "logdet"])
end
