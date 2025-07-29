# SMART-BRIDGES-ES

## ✨ Intro al proyecto

**SMART-BRIDGES-ES** (ref. **PLEC2021-007798**) es un proyecto de I+D+i orientado a la **monitorización inteligente del estado estructural de puentes ferroviarios de alta velocidad**. Su objetivo es contribuir al mantenimiento predictivo de estas infraestructuras críticas mediante el uso de sensores MEMS, análisis avanzado de vibraciones y algoritmos de prognosis estructural basados en datos.

España cuenta con más de **2.600 km de líneas de alta velocidad** y más de **200 puentes críticos**, muchos de ellos afectados por procesos de envejecimiento progresivo. Para abordar este reto, SMART-BRIDGES integra:

- **Monitorización estructural inteligente (SHM)** en tiempo real.
- Algoritmos de seguimiento de frecuencias dominantes y clasificación automática de patrones de vibración.
- Creación de **gemelos digitales** que modelan y predicen la evolución del estado estructural.
- Estrategias de **recolección de energía** (*energy harvesting*) para dotar de autonomía al sistema de monitorización.

El proyecto está financiado en el marco del **Programa Estatal de I+D+i Orientada a los Retos de la Sociedad** (Convocatoria 2021) y coordinado por la **Universidad de Córdoba**, en colaboración con la **Universidad de Granada** e **INECO**, ingeniería de referencia del Administrador de Infraestructuras Ferroviarias de España (**ADIF**).

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

SMART-BRIDGES monitoriza puentes ferroviarios de alta velocidad 24/7 mediante acelerómetros MEMS que registran señales tras el paso de trenes. El objetivo es:

- Realizar *tracking* temporal de frecuencias dominantes.
- Clasificar automáticamente cada evento según su tipología dinámica.
- Detectar cambios anómalos y precursores de deterioro estructural.

---

## 2. Estructura del proyecto

La estructura real del proyecto (simplificada) es la siguiente:

```
SMART-BRIDGES-ES/
├── data/                # Datos de entrada
├── plots/               # Gráficas generadas
├── project_check/       # Scripts de verificación y comparativas
├── results/             # Resultados (CSV) organizados por fecha
├── results_check/       # Estadísticas comparativas
├── scripts/             # Scripts en Julia para análisis y KPIs
├── src/                 # Código fuente adicional
├── pipeline.jl          # Pipeline principal del análisis
├── Project.toml         # Configuración del entorno Julia
├── Manifest.toml        # Dependencias exactas del proyecto
└── README.md
```

---

## 3. Flujo de trabajo

### Fase 0 – Ingesta
- Carga de registros crudos de aceleraciones (X, Y, Z) por sensor.

### Fase 1 – Preprocesado
- Corrección de inclinación.
- Filtro pasa-banda (0.2–50 Hz).
- Sustracción de componente continua.

### Fase 2 – Segmentación
- División en ventanas móviles (>10 segundos).

### Fase 3 – Tracking de frecuencias
- Estimación espectral (Welch).
- Extracción de frecuencias dominantes y amplitudes.

### Fase 4 – Feature Engineering
- RMS, kurtosis, energía por bandas, wavelets.

### Fase 5 – Clasificación
- Modelos supervisados y no supervisados para tipologías dinámicas.

### Fase 6 – Visualización
- Gráficas temporales y reportes.

---

## 4. Instalación y dependencias

Este proyecto utiliza **Julia >= 1.8**.

Instalar dependencias:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

---

## 5. Scripts disponibles

- `pipeline.jl`: pipeline completo de procesamiento.
- `scripts/main.jl`: ejecución central.
- `scripts/estadisticas_XYZ.jl`: cálculo de estadísticas por eje.
- `scripts/extraer_KPIs.jl`: extracción de indicadores clave.
- `scripts/graficas.jl`: generación de gráficos.
- `scripts/firmas_pasos.jl`: análisis de firmas dinámicas.

---

## 6. Organización de datos

- **data/**: datos de entrada.
- **results/**: resultados en CSV por fecha.
- **plots/**: gráficas de señales y KPIs.
- **results_check/**: comparativas y análisis adicionales.

---

## 7. Contribución
Pull requests son bienvenidos. Para cambios mayores, por favor abre un issue primero para discutir lo que quieres cambiar.

---

## 8. Licencia
Este proyecto está bajo licencia **privativa**: los datos son confidenciales y **no se permite su uso ni redistribución sin autorización expresa del consorcio del proyecto**.
