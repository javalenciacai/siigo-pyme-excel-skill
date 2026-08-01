# Skills.sh — Registro del skill

Esta nota describe cómo registrar `siigo-pyme-excel` en
[skills.sh](https://skills.sh/) una vez que el repo esté público.

## Pasos

1. **Confirma que el repo cumple los requisitos de skills.sh**:
   - Repo público en GitHub.
   - Existe `skill/SKILL.md` (o `SKILL.md` en la raíz) con frontmatter
     YAML válido (`name` + `description`).
   - El frontmatter `description` empieza con un verbo o resume el
     propósito en una línea.

2. **Sube el tag inicial**:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. **Regístralo en skills.sh** siguiendo su flujo (suele ser un PR al
   índice público o un comando web). Consulta la doc oficial vigente:
   - https://skills.sh/docs (cuando esté disponible)
   - o el README del propio sitio.

4. **Verifica el renderizado** abriendo la URL pública del skill y
   comprobando que:
   - Aparece la descripción del frontmatter.
   - Los links a `references/` y `scripts/` funcionan.
   - El comando de instalación (`npx skills add ...` o similar) está
     visible.

## Snippet para el índice (ajustar al formato vigente)

```yaml
- name: siigo-pyme-excel
  repo: <TU-USUARIO>/siigo-pyme-excel-skill
  description: >-
    Automatiza ExcelSIIGO.exe (CLI de SIIGO Pyme Colombia) para extraer
    (GET*) e importar (PUSH*) datos entre SIIGO Pyme y archivos Excel.
  tags: [siigo, pyme, colombia, excel, accounting, cli, windows]
  install: npx skills add <TU-USUARIO>/siigo-pyme-excel-skill
```

## Verificación local del frontmatter

Antes de publicar:

```bash
python -c "import yaml,sys; d=yaml.safe_load(open('skill/SKILL.md').read().split('---')[1]); print('name:',d.get('name')); print('description[:80]:',(d.get('description') or '')[:80])"
```

Debe imprimir algo como:
```
name: siigo-pyme-excel
description[:80]: Automatiza ExcelSIIGO.exe (CLI de SIIGO Pyme Colombia) para extraer (GET*
```

## Limitaciones a declarar en skills.sh

- **Windows only**. El CLI es PE32 nativo. En otros SOs requiere Wine
  o ejecución remota.
- **Requiere SIIGO Pyme con licencia**. El usuario debe tener el
  software instalado y licenciado.
- **Operaciones PUSH son destructivas**: importan datos a la base
  SIIGO. El wrapper pide confirmación por defecto.
