using CSV
using DataFrames
using Statistics
using Plots

function estadisticas_XYZ(carpeta_base::String, sensores::Vector{String}, pasos::DataFrame, fecha::String)
    println("📈 Calculando estadísticas globales por sensor y eje...")

    # Rutas de salida
    carpeta_resultados = joinpath("results", "Guadiato_$fecha")
    carpeta_plots = joinpath("plots", "stats", "Guadiato_$fecha")
    mkpath(carpeta_resultados)
    mkpath(carpeta_plots)

    ruta_datos = joinpath("data", "raw", carpeta_base)
    resultados = DataFrame(sensor=String[], eje=String[], media=Float64[], std=Float64[], min=Float64[], max=Float64[])
    datos_completos = Dict("x" => Dict{String, Vector{Float64}}(),
                           "y" => Dict{String, Vector{Float64}}(),
                           "z" => Dict{String, Vector{Float64}}())

    for sensor in sensores
        valores = Dict("x" => Float64[], "y" => Float64[], "z" => Float64[])

        for row in eachrow(pasos)
            archivo = row.filename
            ruta_archivo = joinpath(ruta_datos, sensor, archivo)

            if isfile(ruta_archivo)
                try
                    df = CSV.read(ruta_archivo, DataFrame)
                    if ncol(df) ≥ 4
                        append!(valores["x"], df[:, 2])
                        append!(valores["y"], df[:, 3])
                        append!(valores["z"], df[:, 4])
                    else
                        println("⚠️  Columnas faltantes en $archivo para $sensor")
                    end
                catch e
                    println("⚠️  Error leyendo $ruta_archivo: $e")
                end
            else
                println("⚠️  Archivo no encontrado: $ruta_archivo")
            end
        end

        for eje in ["x", "y", "z"]
            datos_eje = valores[eje]
            if !isempty(datos_eje)
                push!(resultados, (
                    sensor,
                    eje,
                    mean(datos_eje),
                    std(datos_eje),
                    minimum(datos_eje),
                    maximum(datos_eje)
                ))
                datos_completos[eje][sensor] = datos_eje
            end
        end
    end

    # Guardar CSV
    salida_csv = joinpath(carpeta_resultados, "estadisticas_xyz_$fecha.csv")
    CSV.write(salida_csv, resultados)
    println("✅ Estadísticas guardadas en: $salida_csv")

    # Graficar barras media ± std
    for eje in ["x", "y", "z"]
        sensores_validos = collect(keys(datos_completos[eje]))
        medias = [mean(datos_completos[eje][s]) for s in sensores_validos]
        stds   = [std(datos_completos[eje][s]) for s in sensores_validos]

        fig = bar(
            sensores_validos,
            medias,
            yerror=stds,
            xlabel="Sensor",
            ylabel="Aceleración (g)",
            title="Media ± Desviación estándar eje $eje",
            legend=false,
            size=(1000, 700)
        )

        ruta_plot = joinpath(carpeta_plots, "barras_$(eje)_$fecha.png")
        savefig(fig, ruta_plot)
        println("📊 Gráfico guardado: $ruta_plot")
    end
end