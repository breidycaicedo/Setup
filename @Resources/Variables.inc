[Variables]
; =====================================================================
;  AJUSTES DEL SETUP
;  Cambia lo que quieras aqui, guarda y dale "Refrescar" al skin.
;  Colores en formato R,G,B,Transparencia (0 = invisible, 255 = solido)
; =====================================================================

; ---------- Tamano general ----------
; 1 = normal. Si en tu pantalla se ve pequeno, prueba 1.2 o 1.4
S=1

; ---------- Fuentes ----------
Fuente=Poppins
; Windows 11: Segoe Fluent Icons  |  Windows 10: Segoe MDL2 Assets
FuenteIconos=Segoe Fluent Icons

; ---------- Colores del panel ----------
ColorPanel=255,255,255,38
ColorBordePanel=255,255,255,70
ColorTarjeta=16,16,20,215
ColorTexto=245,245,247,255
ColorTextoSuave=150,150,160,255
ColorAcento=255,55,95,255
ColorPista=255,255,255,38

; ---------- Reloj grande ----------
; %I = formato 12 horas  |  %H = formato 24 horas
FormatoHoraReloj=%I
ColorReloj=240,240,245,235
; Hora que sale en la tarjeta de fecha
FormatoHoraTarjeta=%H:%M
Idioma=es-CO

; ---------- Apps (8 accesos directos, estilo iPhone) ----------
; Fondo y Fondo2: los dos colores del degradado (arriba y abajo)
; Color: color del icono
; Icono: codigo del icono de Segoe Fluent Icons (busca "Segoe Fluent Icons" en learn.microsoft.com)
; Accion: programa, URL o protocolo entre ["..."]
; La app 2 es un calendario que muestra el dia de hoy automaticamente.

App1Nombre=Calculadora
App1Icono=[\xE8EF]
App1Fondo=255,179,64,255
App1Fondo2=255,128,0,255
App1Color=255,255,255,255
App1Accion=["calc.exe"]

App2Nombre=Calendario
App2Fondo=255,69,58,255
App2Fondo2=250,250,250,255
App2Color=28,28,30,255
App2Accion=["https://calendar.google.com"]

App3Nombre=Navegador
App3Icono=[\xE774]
App3Fondo=100,210,255,255
App3Fondo2=0,122,255,255
App3Color=255,255,255,255
App3Accion=["https://www.google.com"]

App4Nombre=Word
App4Icono=[\xE8A5]
App4Fondo=125,122,255,255
App4Fondo2=70,60,215,255
App4Color=255,255,255,255
App4Accion=["winword.exe"]

App5Nombre=Ajustes
App5Icono=[\xE713]
App5Fondo=160,160,166,255
App5Fondo2=99,99,104,255
App5Color=255,255,255,255
App5Accion=["ms-settings:"]

App6Nombre=Archivos
App6Icono=[\xE8B7]
App6Fondo=255,220,70,255
App6Fondo2=255,170,0,255
App6Color=255,255,255,255
App6Accion=["explorer.exe"]

App7Nombre=YouTube
App7Icono=[\xE714]
App7Fondo=255,95,85,255
App7Fondo2=215,0,21,255
App7Color=255,255,255,255
App7Accion=["https://www.youtube.com"]

App8Nombre=Spotify
App8Icono=[\xE8D6]
App8Fondo=80,225,115,255
App8Fondo2=25,160,70,255
App8Color=255,255,255,255
App8Accion=["spotify:"]
