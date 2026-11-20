# juego1

Proyecto de juego FPS en 3D desarrollado en Godot. Incluye movimiento en primera persona, disparos y blancos de práctica.

## Abrir y ejecutar

1. Descargar este repositorio desde **Code → Download ZIP** y descomprimirlo, o clonarlo con Git.
2. En Godot 4.7, elegir **Importar** y seleccionar el archivo `project.godot`.
3. Abrir el proyecto y presionar **F5** para ejecutarlo.

Este repositorio contiene el proyecto fuente. Para jugarlo hay que abrirlo en Godot.

## Controles

| Acción | Control |
| --- | --- |
| Caminar | W, A, S, D |
| Mirar | Mouse |
| Saltar | Espacio |
| Correr | Shift |
| Disparar | Clic izquierdo |
| Liberar el mouse | Escape |

Con el mouse liberado, el primer clic lo captura sin disparar. Los blancos reaparecen después de recibir cuatro impactos.

## Créditos

El controlador de movimiento se basa en [Brackeys ProtoController](https://github.com/Brackeys/brackeys-proto-controller), bajo licencia CC0. Su licencia está incluida en `addons/proto_controller/LICENSE`.

Más detalles en [CONTROLES.md](CONTROLES.md).
