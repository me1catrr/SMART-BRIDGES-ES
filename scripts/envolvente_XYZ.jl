using CSV
using DataFrames
using Glob
using Plots
using Statistics
using Dates
using FilePathsBase
using Interpolations

# Detectar extremos locales (máximos o mínimos)
function detectar_extremos(y::Vector{Float64}, tipo::Symbol)
    n = length(y)
    extremos = Int[]
    for i in 2:n-1
        if tipo == :max && y[i] ≥ y[i-1] && y[i] ≥ y[i+1]
            push!(extremos, i)
        elseif tipo == :min && y[i] ≤ y[i-1] && y[i] ≤ y[i+1]
            push!(extremos, i)
        end
    end
    return extremos
end

# Generar envolvente interpolada que comience y termine en cero
function envolvente_interpolada(t::Vector{Time}, y::Vector{Float64}, tipo::Symbol)
    idxs = detectar_extremos(y, tipo)
    idxs = [1; idxs; length(y)]
    tiempos = collect(1:length(y))
    puntos_x = tiempos[idxs]
    puntos_y = tipo == :max ? max.(y[idxs], 0.0) : min.(y[idxs], 0.0)
    puntos_y[1] = 0.0
    puntos_y[end] = 0.0
    itp = LinearInterpolation(puntos_x, puntos_y, extrapolation_bc=Line())
    return [itp(i) for i in tiempos]
end

function generar_envolventes(fecha::String)
    ruta_datos = joinpath("data", "accel_xyz_centered")
    carpeta_salida_base = joinpath("data", "accel_xyz_envolvente", "Guadiato_$fecha")
    carpeta_graficas_env = joinpath("plots", "envolvente", "Guadiato_envolvente_$fecha")
    carpeta_graficas_mix = joinpath("plots", "mixed", "Guadiato_mixed_$fecha")

    ejes = ["x", "y", "z"]
    sensores = ["sensor_01", "sensor_02", "sensor_03", "sensor_04",
                "sensor_05", "sensor_06", "sensor_07", "sensor_08"]

    carpetas_pasos = filter(isdir, sort(Glob.glob(joinpath(ruta_datos, "acceleration_*"))))

    for carpeta in carpetas_pasos
        nombre_paso = basename(carpeta)

        for eje in ejes
            for sensor in sensores
                archivo = joinpath(carpeta, eje, "$(eje)_centered_$(sensor).csv")
                if !isfile(archivo)
                    @warn "Archivo no encontrado: $archivo"
                    continue
                end

                df = CSV.read(archivo, DataFrame)
                t = df.timestamp
                vals = df[:, 2]

                # Envolventes
                env_sup = envolvente_interpolada(t, vals, :max)
                env_inf = envolvente_interpolada(t, vals, :min)

                # Guardar CSV
                carpeta_csv = joinpath(carpeta_salida_base, nombre_paso, eje)
                mkpath(carpeta_csv)
                df_out = DataFrame(timestamp = t,
                                   envolvente_superior = env_sup,
                                   envolvente_inferior = env_inf)
                CSV.write(joinpath(carpeta_csv, "$(eje)_envolvente_$(sensor).csv"), df_out)

                # Gráfico envolvente
                carpeta_plot_env = joinpath(carpeta_graficas_env, nombre_paso, eje)
                mkpath(carpeta_plot_env)
                p = plot(t, env_sup, label="Envolvente sup", color=:red)
                plot!(p, t, env_inf, label="Envolvente inf", color=:blue)
                title!(p, "$nombre_paso - $eje - $sensor")
                xlabel!("Tiempo")
                ylabel!("Aceleración (g)")
                savefig(p, joinpath(carpeta_plot_env, "$(eje)_envolvente_$(sensor).png"))

                # Gráfico señal + envolventes
                carpeta_plot_mix = joinpath(carpeta_graficas_mix, nombre_paso, eje)
                mkpath(carpeta_plot_mix)
                p_mix = plot(t, vals, label=sensor, color=:gray, alpha=0.5)
                plot!(p_mix, t, env_sup, label="Env sup", color=:red, linewidth=2)
                plot!(p_mix, t, env_inf, label="Env inf", color=:blue, linewidth=2)
                title!(p_mix, "$nombre_paso - Señal + Envolvente - $eje - $sensor")
                xlabel!("Tiempo")
                ylabel!("Aceleración (g)")
                savefig(p_mix, joinpath(carpeta_plot_mix, "$(eje)_mixed_$(sensor).png"))

                println("✅ $nombre_paso $eje $sensor procesado.")
            end
        end
    end
end