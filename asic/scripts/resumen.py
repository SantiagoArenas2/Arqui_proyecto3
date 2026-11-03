#!/usr/bin/env python3
# resumen.py
# Proyecto 3 - Resume las corridas de LibreLane de asic/runs en tablas.
#
# Uso (desde la raiz del repositorio, dentro de nix-shell o con python3):
#
#   python3 asic/scripts/resumen.py                 tabla de todas las corridas
#   python3 asic/scripts/resumen.py --csv           ademas escribe asic/resultados/corridas.csv
#   python3 asic/scripts/resumen.py --corrida final detalle de una corrida:
#        timing por corner, sintesis (top 5 celdas, flip-flops, area por
#        modulo), ruta critica, DRC/LVS/antena
#   python3 asic/scripts/resumen.py --corrida final --metricas
#        imprime TODAS las metricas de esa corrida (para buscar una que falte)
#
# Solo usa la biblioteca estandar de Python. Lee, por cada corrida:
#   runs/<tag>/resolved.json             configuracion efectiva (periodo, util)
#   runs/<tag>/final/metrics.json        metricas finales (si la corrida termino)
#   runs/<tag>/NN-*/state_out.json       si no termino: las metricas del ultimo paso
#   runs/<tag>/NN-yosys-synthesis/reports/stat.json   celdas y area de sintesis
#   runs/<tag>/NN-openroad-stapostpnr/<corner>/max.rpt  ruta critica (setup)

import argparse
import csv
import glob
import json
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # asic/
RUNS = os.path.join(RAIZ, "runs")

CORNERS = [
    "nom_tt_025C_5v00", "nom_ss_125C_4v50", "nom_ff_n40C_5v50",
    "min_tt_025C_5v00", "min_ss_125C_4v50", "min_ff_n40C_5v50",
    "max_tt_025C_5v00", "max_ss_125C_4v50", "max_ff_n40C_5v50",
]
TIPICO, LENTO = "nom_tt_025C_5v00", "max_ss_125C_4v50"


# ---------------------------------------------------------------------
#  Lectura de una corrida
# ---------------------------------------------------------------------
def leer_json(ruta):
    try:
        with open(ruta, encoding="utf8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def pasos(run):
    """Carpetas de pasos ordenadas por su numero (01-..., 02-...)."""
    dirs = [d for d in glob.glob(os.path.join(run, "*-*")) if os.path.isdir(d)]
    def num(d):
        m = re.match(r"(\d+)-", os.path.basename(d))
        return int(m.group(1)) if m else -1
    return sorted([d for d in dirs if num(d) >= 0], key=num)


def paso(run, nombre):
    """Ultima carpeta de paso cuyo nombre termina en 'nombre'."""
    cand = [d for d in pasos(run) if os.path.basename(d).lower().endswith(nombre)]
    return cand[-1] if cand else None


def metricas(run):
    final = leer_json(os.path.join(run, "final", "metrics.json"))
    if final is not None:
        return final, True
    for d in reversed(pasos(run)):
        st = leer_json(os.path.join(d, "state_out.json"))
        if st and isinstance(st.get("metrics"), dict):
            return st["metrics"], False
    return {}, False


def stat_sintesis(run):
    d = paso(run, "yosys-synthesis")
    if not d:
        return None
    return leer_json(os.path.join(d, "reports", "stat.json"))


def celdas_totales(stat):
    """Cuenta de celdas por tipo de todo el diseno (incluye submodulos)."""
    if not stat:
        return {}
    if "design" in stat and "num_cells_by_type" in stat["design"]:
        cuenta = dict(stat["design"]["num_cells_by_type"])
    else:
        cuenta = {}
        for mod in stat.get("modules", {}).values():
            for k, v in mod.get("num_cells_by_type", {}).items():
                cuenta[k] = cuenta.get(k, 0) + v
    # Los submodulos conservados aparecen como "celdas": se sacan
    modulos = {m.lstrip("\\") for m in stat.get("modules", {})}
    return {k: v for k, v in cuenta.items() if k.lstrip("\\") not in modulos}


def areas_por_modulo(stat):
    """Area de cada modulo de la jerarquia conservada (stat -json de Yosys)."""
    res = {}
    for nombre, mod in (stat or {}).get("modules", {}).items():
        area = mod.get("area")
        if area is not None:
            res[nombre.lstrip("\\")] = float(area)
    total = None
    if stat and "design" in stat and "area" in stat["design"]:
        total = float(stat["design"]["area"])
    return res, total


def cfg_top(run):
    cfg = leer_json(os.path.join(run, "resolved.json")) or {}
    return cfg.get("DESIGN_NAME", "asic_top")


def flip_flops(celdas):
    return sum(v for k, v in celdas.items() if re.search(r"__s?dff|__latq|__icgt", k))


def g(m, clave, defecto=None):
    v = m.get(clave, defecto)
    return v


def resumen_corrida(run):
    tag = os.path.basename(run)
    cfg = leer_json(os.path.join(run, "resolved.json")) or {}
    m, terminada = metricas(run)
    celdas = celdas_totales(stat_sintesis(run))
    fila = {
        "corrida": tag,
        "terminada": "si" if terminada else "no",
        "CLOCK_PERIOD": cfg.get("CLOCK_PERIOD"),
        "FP_CORE_UTIL": cfg.get("FP_CORE_UTIL"),
        "die_area_um2": g(m, "design__die__area"),
        "core_area_um2": g(m, "design__core__area"),
        "area_celdas_um2": g(m, "design__instance__area__stdcell", g(m, "design__instance__area")),
        "utilizacion": g(m, "design__instance__utilization__stdcell", g(m, "design__instance__utilization")),
        "celdas": g(m, "design__instance__count__stdcell", g(m, "design__instance__count")),
        "flip_flops_sintesis": flip_flops(celdas) if celdas else None,
    }
    for tipo in ("setup", "hold"):
        for ws_tns in ("ws", "tns"):
            fila[f"{tipo}_{ws_tns}"] = g(m, f"timing__{tipo}__{ws_tns}")
            for c, nombre in ((TIPICO, "tt"), (LENTO, "ss_max")):
                fila[f"{tipo}_{ws_tns}_{nombre}"] = g(m, f"timing__{tipo}__{ws_tns}__corner:{c}")
    fila.update({
        "drc_magic": g(m, "magic__drc_error__count"),
        "drc_klayout": g(m, "klayout__drc_error__count"),
        "drc_ruteo": g(m, "route__drc_errors"),
        "lvs_errores": g(m, "design__lvs_error__count"),
        "antena_redes": g(m, "antenna__violating__nets"),
        "antena_pines": g(m, "antenna__violating__pins"),
        "max_slew": g(m, "design__max_slew_violation__count"),
        "max_cap": g(m, "design__max_cap_violation__count"),
        "largo_ruteo_um": g(m, "route__wirelength"),
        "overflow_grt": g(m, "global_route__overflow", g(m, "route__overflow")),
    })
    fila["cierra_timing"] = cierra_timing(m)
    fila["cierra_todo"] = cierra_todo(fila, terminada)
    return fila, m


def num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def cierra_timing(m):
    """WNS >= 0 y TNS = 0 en setup y hold, en TODOS los corners reportados."""
    hay = False
    for tipo in ("setup", "hold"):
        for c in CORNERS + [None]:
            suf = f"__corner:{c}" if c else ""
            ws, tns = num(m.get(f"timing__{tipo}__ws{suf}")), num(m.get(f"timing__{tipo}__tns{suf}"))
            if ws is None and tns is None:
                continue
            hay = True
            if (ws is not None and ws < 0) or (tns is not None and tns < 0):
                return "no"
    return "si" if hay else "?"


def cierra_todo(f, terminada):
    if not terminada:
        return "no (no termino)"
    malos = []
    if f["cierra_timing"] != "si":
        malos.append("timing")
    for k in ("drc_magic", "drc_klayout", "lvs_errores"):
        if num(f[k]) not in (None, 0.0):
            malos.append(k)
    if num(f["antena_redes"]) not in (None, 0.0):
        malos.append("antena (justificar)")
    return "si" if not malos else "no: " + ", ".join(malos)


# ---------------------------------------------------------------------
#  Detalle de una corrida
# ---------------------------------------------------------------------
def fmt(v, dec=3):
    if v is None:
        return "-"
    if isinstance(v, float):
        return f"{v:.{dec}f}"
    return str(v)


def ruta_critica(run, corner=LENTO, archivo="max.rpt"):
    d = paso(run, "openroad-stapostpnr")
    if not d:
        return None
    rpt = os.path.join(d, corner, archivo)
    if not os.path.exists(rpt):
        return None
    with open(rpt, encoding="utf8", errors="replace") as f:
        texto = f.read()
    ini = re.search(r"Startpoint:\s*(\S+)(.*)", texto)
    fin = re.search(r"Endpoint:\s*(\S+)(.*)", texto)
    slack = re.search(r"(-?\d+\.\d+)\s+slack", texto)
    llegada = re.search(r"(-?\d+\.\d+)\s+data arrival time", texto)
    # Celdas del camino: lineas con "instancia (tipo_de_celda)"
    camino = []
    bloque = texto.split("Startpoint:", 1)[1].split("data arrival time", 1)[0] if ini else ""
    for linea in bloque.splitlines():
        mm = re.search(r"\s(\S+)/\S+\s+\((gf180mcu_fd_sc_mcu7t5v0__\S+)\)", linea)
        if mm and (not camino or camino[-1][0] != mm.group(1)):
            camino.append((mm.group(1), mm.group(2)))
    return {
        "reporte": rpt,
        "inicio": ini.group(1) + ini.group(2) if ini else None,
        "fin": fin.group(1) + fin.group(2) if fin else None,
        "slack": slack.group(1) if slack else None,
        "llegada": llegada.group(1) if llegada else None,
        "celdas": camino,
    }


def detalle(run, todas=False):
    fila, m = resumen_corrida(run)
    print(f"== Corrida {fila['corrida']}  (terminada: {fila['terminada']})")
    print(f"   CLOCK_PERIOD = {fila['CLOCK_PERIOD']} ns   FP_CORE_UTIL = {fila['FP_CORE_UTIL']} %")
    print(f"   die = {fmt(fila['die_area_um2'], 1)} um2   core = {fmt(fila['core_area_um2'], 1)} um2   "
          f"celdas = {fmt(fila['area_celdas_um2'], 1)} um2   utilizacion = {fmt(fila['utilizacion'], 4)}")

    if todas:
        print("\n-- Todas las metricas")
        for k in sorted(m):
            print(f"   {k} = {m[k]}")
        return

    print("\n-- Timing por corner (ns)      setup WNS   setup TNS    hold WNS    hold TNS")
    for c in CORNERS:
        vals = [m.get(f"timing__{t}__{x}__corner:{c}") for t in ("setup", "hold") for x in ("ws", "tns")]
        if any(v is not None for v in vals):
            print(f"   {c:<26}" + "".join(f"{fmt(num(v)):>12}" for v in vals))
    print(f"   cierra timing en todos los corners: {fila['cierra_timing']}")

    stat = stat_sintesis(run)
    celdas = celdas_totales(stat)
    if celdas:
        total = sum(celdas.values())
        print(f"\n-- Sintesis: {total} celdas, {flip_flops(celdas)} flip-flops")
        print("   Las 5 celdas mas usadas:")
        for k, v in sorted(celdas.items(), key=lambda x: -x[1])[:5]:
            print(f"     {v:6d}  {k}")
        areas, area_total = areas_por_modulo(stat)
        top = cfg_top(run)
        if areas and area_total:
            # Yosys da el area del top incluyendo sus submodulos: lo propio
            # del top (todo lo que se aplano) es el total menos los conservados.
            sub = {k: v for k, v in areas.items() if k != top}
            areas_mostrar = dict(sub)
            areas_mostrar[f"{top} (resto del diseno, aplanado)"] = area_total - sum(sub.values())
            print("   Area por modulo (jerarquia conservada con SYNTH_KEEP_HIERARCHY_MODULES):")
            for k, v in sorted(areas_mostrar.items(), key=lambda x: -x[1]):
                print(f"     {v:12.1f} um2  {100 * v / area_total:5.1f} %  {k}")
            print(f"     {area_total:12.1f} um2  100.0 %  total del diseno")

    for corner in (LENTO, TIPICO):
        rc = ruta_critica(run, corner)
        if rc:
            print(f"\n-- Ruta critica de setup ({corner})")
            print(f"   inicio: {rc['inicio']}")
            print(f"   fin:    {rc['fin']}")
            print(f"   llegada {rc['llegada']} ns, slack {rc['slack']} ns, {len(rc['celdas'])} celdas")
            for inst, tipo in rc["celdas"]:
                print(f"     {tipo.replace('gf180mcu_fd_sc_mcu7t5v0__', ''):<12} {inst}")
            print(f"   (reporte completo: {os.path.relpath(rc['reporte'])})")
            break

    print("\n-- Signoff")
    for k in ("drc_magic", "drc_klayout", "drc_ruteo", "lvs_errores", "antena_redes",
              "antena_pines", "max_slew", "max_cap"):
        print(f"   {k:<14} {fmt(fila[k])}")
    print(f"   corrida cerrada (criterios del enunciado): {fila['cierra_todo']}")


# ---------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Resumen de corridas de LibreLane")
    ap.add_argument("--corrida", help="nombre (run tag) de una corrida para ver el detalle")
    ap.add_argument("--metricas", action="store_true", help="con --corrida: todas las metricas")
    ap.add_argument("--csv", action="store_true", help="escribe asic/resultados/corridas.csv")
    ap.add_argument("--runs", default=RUNS, help="carpeta de corridas (por defecto asic/runs)")
    a = ap.parse_args()

    if a.corrida:
        run = os.path.join(a.runs, a.corrida)
        if not os.path.isdir(run):
            sys.exit(f"No existe la corrida {run}")
        detalle(run, a.metricas)
        return

    runs = sorted(d for d in glob.glob(os.path.join(a.runs, "*")) if os.path.isdir(d))
    if not runs:
        sys.exit(f"No hay corridas en {a.runs}")
    filas = [resumen_corrida(r)[0] for r in runs]

    cols = ["corrida", "CLOCK_PERIOD", "FP_CORE_UTIL", "die_area_um2", "area_celdas_um2",
            "utilizacion", "flip_flops_sintesis", "setup_ws_tt", "setup_tns_tt", "hold_ws_tt",
            "hold_tns_tt", "setup_ws_ss_max", "setup_tns_ss_max", "hold_ws_ss_max",
            "hold_tns_ss_max", "drc_ruteo", "antena_redes", "cierra_timing", "cierra_todo"]
    print(" | ".join(cols))
    for f in filas:
        print(" | ".join(fmt(num(f[c]) if isinstance(f[c], (int, float)) else f[c], 3) for c in cols))

    if a.csv:
        os.makedirs(os.path.join(RAIZ, "resultados"), exist_ok=True)
        ruta = os.path.join(RAIZ, "resultados", "corridas.csv")
        with open(ruta, "w", newline="", encoding="utf8") as f:
            w = csv.DictWriter(f, fieldnames=list(filas[0].keys()))
            w.writeheader()
            w.writerows(filas)
        print(f"\nEscrito {os.path.relpath(ruta)}")


if __name__ == "__main__":
    main()
