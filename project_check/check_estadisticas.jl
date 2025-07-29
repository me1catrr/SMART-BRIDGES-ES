using CSV
using DataFrames
using Statistics
using Dates

function check_estadisticas(fechas::Vector{String}, carpeta_resultados::String)
    println("📊 Comparando estadísticas XYZ entre fechas: ", fechas)

    # Inicializar estructura
    estadisticas_totales = DataFrame()

    for fecha in fechas
        ruta_csv = joinpath(carpeta_resultados, "Guadiato_$fecha", "estadisticas_xyz_$fecha.csv")

        if !isfile(ruta_csv)
            @warn "Archivo no encontrado: $ruta_csv"
            continue
        end

        df = CSV.read(ruta_csv, DataFrame)
        df.fecha = fill(fecha, nrow(df))  # columna con la fecha actual
        append!(estadisticas_totales, df)
    end

    if nrow(estadisticas_totales) == 0
        @warn "No se encontraron archivos válidos."
        return
    end

    println("✅ Datos cargados correctamente. Registros: ", nrow(estadisticas_totales))

    # Agrupar por sensor y eje y comparar estadísticos entre días
    sensores = unique(estadisticas_totales.sensor)
    ejes = unique(estadisticas_totales.eje)

    columnas_salida = [:sensor, :eje,
        :media_mean, :media_std, :media_min, :media_max,
        :std_mean, :std_std, :std_min, :std_max,
        :min_mean, :min_std, :min_min, :min_max,
        :max_mean, :max_std, :max_min, :max_max]

    comparativa = DataFrame([c => Any[] for c in columnas_salida])

    for sensor in sensores
        for eje in ejes
            subset = estadisticas_totales[(estadisticas_totales.sensor .== sensor) .& (estadisticas_totales.eje .== eje), :]

            if nrow(subset) == 0
                continue
            end

            vals_media = skipmissing(subset.media)
            vals_std   = skipmissing(subset.std)
            vals_min   = skipmissing(subset.min)
            vals_max   = skipmissing(subset.max)

            push!(comparativa, (
                sensor,
                eje,
                mean(vals_media), std(vals_media), minimum(vals_media), maximum(vals_media),
                mean(vals_std),   std(vals_std),   minimum(vals_std),   maximum(vals_std),
                mean(vals_min),   std(vals_min),   minimum(vals_min),   maximum(vals_min),
                mean(vals_max),   std(vals_max),   minimum(vals_max),   maximum(vals_max)
            ))
        end
    end

    # Crear carpeta y guardar resultado
    output_dir = joinpath("results_check", "estadisticas")
    mkpath(output_dir)

    nombre_csv = "comparativa_estadisticas_" * join(fechas, "_vs_") * ".csv"
    ruta_salida = joinpath(output_dir, nombre_csv)

    CSV.write(ruta_salida, comparativa)
    println("💾 Comparativa guardada en: $ruta_salida")
end