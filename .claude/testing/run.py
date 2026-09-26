import io, os, sys
from lupa import lua51

sys.stdout.reconfigure(encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
STAL = os.environ.get("STAL_SRC", os.path.join(ROOT, "SkillTreeAutoLoad"))
API_REPO = os.path.join(os.path.dirname(os.path.dirname(ROOT)), "ApiEbonhold")
EBONAPI = os.environ.get("EBONAPI_SRC", os.path.join(API_REPO, "AddOn", "EbonAPI"))
WOWMOCK = os.environ.get("WOWMOCK", os.path.join(API_REPO, ".claude", "testing", "wowmock.lua"))

RELEASE, WORK = "1.9.0", "1.9.0-2"

RUNS = [
    ("s_boot.lua", "frFR", RELEASE),
    ("s_boot.lua", "enUS", RELEASE),
    ("s_boot.lua", "deDE", RELEASE),
    ("s_boot.lua", "esES", RELEASE),
    ("s_boot.lua", "esMX", RELEASE),
    ("s_versions.lua", "frFR", RELEASE),
    ("s_versions.lua", "frFR", WORK),
    ("s_bridge.lua", "frFR", RELEASE),
    ("s_data.lua", "frFR", RELEASE),
    ("s_core.lua", "frFR", RELEASE),
    ("s_plan.lua", "frFR", RELEASE),
    ("s_overlay.lua", "frFR", RELEASE),
    ("s_view.lua", "frFR", RELEASE),
    ("s_ui.lua", "frFR", RELEASE),
    ("s_ui.lua", "enUS", RELEASE),
    ("s_menus.lua", "frFR", RELEASE),
    ("s_language.lua", "frFR", RELEASE),
]


def toc_files(root, toc):
    text = io.open(os.path.join(root, toc), encoding="utf-8").read()
    return [l.strip().replace("\\", "/") for l in text.splitlines()
            if l.strip() and not l.strip().startswith("#") and l.strip().lower().endswith(".lua")]


def read(path):
    return io.open(path, encoding="utf-8").read()


def run(scenario, locale, version, verbose):
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    execute = L.eval("function(src, name, ...) local f, e = loadstring(src, '=' .. name) if not f then error(e) end return f(...) end")
    mock = execute(read(WOWMOCK), "wowmock")
    mock["locale"] = locale
    mock["version"] = version
    g["STAL_SRC"] = STAL.replace("\\", "/") + "/"
    execute(read(os.path.join(HERE, "fixture.lua")), "fixture")
    g["T"]["verbose"] = verbose
    for f in toc_files(EBONAPI, "EbonAPI.toc"):
        execute(read(os.path.join(EBONAPI, f)), "EbonAPI/" + f, "EbonAPI")
    for f in toc_files(STAL, "SkillTreeAutoLoad.toc"):
        execute(read(os.path.join(STAL, f)), "STAL/" + f, "SkillTreeAutoLoad")
    execute(read(os.path.join(HERE, scenario)), scenario)
    t = g["T"]
    caught = list(mock["caught"].values())
    allowed = int(t["allowErrors"] or 0)
    failed = int(t["failed"]) + max(0, len(caught) - allowed)
    for e in caught[allowed:]:
        print("  ERREUR LUA", e)
    return int(t["passed"]), failed


def main(args):
    verbose = "-v" in args
    args = [a for a in args if a != "-v"]
    runs = RUNS
    if args:
        runs = [(args[0], args[1] if len(args) > 1 else "frFR", args[2] if len(args) > 2 else RELEASE)]
    total_passed, total_failed, broken = 0, 0, 0
    for scenario, locale, version in runs:
        try:
            passed, failed = run(scenario, locale, version, verbose)
        except Exception as err:
            passed, failed = 0, 1
            print("  PLANTE", scenario, err)
        total_passed += passed
        total_failed += failed
        if failed:
            broken += 1
        print("%s  %-16s %-5s %-8s %d/%d" % ("PASS" if not failed else "FAIL", scenario, locale, version,
                                            passed, passed + failed))
    print("\n%d scénarios, %d vérifications, %d échec(s)" % (len(runs), total_passed + total_failed, total_failed))
    sys.exit(1 if total_failed else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
