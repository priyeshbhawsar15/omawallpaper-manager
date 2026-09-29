from __future__ import annotations

import importlib.util
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest import mock


HELPER_PATH = Path(__file__).parents[1] / "bin" / "wallpaper-controller"
SPEC = importlib.util.spec_from_loader(
    "wallpaper_controller", SourceFileLoader("wallpaper_controller", str(HELPER_PATH))
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load Wallpaper Controller helper")
controller = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(controller)


class CycleTests(unittest.TestCase):
    def test_manual_cycle_reenables_stopped_wallpaper_engine(self) -> None:
        config = {
            "wallpaperEnabled": False,
            "active": "we:current",
            "cycle": ["we:current", "we:next"],
            "shuffleRemaining": ["we:next"],
        }
        available = [
            {"id": "we:current", "valid": True},
            {"id": "we:next", "valid": True},
        ]

        with (
            mock.patch.object(controller, "load_config", return_value=config),
            mock.patch.object(controller, "entries", return_value=available),
            mock.patch.object(controller, "save_config"),
            mock.patch.object(controller, "apply", return_value={"active": "we:next"}) as apply,
        ):
            result = controller.cycle()

        self.assertEqual(result, {"active": "we:next"})
        apply.assert_called_once_with("we:next")

    def test_automatic_rotation_remains_blocked_after_stop(self) -> None:
        with (
            mock.patch.object(
                controller,
                "load_config",
                return_value={"wallpaperEnabled": False, "rotationEnabled": True},
            ),
            mock.patch.object(controller, "cycle") as cycle,
        ):
            result = controller.due()

        self.assertEqual(result, {"due": False})
        cycle.assert_not_called()


if __name__ == "__main__":
    unittest.main()
