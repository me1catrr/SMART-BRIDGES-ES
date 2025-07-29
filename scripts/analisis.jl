using CSV
using DataFrames
using Dates

function analizar_archivos_comunes(carpeta_base::String, sensores::Vector{String}, fecha::String)
    println("🔍 Analizando archivos comunes...")

    ruta_base = joinpath("data", "raw", carpeta_base)
    carpeta_salida = joinpath("results", "Guadiato_$fecha")
    mkpath(carpeta_salida)

    archivos_por_sensor = Dict(
        sensor => Set(filter(f -> endswith(f, ".csv"), readdir(joinpath(ruta_base, sensor))))
        for sensor in sensores
    )

    comunes = reduce(intersect, values(archivos_por_sensor))

    resultados = DataFrame(
        paso_tren = Int[],
        filename = String[],
        timestamp_start = String[],
        timestamp_end = String[],
        duration_seconds = Float64[]
    )

    paso_id = 1
    for archivo in sort(collect(comunes))
        ruta = joinpath(ruta_base, sensores[1], archivo)
        try
            df = CSV.read(ruta, DataFrame)
            tstart = Time(string(df[1, 1]))
            tend = Time(string(df[end, 1]))
            duracion = Dates.value(tend - tstart) / 1e9
            push!(resultados, (paso_id, archivo, string(tstart), string(tend), max(duracion, 0)))
            paso_id += 1
        catch e
            println("❌ Error leyendo $archivo: $e")
        end
    end

    outpath = joinpath(carpeta_salida, "paso_trenes_$fecha.csv")
    CSV.write(outpath, resultados)
    println("✅ Archivo generado: $outpath")

    return resultados
end