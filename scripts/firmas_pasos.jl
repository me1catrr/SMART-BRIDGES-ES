using CSV
using DataFrames
using Statistics
using StatsBase

function generar_firmas_pasos(path_kpis::String, path_salida::String)
    println("📄 Leyendo KPIs desde: $path_kpis")
    df = CSV.read(path_kpis, DataFrame)

    columnas_no_kpi = ["paso", "eje", "sensor", "tipo"]
    columnas_kpi = [c for c in names(df) if !(string(c) in columnas_no_kpi)]

    firma_cols = [:paso, :eje]
    for kpi in columnas_kpi
        push!(firma_cols, Symbol("$(kpi)_mean"))
    end

    firmas = DataFrame([col => Any[] for col in firma_cols])

    for paso in unique(df.paso)
        for eje in unique(df[df.paso .== paso, :eje])
            df_sub = df[(df.paso .== paso) .& (df.eje .== eje), :]

            row_firma = Any[string(paso), string(eje)]
            for kpi in columnas_kpi
                vals = skipmissing(df_sub[!, kpi])
                push!(row_firma, Float64(mean(vals)))
            end

            push!(firmas, row_firma)
        end
    end

    println("✅ Guardando firmas de pasos en: $path_salida")
    CSV.write(path_salida, firmas)
end