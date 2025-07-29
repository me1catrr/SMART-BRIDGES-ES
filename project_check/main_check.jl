using FilePathsBase
using Dates

include("check_estadisticas.jl")
include("plot_estadisticas.jl")

# Carpeta donde se guardarán los resultados de la comparación
carpeta_resultados_check = "results_check"
mkpath(carpeta_resultados_check)  # ← crea la carpeta si no existe

# Fechas a comparar
fechas = ["2025-07-16", "2025-07-17", "2025-07-18", "2025-07-19", "2025-07-20"]

# Carpeta base de resultados por día
carpeta_resultados = "results"

# Comparar estadísticas XYZ
check_estadisticas(fechas, carpeta_resultados)

# Graficar comparativas
plot_estadisticas(fechas, carpeta_resultados)