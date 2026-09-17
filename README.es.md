# 🌳 SkillTreeAutoLoad

**Recupera tu Skill Tree con un solo clic.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Servidor Ebonhold](https://img.shields.io/badge/Servidor-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Última versión](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=versión)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Licencia](https://img.shields.io/badge/Licencia-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Cada run te hace más fuerte, pero el árbol siempre hay que reconstruirlo. SkillTreeAutoLoad
recuerda tu Skill Tree tal y como está. En cuanto tengas suficientes Soul Ashes, un solo clic
devolverá cada nodo a su lugar. Dedica tu tiempo a jugar, no a repetir los mismos clics.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | **Español**

---

## Índice

- [🔥 Por qué este addon](#-por-qué-este-addon)
- [✨ Funciones](#-funciones)
- [📋 Requisitos](#-requisitos)
- [💾 Instalación](#-instalación)
- [🚀 Primeros pasos](#-primeros-pasos)
- [🧭 El panel](#-el-panel)
- [👁 Previsualizar un guardado](#-previsualizar-un-guardado)
- [🔄 Activar un guardado](#-activar-un-guardado)
- [📂 Tus guardados](#-tus-guardados)
- [💡 Conviene saber](#-conviene-saber)
- [🧱 Anatomía del código](#-anatomía-del-código)
- [🌍 Idiomas](#-idiomas)
- [📜 Licencia](#-licencia)
- [🙏 Créditos](#-créditos)

---

## 🔥 Por qué este addon

Reconstruir el Skill Tree a mano significa buscar cientos de nodos y seleccionarlos uno a uno,
sin equivocarte de rango. Una tarea repetitiva que te aparta del juego sin necesidad.

SkillTreeAutoLoad guarda el árbol cuando está a tu gusto y recupera esa configuración cuando
la necesitas, incluidos todos los nodos y rangos.

## ✨ Funciones

| | |
|---|---|
| 💾 | **Guarda el árbol tal y como está** — crea tantos guardados con nombre como quieras |
| 🖱 | **Recupera un guardado con un clic** — cada nodo se selecciona en el rango correcto |
| ⚡ | **Elige una activación completa o progresiva para cada guardado** — espera al coste total o gasta ahora lo que tengas disponible |
| 👁 | **Previsualiza un guardado directamente en el árbol** — los nodos que faltan se resaltan y encuadran al pasar el cursor |
| 📊 | **Consulta el progreso de un vistazo** — cada fila se rellena según las Soul Ashes ya invertidas |
| 📁 | **Organiza tus guardados en grupos** — renómbralos, muévelos o elimínalos fácilmente |
| 💰 | **Consulta el coste en Soul Ashes en tiempo real** — la cantidad que falta aparece al pasar el cursor |
| 🪟 | **Usa un panel compacto y plegable** — colócalo dentro del Skill Tree o junto a la ventana |
| 👥 | **Usa tus guardados en toda la cuenta** — todos tus personajes comparten la misma lista |
| 🌍 | **Disfruta de cuatro idiomas** — el addon sigue automáticamente el idioma del cliente |

## 📋 Requisitos

| | |
|---|---|
| **Juego** | World of Warcraft 3.3.5a en el servidor **Ebonhold** |
| **Integración** | ProjectEbonhold, incluido con el cliente Ebonhold; no requiere ningún addon adicional |

## 💾 Instalación

1. Descarga el último archivo desde la [página de Releases](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extrae la carpeta `SkillTreeAutoLoad` dentro de `Interface/AddOns/` de tu cliente Ebonhold.
3. Reinicia el juego y abre el Skill Tree: el panel aparece a su lado.

> [!IMPORTANT]
> Tras la instalación, reinicia el juego por completo. Un simple `/reload` no basta, y tus
> guardados no se conservarían.

## 🚀 Primeros pasos

1. Abre el Skill Tree y selecciona los nodos que quieras, como siempre.
2. Pulsa **`...`** arriba a la derecha del panel, elige **Nuevo guardado** y ponle un nombre.
3. Cuando tengas que reconstruir el árbol, pulsa **Activar** junto al guardado: los nodos
   volverán a quedar como los habías guardado.
4. Pulsa **Apply Changes** en ProjectEbonhold para enviar los cambios al servidor.

> [!NOTE]
> Abre el Skill Tree al menos una vez por sesión antes de activar un guardado. El addon necesita
> leer primero su estado actual.

## 🧭 El panel

El panel se muestra y se oculta junto con la ventana del Skill Tree.

| Control | Qué hace |
|---|---|
| **`<>`** (arriba a la izquierda) | Mueve el panel al otro lado de la ventana. Su posición queda guardada. |
| **`-` / `+`** (arriba a la izquierda) | Pliega el panel en una pestaña o vuelve a desplegarlo. |
| **`...`** (arriba a la derecha) | Crea guardados o grupos y controla el modo compacto y el encuadre automático. |
| **Cabecera de grupo** (clic derecho) | Permite renombrar o eliminar el grupo. Sus guardados vuelven a *Sin categoría*. |
| **Activar** (en una fila) | Recupera el guardado en el árbol mostrado. |
| **Progresivo · SÍ/NO** (en una fila) | Elige el modo de activación de ese guardado. El ajuste queda guardado. |
| **`...`** (en una fila) | Permite renombrar, mover, actualizar o eliminar el guardado. |
| **Fila de un guardado** (al pasar el cursor) | Muestra el progreso y el coste, resalta los nodos que faltan y previsualiza su posición. |

De forma predeterminada, el panel aparece junto al Skill Tree. El **modo compacto** lo coloca
sobre el borde interior del árbol y vuelve a centrar la zona útil a su alrededor. El panel se
puede plegar en ambos modos; su lado, su estado y sus opciones de visualización quedan guardados.

Cada fila muestra el estado del guardado:

- 🟢 **Activo** — todos los nodos del guardado ya están seleccionados.
- 🟡 En **modo completo**, **`Nodos: N — Coste: X Soul Ashes`** muestra todo lo que aún falta.
- 🟡 En **modo progresivo**, la fila muestra lo que puede activar el siguiente clic o cuántas
  Soul Ashes faltan para el siguiente nodo disponible.
- El relleno de la fila representa el progreso total según las Soul Ashes ya invertidas, no
  solo según el número de nodos completados.

El coste se actualiza automáticamente cuando cambia tu saldo de Soul Ashes. Así sabrás al
instante cuándo puedes activar un guardado.

## 👁 Previsualizar un guardado

Pasa el cursor por un guardado para ver directamente en el Skill Tree los nodos que le faltan.
En modo completo, todos aparecen resaltados en ámbar. En modo progresivo, los nodos que puede
activar el siguiente clic aparecen en verde, mientras que los posteriores permanecen en ámbar.

El addon desplaza y amplía suavemente la vista para encuadrar la parte relevante del árbol y
restaura tu vista anterior cuando abandonas el panel. Unas flechas indican cuántos nodos del
guardado permanecen fuera de la zona visible. Puedes desactivar el movimiento automático con
**Encuadrar el árbol al pasar el cursor** en el menú del panel; los resaltados seguirán visibles.

## 🔄 Activar un guardado

Cada guardado tiene su propio modo de activación, que se elige con el control
**Progresivo · SÍ/NO**.

### Modo completo

Es el modo predeterminado. **Activar** permanece deshabilitado hasta que puedas pagar todos los
nodos y rangos que faltan. Un solo clic restaura entonces toda la configuración.

### Modo progresivo

El modo progresivo permite avanzar hacia un guardado costoso a lo largo de varios runs. Cada
clic gasta todo lo que permita tu saldo actual, eligiendo siempre el rango disponible más barato
y respetando los requisitos del árbol. Si todavía no se puede activar nada, la fila muestra la
cantidad que falta para alcanzar el siguiente nodo disponible.

Después de una activación en cualquiera de los dos modos, un mensaje del chat resume los nodos
añadidos y las Soul Ashes gastadas. Pulsa **Apply Changes** en ProjectEbonhold para confirmar el
resultado.

- ✅ **Nunca se elimina un nodo ya seleccionado.** La activación solo añade los nodos que
  faltan.
- 💰 **El coste se muestra de antemano.** En modo completo, el botón permanece atenuado mientras
  el saldo sea insuficiente; en modo progresivo, se habilita cuando se puede pagar al menos un
  rango.
- 🔁 **Tu saldo de Soul Ashes se actualiza inmediatamente**, sin recargar la interfaz.

## 📂 Tus guardados

Los guardados pertenecen a tu **cuenta**: todos tus personajes comparten la misma lista.

Si utilizabas una versión anterior a la 1.5, tus guardados estaban vinculados a cada personaje.
Se transfieren automáticamente a la cuenta cuando ese personaje inicia sesión por primera vez.
No se sobrescribe nada: los guardados idénticos se omiten y los que comparten nombre pero no
contenido se añaden como `Nombre (Personaje)`.

> [!NOTE]
> Crear, renombrar, mover o eliminar un guardado recarga la interfaz. Es intencionado: el juego
> escribe entonces los datos en el disco para protegerlos frente a un cierre inesperado.

## 💡 Conviene saber

- **Los nodos de elección múltiple no se guardan.** El addon te avisa una vez por sesión cuando
  encuentra uno.
- **Los nodos infinitos siguen siendo elecciones manuales.** No se incluyen en los guardados,
  pero sus rangos actuales y su coste en Soul Ashes sí se tienen en cuenta al calcular tu saldo.
- **Los nodos permanentes nunca se modifican.** Un guardado solo contiene las elecciones que
  tú mismo has realizado.
- **Se avisa de los nodos que no aparecen en el árbol mostrado.** No se pueden resaltar,
  encuadrar ni activar hasta que estén disponibles en el árbol actual.
- **Actualizar un guardado no puede reducirlo sin avisar.** Si el árbol actual contiene menos
  nodos que el guardado existente, el addon pide confirmación antes de reemplazarlo.
- **No se comparte ni se exporta ningún dato.** Tus guardados permanecen en tu ordenador y no
  se genera ningún código de build.

## 🧱 Anatomía del código

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   metadatos y orden de carga
├── init.lua                espacio de nombres, colores, mensajes de chat
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            lectura del árbol, cálculo del coste, aplicación de un guardado
    ├── plan.lua            cálculo del progreso y planificación de la activación progresiva
    ├── overlay.lua         marcadores de color sobre los nodos del Skill Tree
    ├── view.lua            encuadre de la vista previa, transiciones y flechas fuera de pantalla
    ├── data.lua            guardados, grupos, almacenamiento de cuenta y migración
    ├── bridge.lua          diálogo con el servidor
    ├── menus.lua           menús desplegables y ventanas emergentes
    ├── ui.lua              disposición del panel, filas y controles de activación
    └── main.lua            arranque
```

## 🌍 Idiomas

🇬🇧 Inglés · 🇫🇷 Francés · 🇩🇪 Alemán · 🇪🇸 Español

El addon sigue automáticamente el idioma de tu cliente de juego.

## 📜 Licencia

SkillTreeAutoLoad es gratuito y seguirá siéndolo. Se publica bajo la
[PolyForm Strict License 1.0.0](LICENSE.md): puedes utilizarlo con fines no comerciales, pero
**no venderlo, modificarlo ni redistribuirlo**. Esto incluye publicarlo en un sitio de addons,
incluirlo en un paquete o distribuir una versión modificada. Para cualquier otro uso, solicita
permiso primero.

## 🙏 Créditos

Addon creado por **Siphelis**.
Desarrollado para ProjectEbonhold, la interfaz de cliente del servidor Ebonhold.
