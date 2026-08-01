# Assets

Plantillas `.xlsx` generadas dinámicamente por `scripts/build-xlsx-template.py`.

No commitear los `.xlsx` al repo (están en `.gitignore`). Si necesitas
regenerar uno:

```bash
python scripts/build-xlsx-template.py GETTER \
    --salida assets/templates/GETTER_template.xlsx --offline
```

Modo `--offline` no invoca el CLI, usa la estructura de columnas
conocida — útil para tests y para que un usuario sepa qué llenar antes
de un PUSH*.
