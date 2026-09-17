@testset "Pretty printing" begin
    text_plain(x) = sprint(show, MIME"text/plain"(), x)

    @testset "Scalar and plain array fields" begin
        v = HeterogeneousVector(x = 1.0, y = 2.5, z = [1, 2, 3])
        str = text_plain(v)
        @test str ==
              "5-element HeterogeneousVector{Float64} with fields (:x, :y, :z):\n" *
              "  x = 1.0\n  y = 2.5\n  z = [1, 2, 3]"
        # The verbose Ref/type-parameter noise from the default NamedTuple show
        # must not leak into the pretty-printed output.
        @test !occursin("Ref", str)
        @test !occursin("RefValue", str)
    end

    @testset "Unitful scalar and uniform-unit array fields" begin
        u0 = HeterogeneousVector(θ = 0.1u"rad", pos = [1.0, 2.0]u"m")
        str = text_plain(u0)
        @test str ==
              "3-element HeterogeneousVector{Quantity{Float64}} with fields (:θ, :pos):\n" *
              "  θ = 0.1 rad\n  pos = [1.0, 2.0] m"
        # Verbose parametric Quantity type signature must be stripped for arrays.
        @test !occursin("FreeUnits", str)
        @test !occursin("Quantity{Float64,", str)
    end

    @testset "Multiple unit systems" begin
        r0 = [1131.34, -2282.34, 6672.42]u"km"
        v0 = [-5.64, 4.30, 2.42]u"km/s"
        hv = HeterogeneousVector(r = r0, v = v0)
        str = text_plain(hv)
        @test occursin("r = [1131.34, -2282.34, 6672.42] km", str)
        @test occursin("v = [-5.64, 4.3, 2.42] km s^-1", str)
    end

    @testset "Field with no fields at all" begin
        v = HeterogeneousVector()
        str = text_plain(v)
        @test str == "0-element HeterogeneousVector{Union{}} with fields ()"
        @test length(v) == 0
    end

    @testset "Single field" begin
        v = HeterogeneousVector(a = 1.0)
        str = text_plain(v)
        @test str == "1-element HeterogeneousVector{Float64} with fields (:a,):\n  a = 1.0"
    end

    @testset "Empty array field with units" begin
        v = HeterogeneousVector(a = Float64[]u"km")
        str = text_plain(v)
        @test occursin("a = Float64[] km", str)
    end

    @testset "Non-numeric field types" begin
        v = HeterogeneousVector(name = "hello", val = 3)
        str = text_plain(v)
        @test occursin("name = \"hello\"", str)
        @test occursin("val = 3", str)
    end

    @testset "Large array field is truncated" begin
        v = HeterogeneousVector(a = collect(1:1000) * u"m")
        str = text_plain(v)
        @test occursin("…", str)
        @test occursin(" m", str)
    end

    @testset "Mixed-unit array falls back to default display" begin
        mixed = Unitful.Quantity[1.0u"m", 2.0u"s"]
        v = HeterogeneousVector(a = mixed)
        str = text_plain(v)
        # Non-concrete eltype (differing units): fall back to Base's own
        # array printing rather than guessing at a single unit to strip.
        @test occursin("a = ", str)
        @test occursin("1.0 m", str)
        @test occursin("2.0 s", str)
    end

    @testset "3-arg show is unaffected" begin
        v = HeterogeneousVector(x = 1.0, y = [1, 2, 3])
        # The compact single-line show (e.g. used inside a container) keeps
        # relying on the default flattened AbstractVector representation;
        # we only customized the MIME"text/plain" (multi-line) display.
        @test sprint(show, v) == "[1.0, 1, 2, 3]"
    end
end
