using CSV
using DataFrames
using FilePathsBase: basename
using FilePathsBase
using Base.Filesystem: rm, isdir, isfile

function accel_XYZ(carpeta_base::String, sensores::Vector{String}, pasos::DataFrame)
    println("📦 Exportando señales por eje sin modificar...")

    # Ruta completa base donde están los datos crudos
    ruta_datos = joinpath("data", "raw", carpeta_base)

    # Carpeta de salida
    carpeta_salida = joinpath("data", "accel_xyz")

    # 🧹 Eliminar contenido previo si existe
    if isdir(carpeta_salida)
        println("🧹 Borrando contenido previo de $carpeta_salida")
        rm(carpeta_salida; force=true, recursive=true)
    end
    mkpath(carpeta_salida)

    for row in eachrow(pasos)
        archivo = row.filename
        nombre = replace(archivo, ".csv" => "")
        carpeta_archivo = joinpath(carpeta_salida, nombre)

        # Verificar que el archivo existe para todos los sensores
        existe_en_todos = all(sensor -> isfile(joinpath(ruta_datos, sensor, archivo)), sensores)

        if !existe_en_todos
            println("⚠️  Skipping $archivo: no está presente en todos los sensores")
            continue
        end

        println("🔍 Procesando $archivo")
        for eje in ["x", "y", "z"]
            mkpath(joinpath(carpeta_archivo, eje))
        end

        for sensor in sensores
            ruta_entrada = joinpath(ruta_datos, sensor, archivo)
            try
                df = CSV.read(ruta_entrada, DataFrame)

                if ncol(df) ≥ 4
                    timestamp = df[:, 1]
                    x = df[:, 2]
                    y = df[:, 3]
                    z = df[:, 4]

                    # Guardar por eje
                    for (eje, data) in zip(["x", "y", "z"], [x, y, z])
                        df_out = DataFrame(timestamp = timestamp, acceleration = data)
                        nombre_out = "$(eje)_$(sensor).csv"
                        ruta_out = joinpath(carpeta_archivo, eje, nombre_out)
                        CSV.write(ruta_out, df_out)
                    end
                else
                    println("⚠️  Columnas faltantes en $sensor para $archivo")
                end
            catch e
                println("⚠️  Error procesando $archivo de $sensor: $e")
            end
        end
    end
end