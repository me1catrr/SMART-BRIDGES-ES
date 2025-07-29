using Cascadia
using Dates
using Gumbo
using HTTP
using DotEnv

function descargar_datos(fecha::String, sensores::Vector{String})
    println("🌐 Iniciando descarga de datos para la fecha: $fecha")

    # Convertir la fecha string a objeto Date
    fecha_dt = Date(fecha, "yyyy-mm-dd")

    # Desglosar componentes
    anio = year(fecha_dt)
    mes = lowercase(Dates.monthname(fecha_dt))  # "july", "august", etc.
    dia = day(fecha_dt)

    # Construir la ruta remota con la fecha
    ruta_dia = "Guadiato/raw/$anio/$mes/$dia"
    println("📂 Ruta remota configurada como: $ruta_dia")
    
    # Cargar variables desde .env
    DotEnv.config()

    # URL base
    login_url = "http://217.76.159.153/smartbridges/login"
    base_url = "http://217.76.159.153/smartbridges-data"

    # Leer credenciales desde variables de entorno
    email = ENV["SMARTBRIDGES_EMAIL"]
    password = ENV["SMARTBRIDGES_PASSWORD"]

    # Formulario de login
    form_data = HTTP.Form(["email" => email, "password" => password])
    
    println("🔐 Iniciando sesión...")
    t0 = time()
    response = HTTP.post(login_url, [], form_data)
    response.status != 200 && error("Login fallido")
    cookie = String(HTTP.header(response, "Set-Cookie"))
    println("✅ Sesión iniciada correctamente")

    println("📅 Fecha: $fecha")
    println("🛰️ Sensores a procesar: $(length(sensores))")
    println("   - " * join(sensores, "\n   - "))

    carpeta_base = joinpath("data", "raw", "Guadiato_raw_$fecha")
    mkpath(carpeta_base)

    for (i, sensor) in enumerate(sensores)
        println("\n[$i/$(length(sensores))] 🌐 Revisando sensor: $sensor")
        sensor_url = "$base_url/$ruta_dia/$sensor/"
        archivos = obtener_csvs(sensor_url, cookie)
        if isempty(archivos)
            println("⚠️  No se encontraron archivos CSV para el sensor $sensor")
            continue
        end
        println("📂 Se encontraron $(length(archivos)) archivos CSV para $sensor")
        carpeta_local = joinpath(carpeta_base, sensor)
        mkpath(carpeta_local)
        for (j, archivo) in enumerate(archivos)
            ruta_local = joinpath(carpeta_local, archivo)
            print("   [$j/$(length(archivos))] Descargando $archivo... ")
            descargar_archivo("$sensor_url$archivo", ruta_local, cookie)
        end
    end
    println("\n⏱️  Proceso finalizado en $(round(time() - t0, digits=2)) segundos.")
end

function obtener_csvs(sensor_url::String, cookie::String)
    println("   🌐 Buscando archivos CSV en: $sensor_url")
    response = HTTP.get(sensor_url, ["Cookie" => cookie])
    response.status != 200 && error("❌ Error al acceder: código ", response.status)

    parsed = parsehtml(String(response.body))
    links = eachmatch(Selector("a"), parsed.root)
    archivos = [node.children[1].text for node in links if !isempty(node.children) && occursin(r"\.csv$", node.children[1].text)]
    return archivos
end

function descargar_archivo(url::String, destino::String, cookie::String)
    response = HTTP.get(url, ["Cookie" => cookie])
    if response.status == 200
        open(destino, "w") do f write(f, response.body) end
        println("✅ OK")
    else
        println("❌ Error en descarga: $url")
    end

    println("📦 Ruta remota configurada como: $ruta_dia")
    println("📂 Ruta local configurada como: $destino")
end