# 🌳 SkillTreeAutoLoad

**Tu Soul Tree, de vuelta en su sitio con un solo clic.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Servidor Ebonhold](https://img.shields.io/badge/Servidor-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Última versión](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=versión)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Licencia](https://img.shields.io/badge/Licencia-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Cada run te hace más fuerte, pero el árbol hay que volver a levantarlo. SkillTreeAutoLoad
guarda tu Soul Tree tal y como está, y en cuanto tienes las Soul Ashes, un clic devuelve cada
nodo al sitio donde lo dejaste. Dedica el tiempo a jugar, no a volver a hacer clic.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | **Español**

---

## Índice

- [🔥 Por qué este addon](#-por-qué-este-addon)
- [✨ Funciones](#-funciones)
- [📋 Requisitos](#-requisitos)
- [💾 Instalación](#-instalación)
- [🚀 Primeros pasos](#-primeros-pasos)
- [🧭 El panel](#-el-panel)
- [🔄 Activar un guardado](#-activar-un-guardado)
- [📂 Tus guardados](#-tus-guardados)
- [💡 Conviene saber](#-conviene-saber)
- [🧱 Anatomía del código](#-anatomía-del-código)
- [🌍 Idiomas](#-idiomas)
- [📜 Licencia](#-licencia)
- [🙏 Créditos](#-créditos)

---

## 🔥 Por qué este addon

Rehacer el Soul Tree a mano significa buscar y pulsar cientos de nodos, uno tras otro, sin
equivocarte de rango. Es el único tramo del juego en el que no pasa nada.

SkillTreeAutoLoad hace una foto del árbol cuando te conviene, y devuelve ese estado exacto
cuando se lo pides — nodos y rangos incluidos.

## ✨ Funciones

| | |
|---|---|
| 💾 | **Fotografía el árbol tal cual está** — tantos guardados como quieras, cada uno con su nombre |
| 🖱 | **Un clic para recuperar uno** — cada nodo se vuelve a seleccionar por ti, en su rango correcto |
| 📁 | **Grupos** para tener tus guardados ordenados, con renombrar, mover y eliminar |
| 💰 | **Coste en Soul Ashes en directo**, actualizado según ganas, con lo que falta exacto al pasar el cursor |
| 👥 | **Compartidos por toda la cuenta** — todos tus personajes ven la misma lista |
| 🌍 | **Cuatro idiomas**, según tu cliente de juego |

## 📋 Requisitos

| | |
|---|---|
| **Juego** | World of Warcraft 3.3.5a en el servidor **Ebonhold** |
| **Dependencia** | Ninguna |

## 💾 Instalación

1. Descarga el último archivo desde la [página de Releases](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extrae la carpeta `SkillTreeAutoLoad` dentro de `Interface/AddOns/` de tu cliente Ebonhold.
3. Reinicia el juego y abre el Soul Tree: el panel aparece a su lado.

> [!IMPORTANT]
> Tras la instalación, reinicia el juego por completo. Un simple `/reload` no basta, y tus
> guardados no se conservarían.

## 🚀 Primeros pasos

1. Abre el Soul Tree y selecciona los nodos que quieras, como siempre.
2. Pulsa **`...`** arriba a la derecha del panel → **Nuevo guardado**, y ponle nombre.
3. Más tarde, cuando haya que rehacer el árbol y tengas las Soul Ashes, pulsa **Activar** en
   esa fila: queda restaurado tal y como lo dejaste.
4. Pulsa **Apply Changes** de ProjectEbonhold para enviarlo al servidor.

> [!NOTE]
> Abre el Soul Tree una vez por sesión antes de activar un guardado: el addon necesita verlo
> abrirse para saber cómo estás.

## 🧭 El panel

El panel se muestra y se oculta junto con la ventana Soul Tree.

| Control | Qué hace |
|---|---|
| **`<>`** (arriba a la izquierda) | Pasa el panel al otro lado de la ventana. Se recuerda. |
| **`...`** (arriba a la derecha) | Menú del panel: **Nuevo guardado** (captura el árbol tal cual), **Nuevo grupo** |
| **Cabecera de grupo** (clic derecho) | Renombrar o eliminar el grupo. Sus guardados vuelven a *Sin categoría* |
| **Activar** (en una fila) | Devuelve el guardado al árbol en pantalla |
| **`...`** (en una fila) | **Renombrar** · **Mover a un grupo** · **Actualizar (estado actual)** · **Eliminar** |

Cada fila te dice cómo estás:

- 🟢 **Activo** — el guardado ya está completamente seleccionado, no hay nada que hacer.
- 🟡 **`N nodo(s) — X Soul Ashes`** — lo que añadiría devolverlo y lo que costaría.
- El botón **Activar** permanece atenuado mientras no puedas permitírtelo. Pasa el cursor por
  la fila para ver exactamente cuánto te falta.

La línea de coste se actualiza sola conforme cambian tus Soul Ashes: ves cómo un guardado se
pone a tu alcance mientras juegas.

## 🔄 Activar un guardado

Un clic en **Activar** y el árbol se rellena: cada nodo del guardado se vuelve a seleccionar, en
su rango correcto. El chat te dice qué se ha colocado y cuánto ha costado. Solo queda pulsar
**Apply Changes**.

- ✅ **No se te quita nada de lo que tenías.** Activar solo añade: los nodos que ya posees se
  quedan donde están, pase lo que pase.
- 💰 **El coste se anuncia de antemano** y el botón sigue atenuado mientras no puedas pagarlo
  — sin sorpresas desagradables.
- 🔁 Tu saldo de Soul Ashes se corrige solo justo después, sin recargar la interfaz.

## 📂 Tus guardados

Pertenecen a la **cuenta**: todos tus personajes ven la misma lista, y lo que guardas en uno
aparece en los demás.

Si vienes de una versión anterior a la 1.5, tus guardados antiguos estaban ligados a cada
personaje. Se recuperan automáticamente en su primera conexión, y nunca se sobrescribe nada: un
guardado idéntico se omite, y uno con el mismo nombre pero distinto contenido llega como
`Nombre (Personaje)`.

> [!NOTE]
> Crear, renombrar, mover o eliminar un guardado recarga la interfaz. Es intencionado: es el
> único momento en que el juego escribe tus guardados en el disco, así quedan a salvo de un
> cierre inesperado.

## 💡 Conviene saber

- **Los nodos de elección múltiple se ignoran** en los guardados. El addon te avisa una vez por
  sesión cuando encuentra uno.
- **Los nodos permanentes no corren peligro.** Un guardado solo puede contener lo que tú mismo
  elegiste: activarlo nunca toma esa decisión por ti.
- **No se comparte ni se exporta nada.** Tus guardados se quedan contigo; no hay ningún código
  de build que copiar y pegar.

## 🧱 Anatomía del código

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   metadatos y orden de carga
├── init.lua                espacio de nombres, colores, mensajes de chat
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            lectura del árbol, cálculo del coste, aplicación de un guardado
    ├── data.lua            guardados, grupos, almacenamiento de cuenta y migración
    ├── bridge.lua          diálogo con el servidor
    ├── menus.lua           menús desplegables y ventanas emergentes
    ├── ui.lua              el panel en sí
    └── main.lua            arranque
```

## 🌍 Idiomas

🇬🇧 Inglés · 🇫🇷 Francés · 🇩🇪 Alemán · 🇪🇸 Español

El addon sigue automáticamente el idioma de tu cliente de juego.

## 📜 Licencia

SkillTreeAutoLoad es gratuito y lo seguirá siendo. Se publica bajo la
[PolyForm Strict License 1.0.0](LICENSE.md): puedes usarlo con cualquier fin no comercial, pero
**no venderlo, ni modificarlo, ni redistribuirlo** — eso incluye republicarlo en un sitio de
addons, incluirlo en un paquete o hacer circular una copia modificada. Si quieres hacer alguna
de esas cosas, pregunta antes.

## 🙏 Créditos

Addon de **Siphelis**.
Desarrollado sobre ProjectEbonhold, la interfaz de cliente del servidor Ebonhold.
