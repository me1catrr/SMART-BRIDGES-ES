using CSV
using DataFrames
using Plots

function generar_graficas(carpeta_fecha::String, sensores::Vector{String}, pasos::DataFrame)
    println("🟢 Generando gráficas XYZ para cada paso de tren...")

    carpeta_salida = joinpath("plots", "raw", carpeta_fecha)
    mkpath(carpeta_salida)

    for row in eachrow(pasos)
        archivo = row.filename
        paso = row.paso_tren

        # Carpeta para este paso
        carpeta_paso = joinpath(carpeta_salida, replace(archivo, ".csv" => ""))
        mkpath(carpeta_paso)

        # Intentamos leer los datos de todos los sensores
        datos_por_sensor = Dict{String, DataFrame}()
        for sensor in sensores
            ruta = joinpath("data", "raw", carpeta_fecha, sensor, archivo)
            if isfile(ruta)
                try
                    df = CSV.read(ruta, DataFrame)

                    columnas_esperadas = ["timestamp", "x_accel (g)", "y_accel (g)", "z_accel (g)"]
                    if all(col -> col ∈ names(df), columnas_esperadas)
                        datos_por_sensor[sensor] = df
                    else
                        println("⚠️ Columnas faltantes en $sensor para $archivo")
                    end
                catch e
                    println("⚠️ Error leyendo $archivo de $sensor: $e")
                end
            else
                println("⚠️ Archivo no encontrado: $ruta")
            end
        end

        # Si no hay datos útiles, saltamos
        if isempty(datos_por_sensor)
            println("⚠️ Sin datos válidos para: $archivo")
            continue
        end

        # Graficar cada eje
        for eje in ["x", "y", "z"]
            fig = plot(title="Paso $paso - Aceleración eje $eje", xlabel="Tiempo", ylabel="Aceleración (g)", size=(1200, 800))

            for (sensor, df) in datos_por_sensor
                try
                    tiempos = df.timestamp
                    valores = df[!, "$(eje)_accel (g)"]
                    plot!(fig, tiempos, valores, label=sensor)
                catch e
                    println("⚠️ Error graficando $sensor eje $eje: $e")
                end
            end

            ruta_img = joinpath(carpeta_paso, "$(eje)_accel.png")
            savefig(fig, ruta_img)
            println("📊 Guardado: $ruta_img")
        end
    end
end