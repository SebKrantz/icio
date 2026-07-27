# Validate the Julia GlobalValueChains.jl decompositions against the Stata `icio` reference output
# for the EMERGING ICIO data. This is the upstream reference that icio::bm() is in turn checked
# against (see validate_bm_emerging.R); GlobalValueChains.jl and bm() agree to ~1e-13, and
# GlobalValueChains.jl matches Stata to ~1e-7 (the residual is Strassen-inversion vs BLAS-LU
# rounding, not a method gap).
#
# Local/dev script (the misc/ folder is git-ignored). Requires the EMERGING CSV tables and the
# renamed Stata references EM_GVC_KWW_BM19_STATA.csv / EM_GVC_SEC_BM19_STATA.csv, plus the
# bilateral sample EM_GVC_BIL_SEC_SAMPLE.csv produced by ICIO_decomp_bil_sample.do.
#
#   julia misc/validate_icio_vs_stata.jl

import Pkg
Pkg.activate("/Users/sebastiankrantz/Documents/Julia/ICIO.jl")
using GlobalValueChains, CSV, DataFrames

base = "/Users/sebastiankrantz/Documents/Data/EMERGING/ICIO_CSV/EMERGING_Broad_Sectors"
cl   = joinpath(base, "EM_countrylist.csv")
SEC  = ["AFF","FBE","PCM","PSM","TEX","WAP","MPR","ELM","TEQ","MAN",
        "EGW","MIN","SMH","TRA","PTE","CON","FIB","PAO"]
year = 2015

maxrel(a, b; thr = 1.0) = (a = Float64.(a); b = Float64.(coalesce.(b, 0.0));
    big = abs.(b) .> thr; any(big) ? maximum(abs.(a[big] .- b[big]) ./ abs.(b[big])) : 0.0)
function report(tag, R, S, cols)
    println(tag, "  (", nrow(R), " rows)")
    for c in cols
        a = Float64.(R[!, c]); b = Float64.(coalesce.(S[!, c], 0.0))
        println("  ", rpad(string(c), 6), " maxrel=", round(maxrel(a, b), sigdigits = 3),
                "  maxabs=", round(maximum(abs.(a .- b)), sigdigits = 4))
    end
end

m = read_icio_csv(joinpath(base, "EM_$(year).csv"), cl; sectors = SEC)

## 1. country, world / sink (9 terms)
jc = sort(decompose(m; level = :country, perspective = :world, approach = :sink), :country)
sc = sort(CSV.read(joinpath(base, "EM_GVC_KWW_BM19_STATA.csv"), DataFrame)[!, :] |>
          df -> df[df.year .== year, :], :country)
@assert jc.country == sc.country
report("== GlobalValueChains.jl COUNTRY world/sink vs Stata ==", jc, sc,
       [:gexp,:dc,:dva,:vax,:ref,:ddc,:fc,:fva,:fdc])

## 2. sector, exporter / source (13 terms) -- Stata uses integer sector index
js = decompose(m; level = :sector)
js.sidx = [findfirst(==(s), SEC) for s in js.from_sector]
js = sort(js, [:from_region, :sidx])
ss = CSV.read(joinpath(base, "EM_GVC_SEC_BM19_STATA.csv"), DataFrame)
ss = sort(ss[ss.year .== year, :], [:from_region, :from_sector])
@assert js.from_region == ss.from_region && js.sidx == ss.from_sector
report("== GlobalValueChains.jl SECTOR exporter/source vs Stata ==", js, ss,
       [:gexp,:dc,:dva,:vax,:davax,:ref,:ddc,:fc,:fva,:fdc,:gvc,:gvcb,:gvcf])

## 3. bilateral, exporter / source (13 terms) -- vs the Stata sample
sbpath = joinpath(base, "EM_GVC_BIL_SEC_SAMPLE.csv")
if isfile(sbpath)
    sb = CSV.read(sbpath, DataFrame)
    exps = unique(sb.from_region); imps = unique(sb.to_region)
    jb = decompose(m; level = :bilateral)
    jb = jb[in.(jb.from_region, Ref(Set(exps))) .& in.(jb.to_region, Ref(Set(imps))), :]
    jb.sidx = [findfirst(==(s), SEC) for s in jb.from_sector]
    jb = sort(jb, [:from_region, :sidx, :to_region])
    sb = sort(sb, [:from_region, :from_sector, :to_region])
    @assert jb.from_region == sb.from_region && jb.sidx == sb.from_sector && jb.to_region == sb.to_region
    report("== GlobalValueChains.jl BILATERAL exporter/source vs Stata sample ==", jb, sb,
           [:gexp,:dc,:dva,:vax,:davax,:ref,:ddc,:fc,:fva,:fdc,:gvc,:gvcb,:gvcf])
else
    println("(skip bilateral: ", sbpath, " not found -- run ICIO_decomp_bil_sample.do)")
end
