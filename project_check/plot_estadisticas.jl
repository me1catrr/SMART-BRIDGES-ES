using CSV
using DataFrames
using Plots

function plot_estadisticas(fechas::Vector{String}, carpeta_resultados::String)
    println("📈 Generando gráficas comparativas de estadísticas")

    estadisticas_totales = DataFrame()

    for fecha in fechas
        ruta_csv = joinpath(carpeta_resultados, "Guadiato_$fecha", "estadisticas_xyz_$fecha.csv")
        if !isfile(ruta_csv)
            @warn "Archivo no encontrado: $ruta_csv"
            continue
        end
        df = CSV.read(ruta_csv, DataFrame)
        df.fecha = fill(fecha, nrow(df))
        append!(estadisticas_totales, df)
    end

    if nrow(estadisticas_totales) == 0
        @warn "No se encontraron datos para graficar."
        return
    end

    # Crear carpeta de salida
    carpeta_salida = joinpath("results_check", "estadisticas", "plots")
    mkpath(carpeta_salida)

    sensores = unique(estadisticas_totales.sensor)
    ejes = unique(estadisticas_totales.eje)

    for sensor in sensores
        for eje in ejes
            subset = estadisticas_totales[(estadisticas_totales.sensor .== sensor) .& (estadisticas_totales.eje .== eje), :]

            if nrow(subset) == 0
                continue
            end

            p = plot(title = "Estadísticas de $sensor eje $eje", xlabel = "Fecha", legend=:topright, rotation=45)
            plot!(p, subset.fecha, subset.media, label = "media", marker = :circle)
            plot!(p, subset.fecha, subset.std,   label = "std",   marker = :square)
            plot!(p, subset.fecha, subset.min,   label = "min",   marker = :diamond)
            plot!(p, subset.fecha, subset.max,   label = "max",   marker = :utriangle)

            nombre_archivo = "$(sensor)_$(eje)_estadisticas.png"
            savefig(p, joinpath(carpeta_salida, nombre_archivo))
        end
    end

    println("✅ Gráficas guardadas en: $carpeta_salida")
end
