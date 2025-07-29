using CSV
using DataFrames
using Plots
using Statistics
using Base.Filesystem: rm, isdir
using FilePathsBase: joinpath

function centrar_XYZ(carpeta_base::String, sensores::Vector{String}, pasos::DataFrame, fecha::String)
    println("📌 Centrando señales por eje según estadística global...")

    # Ruta correcta al CSV de estadísticas con fecha explícita
    ruta_stats = joinpath("results", "Guadiato_$fecha", "estadisticas_xyz_$fecha.csv")

    # Leer estadísticas globales
    estadisticas = CSV.read(ruta_stats, DataFrame)
    rename!(estadisticas, Dict("eje" => :axis, "media" => :mean, "sensor" => :sensor))

    # 🧹 Borrar carpeta completa de salida antes de empezar
    carpeta_centrada = joinpath("data", "accel_xyz_centered")
    if isdir(carpeta_centrada)
        println("🧹 Eliminando contenido previo de $carpeta_centrada")
        rm(carpeta_centrada; force=true, recursive=true)
    end
    mkpath(carpeta_centrada)

    for paso in eachrow(pasos)
        nombre_archivo = paso.filename
        nombre_paso = split(nombre_archivo, ".")[1]  # sin extensión .csv

        ruta_entrada = joinpath("data", "raw", carpeta_base)
        ruta_salida = joinpath(carpeta_centrada, nombre_paso)
        ruta_graficas = joinpath("plots", "centered", "Guadiato_centered_$fecha", nombre_paso)

        for eje in ["x", "y", "z"]
            mkpath(joinpath(ruta_salida, eje))
            mkpath(ruta_graficas)

            p = plot(title="Paso $(paso.paso_tren) - Aceleración eje $eje", xlabel="Tiempo", ylabel="Aceleración (g)")

            for sensor in sensores
                ruta_csv = joinpath(ruta_entrada, sensor, nombre_archivo)
                try
                    datos = CSV.read(ruta_csv, DataFrame)

                    rename!(datos, Dict(
                        "timestamp" => :timestamp,
                        "x_accel (g)" => :x,
                        "y_accel (g)" => :y,
                        "z_accel (g)" => :z
                    ))

                    media_global = estadisticas[(estadisticas.sensor .== sensor) .& (estadisticas.axis .== eje), :mean]
                    if length(media_global) == 1
                        datos[!, Symbol(eje)] .-= media_global[1]
                    else
                        @warn "Media no encontrada para $sensor eje $eje"
                        continue
                    end

                    nombre_csv = "$(eje)_centered_$(sensor).csv"
                    CSV.write(joinpath(ruta_salida, eje, nombre_csv), datos[:, [:timestamp, Symbol(eje)]])
                    plot!(p, datos.timestamp, datos[!, Symbol(eje)], label=sensor)

                catch e
                    @warn "Error procesando $(ruta_csv): $e"
                end
            end

            savefig(p, joinpath(ruta_graficas, "$(eje)_accel_centered.png"))
        end

        println("✅ Finalizado: $nombre_archivo")
    end
end