import json, subprocess, os, sys

LOG = "/Users/dadederk/Developer/RetroRacing/.tmp/iap_l10n_upload_result.json"
out = {"steps": []}

def run_step(name, cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    out["steps"].append({"name": name, "cmd": cmd, "stdout": p.stdout, "stderr": p.stderr, "code": p.returncode})
    return p

iap_id = "6759012658"
locales = {
    "de-DE": ("Unbegrenzte Spiele", "Spiele unbegrenzt und unterstütze RetroRapid!"),
    "nl-NL": ("Onbeperkt spelen", "Speel onbeperkt en steun RetroRapid!"),
    "it": ("Partite illimitate", "Partite illimitate: supporta RetroRapid!"),
    "fr-FR": ("Parties illimitées", "Joue sans limite et soutiens RetroRapid!"),
}

try:
    paths = run_step("paths", ["helm-asc", "paths", "--agent"])
    paths.check_returncode()
    inbox = json.loads(paths.stdout)["uploadsInbox"]
    root = os.path.join(inbox, "iap-unlimited-plays-eu")

    # Per-locale metadata.csv tree (helm-asc canonical format)
    for locale, (name, desc) in locales.items():
        loc_dir = os.path.join(root, locale)
        os.makedirs(loc_dir, exist_ok=True)
        csv_path = os.path.join(loc_dir, "metadata.csv")
        with open(csv_path, "w", encoding="utf-8") as f:
            f.write("field,value\n")
            f.write(f"name,{name}\n")
            f.write(f"description,{desc}\n")
    out["format_tree"] = "per-locale `<locale>/metadata.csv` with `field,value` rows for name and description"

    dry = run_step("dry_run_tree", [
        "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", root, "--dry-run", "--agent"
    ])
    out["dry_run_tree"] = dry.stdout

    worked = False
    if dry.returncode == 0 and "noop" not in dry.stdout and json.loads(dry.stdout).get("status") != "noop":
        live = run_step("live_tree", [
            "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", root, "--agent"
        ])
        out["live_tree"] = live.stdout
        worked = live.returncode == 0

    if not worked:
        csv_path = os.path.join(inbox, "iap-unlimited-plays-eu.csv")
        with open(csv_path, "w", encoding="utf-8") as f:
            f.write("locale,name,description\n")
            for locale, (name, desc) in locales.items():
                f.write(f"{locale},{name},{desc}\n")
        out["format_csv"] = "single multi-locale CSV: locale,name,description"

        dry2 = run_step("dry_run_csv", [
            "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", csv_path, "--dry-run", "--agent"
        ])
        out["dry_run_csv"] = dry2.stdout

        if dry2.returncode == 0 and "noop" not in dry2.stdout and json.loads(dry2.stdout).get("status") != "noop":
            live2 = run_step("live_csv", [
                "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", csv_path, "--agent"
            ])
            out["live_csv"] = live2.stdout
            worked = live2.returncode == 0

    if not worked:
        dl = run_step("download", ["helm-asc", "inAppPurchase", iap_id, "localizations", "download", "--agent"])
        out["download"] = dl.stdout
        dl_json = json.loads(dl.stdout)
        dl_root = dl_json["rootPath"]
        out["download_root"] = dl_root
        # Read en-US template if present
        en_csv = os.path.join(dl_root, "en-US", "metadata.csv")
        if os.path.isfile(en_csv):
            with open(en_csv, encoding="utf-8") as f:
                out["en_us_template"] = f.read()
        for locale, (name, desc) in locales.items():
            loc_dir = os.path.join(dl_root, locale)
            os.makedirs(loc_dir, exist_ok=True)
            with open(os.path.join(loc_dir, "metadata.csv"), "w", encoding="utf-8") as f:
                f.write("field,value\n")
                f.write(f"name,{name}\n")
                f.write(f"description,{desc}\n")
        dry3 = run_step("dry_run_download_root", [
            "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", dl_root, "--dry-run", "--agent", "--locale", "de-DE", "--locale", "nl-NL", "--locale", "it", "--locale", "fr-FR"
        ])
        out["dry_run_download_root"] = dry3.stdout
        if dry3.returncode == 0 and json.loads(dry3.stdout).get("status") != "noop":
            live3 = run_step("live_download_root", [
                "helm-asc", "inAppPurchase", iap_id, "localizations", "upload", "--path", dl_root, "--agent", "--locale", "de-DE", "--locale", "nl-NL", "--locale", "it", "--locale", "fr-FR"
            ])
            out["live_download_root"] = live3.stdout

    verify = run_step("verify", ["helm-asc", "inAppPurchase", iap_id, "localizations", "--agent"])
    out["verify"] = verify.stdout
except Exception as e:
    out["error"] = repr(e)

with open(LOG, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
print("WROTE", LOG)
