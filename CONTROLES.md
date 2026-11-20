# Base de movimiento: Brackeys ProtoController

Origen: https://github.com/Brackeys/brackeys-proto-controller
Licencia: CC0 (incluida en addons/proto_controller/LICENSE).

Los archivos oficiales estan en addons/proto_controller.
player.tscn hereda esa escena y configura el personaje del juego.

Controles:
- WASD: caminar.
- Mouse: mirar.
- Espacio: saltar.
- Shift: correr.
- Clic izquierdo: disparar (un tiro por clic, municion ilimitada).
- Escape: liberar el mouse.
- Con el mouse liberado, el primer clic lo captura sin disparar.

El mouse se captura al iniciar y se libera al cambiar de ventana.
El arma incluye mira central, retroceso visual, sonido, fogonazo e impactos.
Los disparos salen hacia el centro de la camara y respetan paredes y cobertura
delante del canon. Los blancos azules reciben 25 de dano por tiro y reaparecen
1,5 segundos despues de recibir cuatro impactos.

Para ajustar dano, alcance, cadencia y capas de colision, seleccionar Weapon
en Player > Head > Camera3D. Para que un enemigo reciba dano, agregarle un
metodo `take_damage(amount: float)` a su cuerpo o a un nodo padre.

Pruebas desde la carpeta del proyecto con Godot 4.7:
`godot --headless --path . --script res://verify_integration.gd`
`godot --path . --script res://verify_shooting.gd`
La prueba de disparo abre una ventana porque verifica la captura real del mouse.

Ajustar velocidad y sensibilidad desde el nodo Player de player.tscn.
El personaje tiene top_level activado porque Main esta rotado y escalado.
La posicion de aparicion se conserva desde la escena main.tscn del proyecto original.
Los scripts anteriores quedan conservados, pero ya no se usan en Player.
fps_player.gd extiende el controlador original para integrar captura del mouse
y disparos sin modificar los archivos oficiales de Brackeys.
