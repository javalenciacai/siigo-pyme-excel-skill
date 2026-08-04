# Skills.sh — publicación e indexación

Cómo se publica `siigo-pyme-excel` en [skills.sh](https://skills.sh/) (el
directorio de Agent Skills, CLI [`vercel-labs/skills`](https://github.com/vercel-labs/skills)).

## 1. Layout de discovery (crítico)

El CLI (`npx skills add owner/repo`) **sólo** escanea estas ubicaciones del repo:

- La **raíz**, si contiene `SKILL.md`.
- `skills/` (profundidad 1), más `skills/.curated/`, `skills/.experimental/`,
  `skills/.system/`.
- Directorios de agente (profundidad 2): `.claude/skills/`, `.agents/skills/`,
  `.cline/skills/`, y ~77 rutas más.
- Cualquier otra ruta **solo** con `--full-depth`, o declarada en un manifiesto
  de plugin (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`).

> ⚠️ Una carpeta `skill/` en singular **NO** se descubre. Este repo la usaba
> hasta v0.6.3; desde v0.7.0 el skill vive en `skills/siigo-pyme-excel/`.
> El nombre del directorio coincide con el `name` del frontmatter.

Un `SKILL.md` en un nivel más superficial hace *shadow* de versiones anidadas:
no dupliques el skill en la raíz y en `skills/`.

## 2. Frontmatter

Obligatorio:

- `name` — minúsculas con guiones (`siigo-pyme-excel`).
- `description` — una línea, con los triggers de uso. Mantenerla < 1024 chars.

Opcional reconocido por el CLI:

- `metadata.internal: true` — oculta el skill del discovery normal (requiere
  `INSTALL_INTERNAL_SKILLS=1`). **No usar aquí.**

No inventes campos extra: no se indexan.

Verificación local antes de publicar:

```bash
python -c "import yaml;d=yaml.safe_load(open('skills/siigo-pyme-excel/SKILL.md',encoding='utf-8').read().split('---')[1]);print(d['name'],'|',len(d['description']),'|',list(d.keys()))"
```

Debe imprimir:

```
siigo-pyme-excel | 956 | ['name', 'description']
```

## 3. Publicar

El repo debe ser **público** en GitHub. No hay paquete npm: el registro es
GitHub mismo.

```bash
git push origin main
git tag v0.7.0 && git push origin v0.7.0
```

## 4. Indexación: sólo por telemetría de instalación

**No existe formulario ni PR de registro en skills.sh.** El catálogo se puebla
cuando alguien instala el skill con el CLI; las auditorías de seguridad se
generan tras la primera instalación. Para que el skill aparezca hay que
instalarlo al menos una vez después del push:

```bash
npx skills add javalenciacai/siigo-pyme-excel-skill --skill siigo-pyme-excel
```

La indexación puede tardar unos minutos.

## 5. Verificación

```bash
# 1. Discovery: debe LISTAR siigo-pyme-excel (si dice "no skills found", el layout está mal)
npx skills add javalenciacai/siigo-pyme-excel-skill

# 2. Instalación real (dispara la indexación)
npx skills add javalenciacai/siigo-pyme-excel-skill --skill siigo-pyme-excel

# 3. Confirmar instalación local
npx skills list

# 4. Confirmar que está en el catálogo remoto
npx skills find siigo
```

Luego abrir la página pública y comprobar que rendericen la descripción del
frontmatter, el árbol de archivos (`references/`, `scripts/`, `evals/`) y el
comando de instalación:

<https://skills.sh/javalenciacai/siigo-pyme-excel-skill/siigo-pyme-excel>

## 6. API e identificadores

Base: `https://skills.sh/api/v1/`

| Endpoint | Uso |
|---|---|
| `GET /skills` | leaderboard (all-time, trending, hot) |
| `GET /skills/search?q=` | búsqueda fuzzy / semántica |
| `GET /skills/curated` | set curado de first-party |
| `GET /skills/{source}/{skill}` | detalle: install count + árbol de archivos |
| `GET /skills/audit/{source}/{skill}` | auditorías (Socket, Snyk, …) |

El `id` estable tiene formato `{source}/{slug}`; para GitHub es
`owner/repo/slug` → `javalenciacai/siigo-pyme-excel-skill/siigo-pyme-excel`.

Nota: el endpoint de búsqueda responde **401** a peticiones anónimas, así que
verifica con `npx skills find` o la web, no con `curl`.

## 7. Badge para el README

```markdown
[![skills.sh](https://skills.sh/b/javalenciacai/siigo-pyme-excel-skill)](https://skills.sh/javalenciacai/siigo-pyme-excel-skill)
```

## 8. Limitaciones a declarar

- **Windows only**. El CLI es PE32 nativo. En otros SOs requiere Wine o
  ejecución remota (RDP/PSExec).
- **Requiere SIIGO Pyme con licencia** instalada y empresa creada.
- **Las operaciones `PUSH*` son destructivas**: importan datos a la base
  SIIGO. El wrapper pide confirmación (`--yes`) por defecto.
- **No es oficial de SIIGO S.A.S.**
