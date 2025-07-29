include("descarga.jl")
include("analisis.jl")
include("graficas.jl")
include("accel_XYZ.jl")
include("estadisticas_XYZ.jl")
include("centrar_XYZ.jl")
include("envolvente_XYZ.jl")
include("extraer_KPIs.jl")
include("firmas_pasos.jl")

# Configuración general
fecha = "2025-07-22"
carpeta_base = "Guadiato_raw_$fecha"
sensores = ["sensor_01", "sensor_02", "sensor_03", "sensor_04",
            "sensor_05", "sensor_06", "sensor_07", "sensor_08"]

# Paso 1: Descargar archivos
download_success = descargar_datos(fecha, sensores)

# Paso 2: Analizar archivos comunes
pasos = analizar_archivos_comunes(carpeta_base, sensores, fecha)

# Paso 3: Generar gráficas
generar_graficas(carpeta_base, sensores, pasos)

# Paso 4: Exportar señales por eje sin modificar
accel_XYZ(carpeta_base, sensores, pasos)

# Paso 5: Exportar estadísticas por eje
estadisticas_XYZ(carpeta_base, sensores, pasos, fecha)

# Paso 6: Centrar señales por eje
centrar_XYZ(carpeta_base, sensores, pasos, fecha)

# Paso 7: Calcular envolventes y generar gráficas
generar_envolventes(fecha)

# Paso 8: Extraer KPIs de envolventes
extraer_kpis_envolventes(fecha)

# Paso 9: Generar firmas de pasos
ruta_kpis = joinpath("results", "Guadiato_$fecha", "KPIs_$fecha.csv")
ruta_firmas = joinpath("results", "Guadiato_$fecha", "firma_paso_$fecha.csv")

if isfile(ruta_kpis)
    generar_firmas_pasos(ruta_kpis, ruta_firmas)
end

println("Proceso completado")