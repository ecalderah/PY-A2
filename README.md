# 130 ejercicios de Python

Colección de 130 ejercicios de Python resueltos en un notebook de Jupyter.
Material auxiliar del taller **Scientific Stack**, con el respaldo del grupo
organizado de Economía **Beeconomics**.

## Contenido

- `130_ejercicios_python_beeconomics.ipynb` — notebook con los ejercicios y sus soluciones.

## Cómo trabajarlo

```powershell
cd 130-ejercicios-python-beeconomics
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install jupyter ipykernel numpy pandas matplotlib
code .
```

Abre el `.ipynb` y selecciona como kernel el intérprete `.venv\Scripts\python.exe`.

## Respaldo automático en Git

Al abrir la carpeta en VS Code se lanza en segundo plano `tools/auto-commit.ps1`, que
cada 15 segundos revisa si hay cambios guardados y, cuando el árbol de trabajo queda
estable, hace `commit` y `push` a este repositorio automáticamente.

- Ver el proceso: pestaña **Terminal → Auto-commit (git)** en VS Code.
- Detenerlo: cierra esa terminal (o cierra VS Code).
- Ejecutarlo a mano:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\auto-commit.ps1
  ```
- Solo commits locales, sin push:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\auto-commit.ps1 -SinPush
  ```

Los commits automáticos se marcan como `auto: respaldo YYYY-MM-DD HH:MM:SS`. Puedes
seguir haciendo commits manuales con mensajes descriptivos cuando quieras; el script
solo actúa si encuentra cambios sin registrar.
