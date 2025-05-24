"""
Paquete principal de ManagerOfficeScriptTool.

Este módulo expone las clases, funciones y utilidades principales del proyecto,
facilitando su acceso desde scripts externos como main.py.
"""

from .core import (
    ODTManager,
    OfficeInstallation,
    OfficeManager,
    RegistryReader,
    fetch_odt_download_info,
)
from .gui import OfficeSelectionWindow
from .scripts import OfficeInstaller, OfficeUninstaller, run_uninstallers
from .utils import (
    ask_yes_no,
    center_window,
    clean_folders,
    clean_temp_folders_ui,
    ensure_subfolder,
    get_data_path,
    get_temp_dir,
    init_logging,
    safe_log_path,
    safe_log_registry_key,
)

__all__ = [
    "ODTManager",
    "OfficeInstallation",
    "OfficeManager",
    "RegistryReader",
    "fetch_odt_download_info",
    "OfficeSelectionWindow",
    "OfficeInstaller",
    "OfficeUninstaller",
    "run_uninstallers",
    "ask_yes_no",
    "center_window",
    "clean_folders",
    "clean_temp_folders_ui",
    "ensure_subfolder",
    "get_data_path",
    "get_temp_dir",
    "init_logging",
    "safe_log_path",
    "safe_log_registry_key",
]
