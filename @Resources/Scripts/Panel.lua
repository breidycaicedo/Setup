-- =====================================================================
--  Panel.lua
--  Dibuja los anillos (RAM, CPU, bateria, progreso), las pildoras de
--  volumen y brillo, el zoom de las apps y maneja la musica.
--  Todo lo que se mueve pasa por una animacion suave que solo corre
--  cuando algo cambia.
-- =====================================================================

local S = 1
local medidas = {}

-- Estados guardados para no repetir bangs si nada cambio
local musicaActiva = nil
local sonandoAntes = nil
local portadaAntes = nil
local cargandoAntes = nil
local tooltipAntes = nil

-- Valores que se ven en pantalla (animados) y valores a los que van
local mostrado = { ram = 0, cpu = 0, bat = 0, vol = 0, brillo = 0, dia = 0, mes = 0, ano = 0 }
local objetivo = { ram = 0, cpu = 0, bat = 0, vol = 0, brillo = 0, dia = 0, mes = 0, ano = 0 }
local ramTotalGB = 0
local colorBateria = '52,199,89,255'

-- Brillo: false = no se pudo leer (por ejemplo, monitor externo)
local hayBrillo = false
local brilloPendiente = nil

-- Apps: centro de cada mosaico y medidores que se agrandan juntos
local MOSAICOS = {
  App1 = { cx = 46, cy = 46, medidores = { 'App1', 'App1Icono' } },
  App2 = { cx = 122, cy = 46, medidores = { 'App2', 'App2Dia', 'App2Num' } },
  App3 = { cx = 198, cy = 46, medidores = { 'App3', 'App3Icono' } },
  App4 = { cx = 274, cy = 46, medidores = { 'App4', 'App4Icono' } },
  App5 = { cx = 46, cy = 122, medidores = { 'App5', 'App5Icono' } },
  App6 = { cx = 122, cy = 122, medidores = { 'App6', 'App6Icono' } },
  App7 = { cx = 198, cy = 122, medidores = { 'App7', 'App7Icono' } },
  App8 = { cx = 274, cy = 122, medidores = { 'App8', 'App8Icono' } }
}
local ESCALA_HOVER = 1.08
local ESCALA_CLIC = 0.92

-- Animacion
local SUAVIDAD = 0.2
local animando = false

-- Colores
local BLANCO = '245,245,247,255'
local VERDE = '52,199,89,255'
local ROJO = '255,69,58,255'
local ROSA = '255,55,95,255'
local LIMA = '166,255,0,255'
local CIAN = '0,215,255,255'
local ICONO_OSCURO = '45,45,52,255'
local ICONO_CLARO = '200,200,206,255'

-- Medidas de las pildoras de volumen y brillo
local PILDORA_ANCHO = 44
local PILDORA_ALTO = 114

-- ---------------------------------------------------------------------
--  Utilidades
-- ---------------------------------------------------------------------

local function limitar(v, minimo, maximo)
  if v < minimo then
    return minimo
  end
  if v > maximo then
    return maximo
  end
  return v
end

local function redondear(v)
  return math.floor(v + 0.5)
end

-- Numero con decimales y punto, sin depender del idioma de Windows
local function num(x, decimales)
  decimales = decimales or 2
  local factor = 10 ^ decimales
  local negativo = x < 0
  local n = math.floor(math.abs(x) * factor + 0.5)
  local entero = math.floor(n / factor)
  local resto = n - entero * factor
  local texto = string.format('%d', entero)
  if decimales > 0 then
    texto = texto .. '.' .. string.format('%0' .. decimales .. 'd', resto)
  end
  if negativo then
    texto = '-' .. texto
  end
  return texto
end

local function valor(nombre)
  local m = medidas[nombre]
  if m == nil then
    return 0
  end
  return m:GetValue()
end

local function cadena(nombre)
  local m = medidas[nombre]
  if m == nil then
    return ''
  end
  local s = m:GetStringValue()
  if s == nil then
    return ''
  end
  return s
end

local function poner(seccion, opcion, contenido)
  SKIN:Bang('!SetOption', seccion, opcion, contenido)
end

local function mostrar(grupo, visible)
  if visible then
    SKIN:Bang('!ShowMeterGroup', grupo)
  else
    SKIN:Bang('!HideMeterGroup', grupo)
  end
end

local function mostrarMedidor(nombre, visible)
  if visible then
    SKIN:Bang('!ShowMeter', nombre)
  else
    SKIN:Bang('!HideMeter', nombre)
  end
end

-- Acerca un valor a su meta. Devuelve el nuevo valor y si todavia se mueve.
local function acercar(actual, meta)
  local diferencia = meta - actual
  if math.abs(diferencia) < 0.002 then
    return meta, false
  end
  return actual + diferencia * SUAVIDAD, true
end

-- ---------------------------------------------------------------------
--  Dibujo
-- ---------------------------------------------------------------------

-- Arco de anillo que empieza arriba y avanza en sentido horario (p de 0 a 1)
local function arco(cx, cy, r, p, ancho, color)
  p = limitar(p, 0.002, 0.999)
  local inicio = -math.pi / 2
  local fin = inicio + 2 * math.pi * p
  local grande = 0
  if p > 0.5 then
    grande = 1
  end
  local x0 = cx + r * math.cos(inicio)
  local y0 = cy + r * math.sin(inicio)
  local x1 = cx + r * math.cos(fin)
  local y1 = cy + r * math.sin(fin)
  return 'Arc ' .. num(x0) .. ',' .. num(y0) .. ',' .. num(x1) .. ',' .. num(y1) .. ','
    .. num(r) .. ',' .. num(r) .. ',0,0,' .. grande .. ',0'
    .. ' | StrokeWidth ' .. num(ancho)
    .. ' | Stroke Color ' .. color
    .. ' | Fill Color 0,0,0,0'
    .. ' | StrokeStartCap Round | StrokeEndCap Round'
end

local function anillo(medidor, p, color)
  poner(medidor, 'Shape', arco(69 * S, 69 * S, 46 * S, p, 10 * S, color))
end

local function pildora(relleno, icono, p)
  local alto = PILDORA_ALTO * limitar(p, 0, 1)
  if alto < 1 then
    poner(relleno, 'Shape', 'Rectangle 0,0,1,1 | Fill Color 0,0,0,0 | StrokeWidth 0')
  else
    poner(relleno, 'Shape', 'Rectangle 0,' .. num((PILDORA_ALTO - alto) * S) .. ','
      .. num(PILDORA_ANCHO * S) .. ',' .. num(alto * S)
      .. ' | Fill Color ' .. BLANCO .. ' | StrokeWidth 0')
  end
  local colorIcono = ICONO_CLARO
  if alto > 34 then
    colorIcono = ICONO_OSCURO
  end
  poner(icono, 'FontColor', colorIcono)
end

local function dibujarAnillos()
  anillo('ArcoRAM', mostrado.ram, BLANCO)
  poner('TxtRAM', 'Text', num(mostrado.ram * ramTotalGB, 1) .. 'G')

  anillo('ArcoCPU', mostrado.cpu, BLANCO)
  poner('TxtCPU', 'Text', redondear(mostrado.cpu * 100) .. '%')

  anillo('ArcoBateria', mostrado.bat, colorBateria)
  poner('TxtBateria', 'Text', redondear(mostrado.bat * 100) .. '%')

  poner('ArcosProgreso', 'Shape', arco(69 * S, 69 * S, 52 * S, mostrado.dia, 11 * S, ROSA))
  poner('ArcosProgreso', 'Shape2', arco(69 * S, 69 * S, 38 * S, mostrado.mes, 11 * S, LIMA))
  poner('ArcosProgreso', 'Shape3', arco(69 * S, 69 * S, 24 * S, mostrado.ano, 11 * S, CIAN))
end

local function dibujarControles()
  pildora('RellenoVol', 'IconoVol', mostrado.vol)
  pildora('RellenoBrillo', 'IconoBrillo', mostrado.brillo)
end

local function dibujarMosaico(nombre)
  local m = MOSAICOS[nombre]
  local s = m.escala
  local matriz = num(s, 4) .. ';0;0;' .. num(s, 4) .. ';'
    .. num(m.cx * S * (1 - s)) .. ';' .. num(m.cy * S * (1 - s))
  for i = 1, #m.medidores do
    poner(m.medidores[i], 'TransformationMatrix', matriz)
  end
end

-- Avanza un cuadro de animacion. Devuelve true si algo se sigue moviendo.
local function avanzar()
  local sigue = false
  local anillosCambian = false
  local controlesCambian = false
  local seMueve = false

  for _, clave in ipairs({ 'ram', 'cpu', 'bat', 'dia', 'mes', 'ano' }) do
    if mostrado[clave] ~= objetivo[clave] then
      mostrado[clave], seMueve = acercar(mostrado[clave], objetivo[clave])
      anillosCambian = true
      sigue = sigue or seMueve
    end
  end
  for _, clave in ipairs({ 'vol', 'brillo' }) do
    if mostrado[clave] ~= objetivo[clave] then
      mostrado[clave], seMueve = acercar(mostrado[clave], objetivo[clave])
      controlesCambian = true
      sigue = sigue or seMueve
    end
  end
  for nombre, m in pairs(MOSAICOS) do
    if m.escala ~= m.meta then
      m.escala, seMueve = acercar(m.escala, m.meta)
      dibujarMosaico(nombre)
      sigue = sigue or seMueve
    end
  end

  if anillosCambian then
    dibujarAnillos()
  end
  if controlesCambian then
    dibujarControles()
  end
  return sigue
end

local function animar()
  if not animando then
    animando = true
    SKIN:Bang('!CommandMeasure', 'mAnimar', 'Execute 1')
  end
end

-- ---------------------------------------------------------------------
--  Rainmeter
-- ---------------------------------------------------------------------

function Initialize()
  S = tonumber(SKIN:GetVariable('S')) or 1
  local nombres = {
    'mCPU', 'mRAM', 'mRAMTotal', 'mBateria', 'mCargando', 'mVolumen',
    'mTitulo', 'mPortada', 'mEstado', 'mBrilloLeer'
  }
  for i = 1, #nombres do
    medidas[nombres[i]] = SKIN:GetMeasure(nombres[i])
  end
  for _, m in pairs(MOSAICOS) do
    m.escala = 1
    m.meta = 1
  end
end

function Update()
  -- RAM
  local total = valor('mRAMTotal')
  ramTotalGB = total / 1073741824
  if total > 0 then
    objetivo.ram = limitar(valor('mRAM') / total, 0, 1)
  end

  -- CPU
  objetivo.cpu = limitar(valor('mCPU') / 100, 0, 1)

  -- Bateria
  objetivo.bat = limitar(valor('mBateria') / 100, 0, 1)
  local cargando = valor('mCargando') == 1
  colorBateria = VERDE
  if objetivo.bat <= 0.2 and not cargando then
    colorBateria = ROJO
  end
  if cargando ~= cargandoAntes then
    mostrar('Cargando', cargando)
    mostrar('Descargando', not cargando)
    cargandoAntes = cargando
  end

  -- Progreso del dia, del mes y del ano
  local t = os.date('*t')
  local pDia = (t.hour * 3600 + t.min * 60 + t.sec) / 86400
  local diasMes = os.date('*t', os.time({ year = t.year, month = t.month + 1, day = 0, hour = 12 })).day
  local diasAno = 365
  if (t.year % 4 == 0 and t.year % 100 ~= 0) or t.year % 400 == 0 then
    diasAno = 366
  end
  objetivo.dia = pDia
  objetivo.mes = ((t.day - 1) + pDia) / diasMes
  objetivo.ano = ((t.yday - 1) + pDia) / diasAno
  -- "Dia", "Ano" con tilde y enie en UTF-8
  local tooltip = 'D\195\173a ' .. redondear(objetivo.dia * 100) .. '%   Mes ' .. redondear(objetivo.mes * 100)
    .. '%   A\195\177o ' .. redondear(objetivo.ano * 100) .. '%'
  if tooltip ~= tooltipAntes then
    poner('ArcosProgreso', 'ToolTipText', tooltip)
    tooltipAntes = tooltip
  end

  -- Volumen (-1 significa silenciado)
  local v = valor('mVolumen')
  if v < 0 then
    v = 0
  end
  objetivo.vol = limitar(v / 100, 0, 1)

  -- Musica (0 = detenida, 1 = sonando, 2 = en pausa)
  local estado = valor('mEstado')
  local titulo = cadena('mTitulo')
  local activa = titulo ~= '' and estado ~= 0
  if activa ~= musicaActiva then
    mostrar('Sonando', activa)
    mostrar('Inactivo', not activa)
    musicaActiva = activa
  end
  local sonando = estado == 1
  if sonando ~= sonandoAntes then
    mostrarMedidor('BtnPausa', sonando)
    mostrarMedidor('BtnPlay', not sonando)
    sonandoAntes = sonando
  end
  local hayPortada = activa and cadena('mPortada') ~= ''
  if hayPortada ~= portadaAntes then
    mostrarMedidor('Portada', hayPortada)
    portadaAntes = hayPortada
  end

  -- Brillo: se aplica como mucho una vez por segundo
  if brilloPendiente ~= nil then
    SKIN:Bang('!SetVariable', 'Brillo', string.format('%d', brilloPendiente))
    SKIN:Bang('!UpdateMeasure', 'mBrilloPoner')
    SKIN:Bang('!CommandMeasure', 'mBrilloPoner', 'Run')
    brilloPendiente = nil
  end

  -- Si algo cambio, arranca la animacion
  for clave, meta in pairs(objetivo) do
    if mostrado[clave] ~= meta then
      animar()
      break
    end
  end
  dibujarAnillos()
  dibujarControles()
  return 0
end

-- ---------------------------------------------------------------------
--  Animacion (la llama el ActionTimer [mAnimar])
-- ---------------------------------------------------------------------

function Paso()
  local sigue = avanzar()
  SKIN:Bang('!UpdateMeterGroup', 'Anim')
  SKIN:Bang('!Redraw')
  if not sigue then
    animando = false
    SKIN:Bang('!CommandMeasure', 'mAnimar', 'Stop 1')
  end
end

function FinAnimacion()
  animando = false
end

-- ---------------------------------------------------------------------
--  Acciones (las llaman los clics del panel)
-- ---------------------------------------------------------------------

-- estado: 0 = normal, 1 = mouse encima, 2 = presionado
function Hover(nombre, estado)
  local m = MOSAICOS[nombre]
  if m == nil then
    return
  end
  if estado == 1 then
    m.meta = ESCALA_HOVER
  elseif estado == 2 then
    m.meta = ESCALA_CLIC
  else
    m.meta = 1
  end
  animar()
end

-- y = posicion del clic en porcentaje (0 arriba, 100 abajo)
function PonerVolumen(y)
  local v = limitar(redondear(100 - y), 0, 100)
  SKIN:Bang('!CommandMeasure', 'mVolumen', 'SetVolume ' .. v)
  objetivo.vol = v / 100
  animar()
end

function SubirVolumen(paso)
  local v = limitar(redondear(objetivo.vol * 100) + paso, 0, 100)
  SKIN:Bang('!CommandMeasure', 'mVolumen', 'SetVolume ' .. v)
  objetivo.vol = v / 100
  animar()
end

function LeerBrillo()
  local n = tonumber(string.match(cadena('mBrilloLeer'), '%d+'))
  if n ~= nil then
    hayBrillo = true
    objetivo.brillo = limitar(n / 100, 0, 1)
  else
    hayBrillo = false
    objetivo.brillo = 0
  end
  animar()
end

function PonerBrillo(y)
  local v = limitar(redondear(100 - y), 0, 100)
  objetivo.brillo = v / 100
  brilloPendiente = v
  animar()
end

function SubirBrillo(paso)
  local actual = 50
  if hayBrillo then
    actual = redondear(objetivo.brillo * 100)
  end
  local v = limitar(actual + paso, 0, 100)
  hayBrillo = true
  objetivo.brillo = v / 100
  brilloPendiente = v
  animar()
end
