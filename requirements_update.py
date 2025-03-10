import os
import pkg_resources
import subprocess
import ast

# Verzeichnisse durchsuchen (Hauptprojektordner)
PROJECT_DIR = "/opt/omnimanage"

# Anforderungen-Datei
REQUIREMENTS_FILE = os.path.join(PROJECT_DIR, "requirements.txt")


def get_installed_packages():
    """Gibt eine Liste aller installierten Pakete zurück."""
    installed = {pkg.key for pkg in pkg_resources.working_set}
    return installed


def get_imported_modules(directory):
    """Durchsucht alle .py-Dateien im Projektverzeichnis nach importierten Modulen."""
    imported_modules = set()
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".py"):
                file_path = os.path.join(root, file)
                with open(file_path, "r", encoding="utf-8") as f:
                    try:
                        tree = ast.parse(f.read(), filename=file_path)
                        for node in ast.walk(tree):
                            if isinstance(node, ast.Import):
                                for alias in node.names:
                                    imported_modules.add(alias.name.split(".")[0])
                            elif isinstance(node, ast.ImportFrom):
                                if node.module:
                                    imported_modules.add(node.module.split(".")[0])
                    except (SyntaxError, UnicodeDecodeError):
                        print(f"⚠️ Fehler beim Analysieren von {file_path}, überspringe Datei.")
    
    return imported_modules


def update_requirements():
    """Aktualisiert die requirements.txt Datei mit neuen Paketen."""
    installed_packages = get_installed_packages()
    imported_modules = get_imported_modules(PROJECT_DIR)

    # Module herausfiltern, die nicht nachinstalliert werden müssen
    standard_libs = {"sys", "os", "re", "json", "time", "datetime", "random", "math",
                     "subprocess", "shutil", "pathlib", "logging", "argparse", "typing",
                     "itertools", "collections", "functools", "enum", "traceback", "inspect"}

    missing_packages = imported_modules - installed_packages - standard_libs

    if not missing_packages:
        print("✅ Alle benötigten Pakete sind bereits installiert.")
        return

    print("📦 Fehlende Pakete gefunden:", ", ".join(missing_packages))

    # Fehlende Pakete installieren
    for package in missing_packages:
        try:
            subprocess.run(["pip", "install", package], check=True)
            print(f"✅ Erfolgreich installiert: {package}")
        except subprocess.CalledProcessError:
            print(f"❌ Fehler beim Installieren von: {package}")

    # requirements.txt aktualisieren
    with open(REQUIREMENTS_FILE, "a", encoding="utf-8") as req_file:
        for package in missing_packages:
            req_file.write(f"{package}\n")

    print("✅ requirements.txt wurde aktualisiert.")


if __name__ == "__main__":
    update_requirements()
