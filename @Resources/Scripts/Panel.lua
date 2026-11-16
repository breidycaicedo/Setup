-- =====================================================================
--  Panel.lua
--  Dibuja los anillos (RAM, CPU, bateria, progreso) y maneja la musica,
--  el volumen y el brillo del panel.
-- =====================================================================

local S = 1
local medidas = {}

-- Estados guardados para no repetir bangs si nada cambio
local musicaActiva = nil
local sonandoAntes = nil
local portadaAntes = nil
local cargandoAntes = nil
local tooltipAntes = nil

-- Brillo: nil = no se pudo leer (por ejemplo, monitor externo)
local brillo = nil
local brilloPendiente = nil

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

-- Arco de anillo que empieza arriba y avanza en sentido horario.
-- p va de 0 a 1.
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
  local alto = 0
  if p ~= nil then
    alto = PILDORA_ALTO * limitar(p, 0, 1)
  end
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

local function volumenActual()
  local v = valor('mVolumen')
  -- -1 significa silenciado
  if v < 0 then
    return 0
  end
  return limitar(v / 100, 0, 1)
end

local function dibujarControles()
  pildora('RellenoVol', 'IconoVol', volumenActual())
  pildora('RellenoBrillo', 'IconoBrillo', brillo)
end

local function redibujarControles()
  dibujarControles()
  SKIN:Bang('!UpdateMeterGroup', 'Controles')
  SKIN:Bang('!Redraw')
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
end

function Update()
  -- RAM
  local total = valor('mRAMTotal')
  local usada = valor('mRAM')
  local pRAM = 0
  if total > 0 then
    pRAM = usada / total
  end
  anillo('ArcoRAM', pRAM, BLANCO)
  poner('TxtRAM', 'Text', num(usada / 1073741824, 1) .. 'G')

  -- CPU
  local pCPU = limitar(valor('mCPU') / 100, 0, 1)
  anillo('ArcoCPU', pCPU, BLANCO)
  poner('TxtCPU', 'Text', redondear(pCPU * 100) .. '%')

  -- Bateria
  local pBat = limitar(valor('mBateria') / 100, 0, 1)
  local cargando = valor('mCargando') == 1
  local colorBat = VERDE
  if pBat <= 0.2 and not cargando then
    colorBat = ROJO
  end
  anillo('ArcoBateria', pBat, colorBat)
  poner('TxtBateria', 'Text', redondear(pBat * 100) .. '%')
  if cargando ~= cargandoAntes then
    mostrar('Cargando', cargando)
    mostrar('Descargando', not cargando)
    cargandoAntes = cargando
  end

  -- Progreso del dia, del mes y del ano
  local t = os.date('*t')
  local pDia = (t.hour * 3600 + t.min * 60 + t.sec) / 86400
  local diasMes = os.date('*t', os.time({ year = t.year, month = t.month + 1, day = 0, hour = 12 })).day
  local pMes = ((t.day - 1) + pDia) / diasMes
  local diasAno = 365
  if (t.year % 4 == 0 and t.year % 100 ~= 0) or t.year % 400 == 0 then
    diasAno = 366
  end
  local pAno = ((t.yday - 1) + pDia) / diasAno
  poner('ArcosProgreso', 'Shape', arco(69 * S, 69 * S, 52 * S, pDia, 11 * S, ROSA))
  poner('ArcosProgreso', 'Shape2', arco(69 * S, 69 * S, 38 * S, pMes, 11 * S, LIMA))
  poner('ArcosProgreso', 'Shape3', arco(69 * S, 69 * S, 24 * S, pAno, 11 * S, CIAN))
  -- "Dia", "Ano" con tilde y enie en UTF-8
  local tooltip = 'D\195\173a ' .. redondear(pDia * 100) .. '%   Mes ' .. redondear(pMes * 100)
    .. '%   A\195\177o ' .. redondear(pAno * 100) .. '%'
  if tooltip ~= tooltipAntes then
    poner('ArcosProgreso', 'ToolTipText', tooltip)
    tooltipAntes = tooltip
  end

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

  dibujarControles()
  return 0
end

-- ---------------------------------------------------------------------
--  Acciones (las llaman los clics del panel)
-- ---------------------------------------------------------------------

-- y = posicion del clic en porcentaje (0 arriba, 100 abajo)
function PonerVolumen(y)
  local v = limitar(redondear(100 - y), 0, 100)
  SKIN:Bang('!CommandMeasure', 'mVolumen', 'SetVolume ' .. v)
  SKIN:Bang('!UpdateMeasure', 'mVolumen')
  redibujarControles()
end

function SubirVolumen(paso)
  SKIN:Bang('!CommandMeasure', 'mVolumen', 'ChangeVolume ' .. paso)
  SKIN:Bang('!UpdateMeasure', 'mVolumen')
  redibujarControles()
end

function LeerBrillo()
  local n = tonumber(string.match(cadena('mBrilloLeer'), '%d+'))
  if n ~= nil then
    brillo = limitar(n / 100, 0, 1)
  else
    brillo = nil
  end
  redibujarControles()
end

function PonerBrillo(y)
  local v = limitar(redondear(100 - y), 0, 100)
  brillo = v / 100
  brilloPendiente = v
  redibujarControles()
end

function SubirBrillo(paso)
  local actual = 50
  if brillo ~= nil then
    actual = redondear(brillo * 100)
  end
  local v = limitar(actual + paso, 0, 100)
  brillo = v / 100
  brilloPendiente = v
  redibujarControles()
end
