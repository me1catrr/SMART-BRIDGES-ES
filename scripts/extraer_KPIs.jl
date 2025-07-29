using CSV
using DataFrames
using Glob
using Statistics
using StatsBase
using FFTW
using DSP
using Dates

function calcular_kpis(signal::Vector{Float64}, fs::Float64)
    t = collect(0:length(signal)-1) ./ fs
    max_amp = maximum(signal)
    rms_amp = sqrt(mean(signal .^ 2))
    area = sum(signal) / fs
    time_to_peak = t[argmax(signal)]

    d_signal = diff(signal) .* fs
    max_slope_up = maximum(d_signal)
    max_slope_down = minimum(d_signal)

    skew = skewness(signal)
    kurt = kurtosis(signal)
    impulsivity = max_amp / (rms_amp + eps())

    N = length(signal)
    fft_result = abs.(fft(signal))[1:div(N, 2)]
    power_spectrum = fft_result .^ 2
    freqs = fs .* (0:div(N, 2)-1) ./ N

    total_energy = sum(power_spectrum)
    centroid = sum(freqs .* power_spectrum) / (total_energy + eps())
    bandwidth = sqrt(sum((freqs .- centroid).^2 .* power_spectrum) / (total_energy + eps()))
    flatness = exp(mean(log.(power_spectrum .+ eps()))) / (mean(power_spectrum) + eps())
    peak_freq = freqs[argmax(fft_result)]

    band_1 = sum(power_spectrum[freqs .< 10])
    band_2 = sum(power_spectrum[(freqs .>= 10) .& (freqs .< 30)])
    band_3 = sum(power_spectrum[freqs .>= 30])
    low_high_ratio = band_1 / (band_3 + eps())

    return Dict(
        "max_amplitude" => max_amp,
        "rms_amplitude" => rms_amp,
        "area_under_curve" => area,
        "time_to_peak" => time_to_peak,
        "max_slope_up" => max_slope_up,
        "max_slope_down" => max_slope_down,
        "skewness" => skew,
        "kurtosis" => kurt,
        "impulsivity_index" => impulsivity,
        "total_energy" => total_energy,
        "spectral_centroid" => centroid,
        "spectral_bandwidth" => bandwidth,
        "spectral_flatness" => flatness,
        "peak_frequency" => peak_freq,
        "band_power_0_10Hz" => band_1,
        "band_power_10_30Hz" => band_2,
        "band_power_30+Hz" => band_3,
        "low_high_ratio" => low_high_ratio
    )
end

function extraer_kpis_envolventes(fecha::String)
    println("📊 Extrayendo KPIs de envolventes...")

    ruta_base = joinpath("data", "accel_xyz_envolvente", "Guadiato_$fecha")
    carpeta_resultados = joinpath("results", "Guadiato_$fecha")
    mkpath(carpeta_resultados)

    sensores = ["sensor_01", "sensor_02", "sensor_03", "sensor_04",
                "sensor_05", "sensor_06", "sensor_07", "sensor_08"]
    ejes = ["x", "y", "z"]

    pasos = filter(isdir, sort(Glob.glob(joinpath(ruta_base, "acceleration_*"))))

    df_kpis = DataFrame()

    for paso in pasos
        nombre_paso = basename(paso)
        for eje in ejes
            for sensor in sensores
                archivo = joinpath(paso, eje, "$(eje)_envolvente_$(sensor).csv")
                if !isfile(archivo)
                    @warn "Falta: $archivo"
                    continue
                end

                df = CSV.read(archivo, DataFrame)
                if !("timestamp" in names(df)) || !("envolvente_superior" in names(df))
                    @warn "Formato incorrecto en $archivo"
                    continue
                end

                ts = df.timestamp
                if length(ts) < 2
                    continue
                end
                dt = Dates.value(ts[2] - ts[1]) / 1e9
                fs = 1 / dt

                for tipo in ["envolvente_superior", "envolvente_inferior"]
                    if tipo ∉ names(df)
                        continue
                    end
                    sig = df[:, tipo]
                    kpis = calcular_kpis(sig, fs)
                    kpis_sym = Dict(Symbol(k) => v for (k, v) in kpis)
                    fila = DataFrame(;
                        :paso => nombre_paso,
                        :eje => eje,
                        :sensor => sensor,
                        :tipo => tipo,
                        kpis_sym...
                    )
                    append!(df_kpis, fila)
                end
            end
        end
    end

    salida = joinpath(carpeta_resultados, "KPIs_$fecha.csv")
    CSV.write(salida, df_kpis)
    println("✅ KPIs exportados a $salida")
end