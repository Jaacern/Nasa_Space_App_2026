# Rendimiento y presupuesto en Studio — ARES FORGE

Fecha: 14-11-2026
Entorno medido: Roblox Studio en PC (viewport en segundo plano durante ejecución MCP; no se ha medido aún en dispositivo móvil físico ni en cliente publicado).

## 1. Resumen ejecutivo

| Escenario | Enemigos activos | Modelos en `ClientFx` | FPS promedio | FPS mediana | FPS p5 | FPS mínimo | Frame medio / máx | Memoria total (`Stats`) | Instancias / Primitivas |
|---|---|---|---|---|---|---|---|---|---|
| Menú inactivo (línea base) | 0 | 0 | 15,0 | — | — | 14,5 | 66,7 ms / — | 552,5 MB | 58 220 / 1 290 |
| Combate intenso (`t = 700+`) | 92 → 98 | 209 → 215 | 15,0 | 15,0 | 14,6 | 12,4 | 66,7 ms / 80,7 ms | 547,4 MB | 58 215 / 1 286 |

### Hallazgo clave de capado de Studio y pooling
- Incluso en el menú inactivo con `0` enemigos, Roblox Studio en segundo plano limita `RunService.RenderStepped` a **15,0 FPS** (`39` fotogramas en `2,6 s`, `~66,7 ms/frame`).
- Con **92 a 98 enemigos simultáneos** (incluidos los 4 jefes `boss1`, `boss2`, `boss3`, `final`, 6 élites, drones y 34 proyectiles enemigos), el juego sostuvo el mismo techo de **15,0 FPS** (`76` fotogramas en `5,068 s`, `p5 = 14,6 FPS`, peor fotograma puntual `12,4 FPS` / `80,7 ms`) sin incremento de memoria ni proliferación de instancias frente al menú, validando el *object pooling* de `Renderer.luau`.

## 2. Metodología de medición en Roblox Studio

1. Inicio de partida en modo completo (`Cmd:FireServer("debug", "invincible", true)` y `Cmd:FireServer("start", "full")`).
2. Avance del reloj de misión (`Cmd:FireServer("debug", "time", 700)`) y espera activa de `26,4 s` resolviendo pantallas de subida de nivel hasta acumular `>= 90` modelos de enemigos activos en `Workspace.ClientFx`.
3. Ventana de muestreo de `5,068 s` (`76` fotogramas) sobre `RunService.RenderStepped:Wait()`, registrando cada `dt`, estadísticas de `game:GetService("Stats")` y el desglose de `Workspace.ClientFx`.
4. Línea base adicional de `2,6 s` (`39` fotogramas) en el menú principal con `0` enemigos activos para aislar el límite de refresco del viewport en segundo plano.

### Desglose de entidades activas en `Workspace.ClientFx` (inicio → fin de la ventana)
- **Enemigos y drones**: `92 → 98` (`chaser`: 51 → 57, `ranged`: 14, `tank`: 9, `kamikaze`: 6, `elite1`: 2, `elite2`: 2, `elite3`: 2, `boss1`: 1, `boss2`: 1, `boss3`: 1, `final`: 1, más `drone`: 2).
- **Otros objetos en `ClientFx`**: `chest`: 3, `gem`: 10, `shot`: 3, `eshot`: 34, efectos/telegrafías (`other`): 67. Total: `209 → 215`.

## 3. Optimización crítica descubierta (`EditableMesh` + `FixedSize`)

- Durante la primera prueba en Play, construir los 28 assets (81 submallas por material) con `AssetService:CreateEditableMesh()` dinámico agotó el presupuesto de memoria de `EditableMesh` a partir de la novena submalla (`ranged parte 3`: *"Failed to create empty EditableMesh that was requested due to reaching memory budget limits"*).
- Solución aplicada en `game/src/client/MeshFactory.luau`: tras rellenar cada `EditableMesh` temporal `em`, se convierte a inmutable mediante `AssetService:CreateEditableMeshAsync(Content.fromObject(em), { FixedSize = true })` y se llama de inmediato a `em:Destroy()` antes de `AssetService:CreateMeshPartAsync(...)`. Resultado verificado: **28/28 modelos construidos en cliente sin errores**, **0 fallos** y memoria total estable en ~`547–553 MB`.

## 4. Limitaciones y pendiente

- **Sin medición sin capado a 60 FPS**: al estar Roblox Studio en segundo plano a 15 FPS durante la captura, este ensayo verifica que no hubo caída apreciable respecto a la línea base de Studio ni fuga de instancias/memoria con ~98 enemigos, pero **no certifica 60 FPS en móvil o cliente en primer plano**.
- **Recomendación antes de entrega final**: repetir la misma sonda de 5 s con el viewport en primer plano a 60 FPS en PC y en un teléfono de gama media (activando también `Ajustes -> Efectos bajos`).
