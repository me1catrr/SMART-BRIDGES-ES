# SMART-BRIDGES-ES

## ✨ Intro al proyecto

**SMART-BRIDGES-ES** (ref. **PLEC2021-007798**) es un proyecto de I+D+i orientado a la **monitorización inteligente del estado estructural de puentes ferroviarios de alta velocidad**. Su objetivo es contribuir al mantenimiento predictivo de estas infraestructuras críticas mediante el uso de sensores MEMS, análisis avanzado de vibraciones y algoritmos de prognosis estructural basados en datos.

España cuenta con más de **2.600 km de líneas de alta velocidad** y más de **200 puentes críticos**, muchos de ellos afectados por procesos de envejecimiento progresivo. Para abordar este reto, SMART-BRIDGES integra:

- **Monitorización estructural inteligente (SHM)** en tiempo real.
- Algoritmos de seguimiento de frecuencias dominantes y clasificación automática de patrones de vibración.
- Creación de **gemelos digitales** que modelan y predicen la evolución del estado estructural.
- Estrategias de **recolección de energía** (energy harvesting) para dotar de autonomía al sistema de monitorización.

El proyecto está financiado en el marco del **Programa Estatal de I+D+i Orientada a los Retos de la Sociedad** (Convocatoria 2021) y coordinado por la **Universidad de Córdoba**, en colaboración con la **Universidad de Granada** e **INECO**, ingeniería de referencia del Administrador de Infraestructuras Ferroviarias de España (**ADIF**).

**Análisis de vibraciones en puentes ferroviarios de alta velocidad monitorizados mediante acelerómetros MEMS.**

Este repositorio contiene el flujo de trabajo completo para:

✅ Preprocesado de registros breves de acelerómetros (8 sensores, 3 ejes)  
✅ Seguimiento temporal de frecuencias características  
✅ Clasificación automática de la "firma dinámica" de cada paso de tren  
✅ Visualización y generación de informes

---

## 📑 Tabla de contenidos

- [1. Motivación](#1-motivación)
- [2. Estructura del proyecto](#2-estructura-del-proyecto)
- [3. Flujo de trabajo](#3-flujo-de-trabajo)
- [4. Instalación y dependencias](#4-instalación-y-dependencias)
- [5. Scripts disponibles](#5-scripts-disponibles)
- [6. Organización de datos](#6-organización-de-datos)
- [7. Contribución](#7-contribución)
- [8. Licencia](#8-licencia)

---

## 1. Motivación

El proyecto SMART-BRIDGES monitoriza puentes ferroviarios de alta velocidad 24/7 mediante acelerómetros MEMS que registran señales de vibración de corta duración tras el paso de trenes. El objetivo es:

- Realizar *tracking* temporal de frecuencias dominantes.
- Clasificar automáticamente cada evento según su tipología dinámica.
- Detectar cambios anómalos y precursores de deterioro estructural.

---

## 2. Estructura del proyecto

```
SMART-BRIDGES-ES/
│
├── data_raw/          # Datos brutos de sensores
├── data_processed/    # Datos filtrados y corregidos
├── data_features/     # Features listas para ML
├── metadata/          # Metadata (posición de sensores, info trenes)
├── scripts/           # Scripts Julia de procesamiento
├── notebooks/         # Notebooks de exploración
├── models/            # Modelos entrenados
├── reports/           # Informes generados
├── logs/              # Logs de ejecución
├── environment/       # Entorno Julia (Project.toml, Manifest.toml)
├── .gitignore
└── README.md
```

---

## 3. Flujo de trabajo

### Fase 0 – Ingesta
- Se cargan los registros crudos de aceleraciones (3 ejes) por sensor.
- Se verifican offsets y consistencia de muestreo.

### Fase 1 – Preprocesado
- Corrección de inclinación (desalineación de sensores).
- Filtro pasa-banda (0.2–50 Hz) para eliminar ruido de baja y alta frecuencia.
- Sustracción de componente continua.

### Fase 2 – Segmentación
- División en ventanas móviles si la duración >10 segundos.

### Fase 3 – Tracking de frecuencias
- Estimación espectral (Welch).
- Extracción de frecuencias dominantes y amplitudes.
- Registro en base de datos temporal.

### Fase 4 – Feature Engineering
- RMS, kurtosis, crest factor.
- Energía por bandas.
- Energía Wavelet.
- Normalización.

### Fase 5 – Clasificación
- Entrenamiento de modelos supervisados o clustering no supervisado.
- Predicción de la tipología de cada paso de tren.

### Fase 6 – Visualización
- Series temporales de frecuencias dominantes.
- Matriz de confusión de clasificación.

---

## 4. Instalación y dependencias

Este proyecto utiliza Julia >= 1.8

**Paquetes principales:**
- [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)
- [CSV.jl](https://github.com/JuliaData/CSV.jl)
- [DSP.jl](https://github.com/JuliaDSP/DSP.jl)
- [Wavelets.jl](https://github.com/JuliaDSP/Wavelets.jl)
- [MLJ.jl](https://github.com/alan-turing-institute/MLJ.jl)
- [Rotations.jl](https://github.com/FugroRoames/Rotations.jl)
- [Plots.jl](https://github.com/JuliaPlots/Plots.jl)

Para instalar todas las dependencias:
```julia
using Pkg
Pkg.instantiate()
