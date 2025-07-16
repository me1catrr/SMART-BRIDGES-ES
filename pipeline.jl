###########################################################
# pipeline.jl
#
# Pipeline completo para monitorización de vibraciones
# de un puente con pasos de trenes.
#
# Incluye:
# - Carga de señales
# - Preprocesado (filtro, normalización)
# - Transformadas (FFT, wavelet)
# - Extracción de características
# - Modelado (supervisado y no supervisado)
# - Alineamiento DTW
# - Visualización
###########################################################

# ============================
# Librerías necesarias
# ============================
using DelimitedFiles      # Para leer CSV
using DSP                 # Procesado de señales
using StatsBase           # Estadísticas básicas
using MLJ                 # Machine Learning
using Plots               # Visualización
using Wavelets            # Wavelets
using Flux                # Deep Learning (Autoencoder)
using DynamicAxisWarping  # DTW
using Distances           # Distancias adicionales

# ============================
# Parámetros generales
# ============================

fs = 2000                     # Frecuencia de muestreo en Hz
data_dir = "data/"            # Carpeta con tus CSV
labels_file = "labels.csv"    # Etiquetas (si tienes)

# ============================
# 1. Carga de datos
# ============================
println("Cargando archivos CSV...")

# Leer nombres de archivos
files = readdir(data_dir)

# Cargar todas las señales
signals = [readdlm(joinpath(data_dir, f))[:,1] for f in files]

println("Total de señales cargadas: ", length(signals))

# Si tienes etiquetas, las cargamos
labels = readdlm(labels_file)[:,1]  # 0 = normal, 1 = anómalo

# ============================
# 2. Preprocesado
# ============================

# Filtro pasa banda 1-500 Hz
bp_filter = butter(4, (1,500), fs=fs)

# Filtro notch (opcional, para eliminar frecuencia concreta)
# notch_filter = notch(50, fs)  # Si quieres quitar 50Hz

# Función de filtrado y normalización
function preprocess_signal(x)
    filtered = filtfilt(bp_filter, x)
    normed = (filtered .- mean(filtered)) ./ std(filtered)
    return normed
end

# Aplicar a todas las señales
preprocessed_signals = [preprocess_signal(s) for s in signals]

println("Preprocesado completado.")

# ============================
# 3. Extracción de características
# ============================

# FFT auxiliar
function compute_fft(x)
    abs.(fft(x))
end

# Frecuencias correspondientes
function fft_freqs(N, fs)
    (0:N-1)*(fs/N)
end

# Wavelet energy
function wavelet_energy(x)
    wt = modwt(x, wavelet(WT.db2), 4)
    [sum(abs2, wt[j]) for j in 1:length(wt)]
end

# Función principal de extracción de features
function extract_features(x)
    rms = sqrt(mean(x.^2))
    max_amp = maximum(abs.(x))
    crest = max_amp / rms
    energy = sum(x.^2)
    decay_time = sum(abs.(diff(x)))

    # FFT
    fft_vals = compute_fft(x)
    freqs = fft_freqs(length(x), fs)
    peak_freq = freqs[argmax(fft_vals[1:div(end,2)])]

    # Wavelet energies
    wavelet_energies = wavelet_energy(x)

    return vcat(
        [rms, max_amp, crest, energy, decay_time, peak_freq],
        wavelet_energies
    )
end

# Extraemos características de todas las señales
X_features = [extract_features(s) for s in preprocessed_signals]
X = reduce(vcat, [f' for f in X_features])  # Matriz NxM

println("Extracción de características completada.")

# ============================
# 4. Modelado
# ============================

# ========== Supervisado ==========
# Random Forest
@load RandomForestClassifier pkg=DecisionTree
model_rf = RandomForestClassifier()
mach_rf = machine(model_rf, X, labels)
fit!(mach_rf)

# Predicción
yhat_rf = predict_mode(mach_rf, X)

# SVM
@load SVC pkg=LIBSVM
model_svm = SVC()
mach_svm = machine(model_svm, X, labels)
fit!(mach_svm)

yhat_svm = predict_mode(mach_svm, X)

# ========== No Supervisado ==========
# Isolation Forest
@load IsolationForest pkg=IsolationForest
model_if = IsolationForest()
mach_if = machine(model_if, X)
fit!(mach_if)

scores_if = predict(mach_if, X)

# One-Class SVM
@load OneClassSVM pkg=LIBSVM
model_ocsvm = OneClassSVM()
mach_ocsvm = machine(model_ocsvm, X)
fit!(mach_ocsvm)

scores_ocsvm = predict(mach_ocsvm, X)

# Autoencoder
input_size = size(X,2)

encoder = Chain(
    Dense(input_size, 32, relu),
    Dense(32, 8, relu)
)
decoder = Chain(
    Dense(8, 32, relu),
    Dense(32, input_size)
)

autoencoder = Chain(encoder, decoder)

# Normalizar X
X_norm = (X .- mean(X, dims=1)) ./ std(X, dims=1)
X_tensor = permutedims(X_norm)

loss(x) = Flux.Losses.mse(autoencoder(x), x)
opt = ADAM()

println("Entrenando Autoencoder...")
for epoch in 1:20
    grads = gradient(() -> loss(X_tensor), Flux.params(autoencoder))
    Flux.Optimise.update!(opt, Flux.params(autoencoder), grads)
    println("Epoch $epoch, loss=", round(loss(X_tensor), digits=6))
end

errors = [Flux.Losses.mse(autoencoder(x), x) for x in eachcol(X_tensor)]

println("Modelado completado.")

# ============================
# 5. Umbrales dinámicos
# ============================

threshold_if = -0.5
threshold_ae = 0.02

anomalies = [ (s < threshold_if) || (e > threshold_ae)
              for (s,e) in zip(scores_if, errors) ]

# ============================
# 6. Alineamiento con DTW
# ============================

# Opcional: comparar la primera señal con las demás
reference = preprocessed_signals[1]
dtw_distances = [dtw(reference, s) for s in preprocessed_signals]

# ============================
# 7. Visualización
# ============================

# Energía y amplitud
energies = X[:,4]
maxamps = X[:,2]

plot(energies, label="Energía total")
plot!(maxamps, label="Amplitud máxima", xlabel="Evento")

# Mapa de calor de espectros
spectrograms = [compute_fft(s)[1:200] for s in preprocessed_signals]
heatmap(hcat(spectrograms...), xlabel="Evento", ylabel="Frecuencia bin", title="Espectros por evento")

# Puntuación de anomalías
plot(scores_if, label="Isolation Forest")
plot!(errors, label="Error Autoencoder", xlabel="Evento", ylabel="Puntuación")

# DTW
plot(dtw_distances, label="DTW Distance to Ref", xlabel="Evento")

# ============================
# 8. Resumen de resultados
# ============================

println("\nResumen de resultados:")
for i in 1:length(anomalies)
    println("Evento $(i): IF=$(round(scores_if[i], digits=3)) | AE=$(round(errors[i], digits=4)) | Anómalo=$(anomalies[i])")
end

println("\nPipeline completado con éxito.")

