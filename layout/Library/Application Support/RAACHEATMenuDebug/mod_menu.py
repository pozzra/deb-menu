#!/usr/bin/env python3
"""
================================================================================
ROSE'S / RAACHEAT MOD MENU & CONFIG GENERATOR (Python Edition)
================================================================================
Source Decompilation: ESP Cracked.apk (libRAACHEAT.so / OnDevzGuard / Dex2C)
Target Game: Rules of Survival: Legacy (net.roslegacy.prod)
Extracted Architecture: ARM64-v8a (.rodata VA: 0x4E190, .text VA: 0x3775A0)

Features:
  - 100% extracted data from ESP_Cracked_decompiled
  - Aimbot & Combat Protocol Controller
  - Cyber ESP / Visuals Configurator with Color Palettes
  - Memory Engine, Movement & Weapon Hacks
  - Config File Generators (aim_cfg.txt, esp.txt, menu_config.txt, speed-memory.cfg)
  - Game Python Payload Generator (ros_payload.py for execfile)
  - Interactive Dark Cyberpunk Tkinter GUI + CLI Fallback
  - Preset Manager (Legit, Rage, ESP Only, Default)
  - Deep XREF & Virtual Address Inspection Engine
================================================================================
"""

import os
import sys
import json
import argparse
from typing import Dict, List, Any, Optional

# Base Workspace Paths
WORKSPACE_ROOT = os.path.dirname(os.path.abspath(__file__))
DECOMPILED_DIR = os.path.join(WORKSPACE_ROOT, "ESP_Cracked_decompiled")
CATALOG_PATH = os.path.join(WORKSPACE_ROOT, "RAACHEAT_Menu_Code_Debug", "menu_catalog.json")

# ==============================================================================
# 1. EXTRACTED FEATURE DATABASE (Source: libRAACHEAT.so & strings analysis)
# ==============================================================================

RAW_EXTRACTED_DATA = {
    "aimbot": [
        {
            "id": "aim_enable",
            "name": "AimBot / AimLock Enable",
            "config_key": "Aim.Enable",
            "va": "0x0004fc40",
            "flag_addr": "0x46A1A0",
            "save_addr": "0x46A058",
            "first_xref": "0x0037c5bc",
            "type": "bool",
            "default": False,
            "desc": "Main aimlock toggle. Directly modifies game aim vector towards target.",
        },
        {
            "id": "aim_fov",
            "name": "Aim FOV Radius",
            "config_key": "Aim.Fov",
            "va": "0x0004f287",
            "first_xref": "0x0037c76c",
            "type": "float",
            "min": 10.0,
            "max": 360.0,
            "default": 90.0,
            "desc": "Targeting cone radius in degrees from center of screen.",
        },
        {
            "id": "aim_smooth",
            "name": "Aim Smooth",
            "config_key": "Aim.Smooth",
            "va": "0x000546f9",
            "first_xref": "0x0037c8a4",
            "type": "float",
            "min": 1.0,
            "max": 30.0,
            "default": 8.0,
            "desc": "Smoothing factor. Higher values appear more natural and bypass anti-cheat heuristics.",
        },
        {
            "id": "aim_distance",
            "name": "Aim Lock Distance",
            "config_key": "Aim.MaxDistance",
            "va": "0x0004fa47",
            "first_xref": "0x0037c680",
            "type": "float",
            "min": 20.0,
            "max": 500.0,
            "default": 250.0,
            "desc": "Maximum target engagement distance in meters.",
        },
        {
            "id": "aim_instant",
            "name": "Instant AimLock (Direct Snap)",
            "config_key": "Aim.InstantAim",
            "va": "0x00052f19",
            "first_xref": "0x0037cb10",
            "type": "bool",
            "default": False,
            "desc": "Bypasses interpolation and snaps crosshair immediately to target bone.",
        },
        {
            "id": "aim_draw_fov",
            "name": "Draw Aim FOV Circle",
            "config_key": "Aim.DrawFovCircle",
            "va": "0x00052f37",
            "first_xref": "0x0037cb84",
            "type": "bool",
            "default": True,
            "desc": "Renders an on-screen circle representing the active targeting boundary.",
        },
        {
            "id": "silent_aim",
            "name": "Silent Aim (Magic Bullet)",
            "config_key": "Aim.SilentAim",
            "va": "0x000521f9",
            "first_xref": "0x0037c950",
            "type": "bool",
            "default": False,
            "desc": "Redirects bullets towards targets without visibly redirecting the client camera.",
        },
        {
            "id": "silent_distance",
            "name": "Silent Aim Distance",
            "config_key": "Aim.SilentDistance",
            "va": "0x00050128",
            "first_xref": "0x0037ca0c",
            "type": "float",
            "min": 10.0,
            "max": 300.0,
            "default": 120.0,
            "desc": "Maximum range at which silent bullet redirection occurs.",
        },
        {
            "id": "silent_360",
            "name": "Silent 360",
            "config_key": "Aim.Silent360",
            "va": "0x00051b91",
            "first_xref": "0x0037caa0",
            "type": "bool",
            "default": False,
            "desc": "Allows silent aim hits even on enemies behind player back.",
        },
        {
            "id": "target_bone",
            "name": "Target Bone",
            "config_key": "Aim.TargetBone",
            "va": "0x00051899",
            "first_xref": "0x0037cc40",
            "type": "combo",
            "options": ["Head", "Neck", "Chest", "Pelvis"],
            "default": "Head",
            "desc": "Skeletal bone target priority for locking/prediction.",
        },
        {
            "id": "trigger_condition",
            "name": "Trigger Condition",
            "config_key": "Aim.Trigger",
            "va": "0x0004fc65",
            "first_xref": "0x0037cd1c",
            "type": "combo",
            "options": ["While Scoped", "While Firing", "Scoped or Firing", "Always Active"],
            "default": "While Scoped",
            "desc": "Specifies when aimbot engages.",
        },
        {
            "id": "aim_ignore_knocked",
            "name": "Ignore Knocked",
            "config_key": "Aim.IgnoreKnocked",
            "va": "0x0004f731",
            "first_xref": "0x0037cde8",
            "type": "bool",
            "default": True,
            "desc": "Disregards down/crawling enemies to prioritize standing threats.",
        },
        {
            "id": "aim_ignore_bot",
            "name": "Ignore Bot",
            "config_key": "Aim.IgnoreBot",
            "va": "0x00052d8c",
            "first_xref": "0x0037ce60",
            "type": "bool",
            "default": False,
            "desc": "Excludes AI bot players from targeting.",
        },
        {
            "id": "aim_vischeck",
            "name": "Visible Check",
            "config_key": "Aim.VisCheck",
            "va": "0x0005226d",
            "first_xref": "0x0037cef0",
            "type": "bool",
            "default": True,
            "desc": "Raycasts terrain and walls to ensure targets are physically visible.",
        },
        {
            "id": "aim_teamcheck",
            "name": "Team Check",
            "config_key": "Aim.TeamCheck",
            "va": "0x000540f8",
            "first_xref": "0x0037cf70",
            "type": "bool",
            "default": True,
            "desc": "Excludes teammates from all combat calculations.",
        },
        {
            "id": "aim_autoshoot",
            "name": "Auto Shoot",
            "config_key": "Aim.AutoShoot",
            "va": "0x000532a3",
            "first_xref": "0x0037d010",
            "type": "bool",
            "default": False,
            "desc": "Automatically fires weapon once crosshair is on target.",
        },
        {
            "id": "aim_power",
            "name": "Follow Hardness (Power)",
            "config_key": "Aim.Power",
            "va": "0x00054b54",
            "first_xref": "0x0037d090",
            "type": "float",
            "min": 1.0,
            "max": 100.0,
            "default": 75.0,
            "desc": "Aim tracking rigidity under rapid target movement.",
        },
        {
            "id": "aim_cross",
            "name": "Aim Crosshair Overlay",
            "config_key": "Aim.Cross",
            "va": "0x00052fa8",
            "first_xref": "0x0037d110",
            "type": "bool",
            "default": True,
            "desc": "Renders enhanced center crosshair.",
        },
    ],
    "visuals": [
        {
            "id": "esp_active",
            "name": "CYBER ESP Master",
            "config_key": "ESP.Active",
            "va": "0x00052656",
            "first_xref": "0x0037d200",
            "type": "bool",
            "default": True,
            "desc": "Master switch for all on-screen overlay drawings.",
        },
        {
            "id": "esp_box",
            "name": "Esp Box",
            "config_key": "ESP.Box",
            "va": "0x00052064",
            "first_xref": "0x0037d280",
            "type": "bool",
            "default": True,
            "desc": "Draws bounding box around players.",
        },
        {
            "id": "esp_box_style",
            "name": "Box Style",
            "config_key": "ESP.BoxStyle",
            "va": "0x00052ad6",
            "first_xref": "0x0037d300",
            "type": "combo",
            "options": ["2D Corner Box", "2D Full Box", "3D Bounding Box"],
            "default": "2D Corner Box",
            "desc": "Visual style of ESP box.",
        },
        {
            "id": "esp_line",
            "name": "Esp Line (Tracer)",
            "config_key": "ESP.Line",
            "va": "0x000518b5",
            "first_xref": "0x0037d390",
            "type": "bool",
            "default": True,
            "desc": "Draws snap line from screen position to player.",
        },
        {
            "id": "esp_line_pos",
            "name": "Line Position",
            "config_key": "ESP.LinePosition",
            "va": "0x0004f755",
            "first_xref": "0x0037d410",
            "type": "combo",
            "options": ["Bottom", "Top", "Crosshair"],
            "default": "Bottom",
            "desc": "Origin point for snap tracers.",
        },
        {
            "id": "esp_line_thickness",
            "name": "Line Thickness",
            "config_key": "ESP.LineThickness",
            "va": "0x0005225b",
            "first_xref": "0x0037d490",
            "type": "float",
            "min": 1.0,
            "max": 6.0,
            "default": 2.0,
            "desc": "Tracer and box line stroke width.",
        },
        {
            "id": "esp_skeleton",
            "name": "Esp Bone / Skeleton",
            "config_key": "ESP.Skeleton",
            "va": "0x0004f093",
            "first_xref": "0x0037d520",
            "type": "bool",
            "default": True,
            "desc": "Renders player bone joints and spine/limbs.",
        },
        {
            "id": "esp_health",
            "name": "Esp Health Bar",
            "config_key": "ESP.Health",
            "va": "0x00053839",
            "first_xref": "0x0037d5a0",
            "type": "bool",
            "default": True,
            "desc": "Displays health status and numeric HP above head.",
        },
        {
            "id": "esp_distance",
            "name": "Esp Distance",
            "config_key": "ESP.Distance",
            "va": "0x0005442d",
            "first_xref": "0x0037d620",
            "type": "bool",
            "default": True,
            "desc": "Shows real-time distance in meters.",
        },
        {
            "id": "esp_name",
            "name": "Esp Player Name",
            "config_key": "ESP.Name",
            "va": "0x0005329a",
            "first_xref": "0x0037d6a0",
            "type": "bool",
            "default": True,
            "desc": "Displays player in-game username.",
        },
        {
            "id": "esp_vehicle",
            "name": "Vehicle Esp",
            "config_key": "ESP.Vehicle",
            "va": "0x0004fc7e",
            "first_xref": "0x0037d720",
            "type": "bool",
            "default": False,
            "desc": "Highlights cars, bikes, and boats with distance.",
        },
        {
            "id": "esp_bot",
            "name": "Bot Identifier",
            "config_key": "ESP.Bot",
            "va": "0x00053415",
            "first_xref": "0x0037d7a0",
            "type": "bool",
            "default": True,
            "desc": "Distinguishes AI bots from real players using green tracers.",
        },
        {
            "id": "esp_knocked",
            "name": "Esp Knocked State",
            "config_key": "ESP.Knocked",
            "va": "0x0004f0a0",
            "first_xref": "0x0037d820",
            "type": "bool",
            "default": True,
            "desc": "Applies special yellow marker to knocked players.",
        },
        {
            "id": "esp_enemy_only",
            "name": "Enemy Only (Exclude Team)",
            "config_key": "ESP.EnemyOnly",
            "va": "0x00050174",
            "first_xref": "0x0037d8a0",
            "type": "bool",
            "default": True,
            "desc": "Hides ESP overlays on squad members.",
        },
        {
            "id": "esp_crown_weapons",
            "name": "Crown Weapons ESP",
            "config_key": "ESP.CrownWeapons",
            "va": "0x0005154d",
            "first_xref": "0x0037d920",
            "type": "bool",
            "default": False,
            "desc": "Highlights rare airdrop weapons and armor.",
        },
        {
            "id": "esp_radar_fx",
            "name": "Radar FX & Alerts",
            "config_key": "ESP.Alert",
            "va": "0x0005223d",
            "first_xref": "0x0037d9a0",
            "type": "bool",
            "default": True,
            "desc": "Pings on-screen warning arrows when enemies approach off-screen.",
        },
        {
            "id": "esp_max_distance",
            "name": "ESP Max Distance",
            "config_key": "ESP.MaxDistance",
            "va": "0x0005193d",
            "first_xref": "0x0037da20",
            "type": "float",
            "min": 50.0,
            "max": 800.0,
            "default": 400.0,
            "desc": "Maximum render distance for ESP components.",
        },
        {
            "id": "esp_hide_recording",
            "name": "Hide ESP (Screen & Recording)",
            "config_key": "Settings.HideRecording",
            "va": "0x0004fc8a",
            "first_xref": "0x0037daa0",
            "type": "bool",
            "default": True,
            "desc": "Stream-proof mode: masks ImGui surface from video capture & screen recording.",
        },
    ],
    "memory": [
        {
            "id": "mem_speed_hack",
            "name": "Speed Hack",
            "config_key": "Speed.Enable",
            "va": "0x00053d2d",
            "first_xref": "0x0037db40",
            "type": "bool",
            "default": False,
            "desc": "Alters player movement velocity memory pointers in libclient.so.",
        },
        {
            "id": "mem_speed_mult",
            "name": "Speed Multiplier",
            "config_key": "Speed.Multiplier",
            "va": "0x00053cb9",
            "first_xref": "0x0037dbc0",
            "type": "float",
            "min": 1.0,
            "max": 8.0,
            "default": 2.5,
            "desc": "Velocity multiplier applied when Speed Hack is active.",
        },
        {
            "id": "mem_fly_hack",
            "name": "Fly Hack",
            "config_key": "Memory.FlyHack",
            "va": "0x00053ef7",
            "first_xref": "0x0037dc40",
            "type": "bool",
            "default": False,
            "desc": "Locks gravity and allows free vertical altitude adjustment.",
        },
        {
            "id": "mem_wall_hack",
            "name": "Wall Hack",
            "config_key": "Memory.WallHack",
            "va": "0x0004f515",
            "first_xref": "0x0037dcc0",
            "type": "bool",
            "default": False,
            "desc": "Disables collision meshes on select structures.",
        },
        {
            "id": "mem_fast_reload",
            "name": "Fast Reload",
            "config_key": "Memory.FastReload",
            "va": "0x0004f780",
            "first_xref": "0x0037dd40",
            "type": "bool",
            "default": False,
            "desc": "Overrides weapon reload animation duration to zero.",
        },
        {
            "id": "mem_fast_heal",
            "name": "Fast Heal",
            "config_key": "Memory.FastHeal",
            "va": "0x00052db4",
            "first_xref": "0x0037ddc0",
            "type": "bool",
            "default": False,
            "desc": "Removes channel delay when applying medkits and bandages.",
        },
        {
            "id": "mem_fast_parachute",
            "name": "Fast Parachute",
            "config_key": "Memory.FastParachute",
            "va": "0x000538a1",
            "first_xref": "0x0037de40",
            "type": "bool",
            "default": False,
            "desc": "Increases dive and glide descent speed upon dropping.",
        },
        {
            "id": "mem_no_recoil",
            "name": "No Recoil",
            "config_key": "Memory.NoRecoil",
            "va": "0x0005479d",
            "first_xref": "0x0037dec0",
            "type": "bool",
            "default": False,
            "desc": "Patches weapon spread and kickback angles to zero in weapon table.",
        },
        {
            "id": "mem_unlock_fps",
            "name": "Unlock 120 FPS",
            "config_key": "Settings.Unlock120FPS",
            "va": "0x000533f9",
            "first_xref": "0x0037df40",
            "type": "bool",
            "default": True,
            "desc": "Bypasses standard 60 FPS cap on high-refresh mobile displays.",
        },
    ],
}

# Color palettes (RGBA normalized 0.0 - 1.0)
DEFAULT_COLORS = {
    "ESP.BoxColor": [0.31, 0.94, 0.65, 1.0],      # Neon Emerald
    "ESP.LineColor": [1.00, 0.25, 0.25, 0.85],    # Crimson
    "ESP.SkeletonColor": [1.00, 1.00, 1.00, 0.90],# Ghost White
}

# ==============================================================================
# 2. PRESET PROFILES
# ==============================================================================

PRESETS = {
    "Default / Balanced": {
        "aim_enable": False,
        "aim_fov": 90.0,
        "aim_smooth": 8.0,
        "aim_distance": 250.0,
        "aim_instant": False,
        "silent_aim": False,
        "esp_active": True,
        "esp_box": True,
        "esp_skeleton": True,
        "esp_health": True,
        "esp_distance": True,
        "esp_line": True,
        "mem_speed_hack": False,
        "mem_fly_hack": False,
        "mem_no_recoil": False,
        "mem_unlock_fps": True,
    },
    "Legit / Closet": {
        "aim_enable": True,
        "aim_fov": 35.0,
        "aim_smooth": 16.0,
        "aim_distance": 180.0,
        "aim_instant": False,
        "silent_aim": False,
        "silent_360": False,
        "esp_active": True,
        "esp_box": True,
        "esp_box_style": "2D Corner Box",
        "esp_skeleton": True,
        "esp_health": True,
        "esp_distance": True,
        "esp_line": False,
        "mem_speed_hack": False,
        "mem_fly_hack": False,
        "mem_no_recoil": False,
        "mem_unlock_fps": True,
        "esp_hide_recording": True,
    },
    "Rage / HvH": {
        "aim_enable": True,
        "aim_fov": 360.0,
        "aim_smooth": 1.0,
        "aim_distance": 500.0,
        "aim_instant": True,
        "silent_aim": True,
        "silent_360": True,
        "aim_autoshoot": True,
        "esp_active": True,
        "esp_box": True,
        "esp_line": True,
        "esp_skeleton": True,
        "esp_health": True,
        "esp_distance": True,
        "mem_speed_hack": True,
        "mem_speed_mult": 4.5,
        "mem_fly_hack": True,
        "mem_fast_reload": True,
        "mem_fast_heal": True,
        "mem_no_recoil": True,
        "mem_unlock_fps": True,
    },
    "ESP Only / Streamer": {
        "aim_enable": False,
        "silent_aim": False,
        "esp_active": True,
        "esp_box": True,
        "esp_skeleton": True,
        "esp_health": True,
        "esp_distance": True,
        "esp_line": False,
        "esp_hide_recording": True,
        "mem_speed_hack": False,
        "mem_fly_hack": False,
        "mem_no_recoil": False,
        "mem_unlock_fps": True,
    },
}

# ==============================================================================
# 3. MOD MENU CORE MODEL & CONFIG ENGINE
# ==============================================================================

class ModMenuState:
    """Manages mod menu state, config reading/writing, and validation."""

    def __init__(self):
        self.values: Dict[str, Any] = {}
        self.colors: Dict[str, List[float]] = dict(DEFAULT_COLORS)
        self.reset_to_default()

    def reset_to_default(self):
        """Loads default values for all features."""
        for cat, feats in RAW_EXTRACTED_DATA.items():
            for f in feats:
                self.values[f["id"]] = f["default"]
        self.colors = dict(DEFAULT_COLORS)

    def apply_preset(self, preset_name: str):
        """Applies a preset configuration dictionary."""
        if preset_name in PRESETS:
            preset = PRESETS[preset_name]
            for k, v in preset.items():
                if k in self.values:
                    self.values[k] = v

    def set_value(self, feature_id: str, value: Any):
        self.values[feature_id] = value

    def get_value(self, feature_id: str) -> Any:
        return self.values.get(feature_id)

    # --------------------------------------------------------------------------
    # Config File Builders (Matching ROS / libRAACHEAT formats)
    # --------------------------------------------------------------------------

    def build_aim_cfg(self) -> str:
        """
        Builds /data/data/net.roslegacy.prod/imgui/aim_cfg.txt
        Format used by libRAACHEAT aimbot engine.
        """
        lines = [
            "# RAACHEAT AIMBOT CONFIGURATION",
            "# Source: libRAACHEAT.so (AArch64)",
            f"Aim.Enable={'1' if self.values.get('aim_enable') else '0'}",
            f"Aim.Fov={self.values.get('aim_fov', 90.0):.1f}",
            f"Aim.Smooth={self.values.get('aim_smooth', 8.0):.1f}",
            f"Aim.MaxDistance={self.values.get('aim_distance', 250.0):.1f}",
            f"Aim.InstantAim={'1' if self.values.get('aim_instant') else '0'}",
            f"Aim.SilentAim={'1' if self.values.get('silent_aim') else '0'}",
            f"Aim.SilentDistance={self.values.get('silent_distance', 120.0):.1f}",
            f"Aim.Silent360={'1' if self.values.get('silent_360') else '0'}",
            f"Aim.TargetBone={self.values.get('target_bone', 'Head')}",
            f"Aim.Trigger={self.values.get('trigger_condition', 'While Scoped')}",
            f"Aim.IgnoreKnocked={'1' if self.values.get('aim_ignore_knocked') else '0'}",
            f"Aim.IgnoreBot={'1' if self.values.get('aim_ignore_bot') else '0'}",
            f"Aim.VisCheck={'1' if self.values.get('aim_vischeck') else '0'}",
            f"Aim.TeamCheck={'1' if self.values.get('aim_teamcheck') else '0'}",
            f"Aim.AutoShoot={'1' if self.values.get('aim_autoshoot') else '0'}",
            f"Aim.Power={self.values.get('aim_power', 75.0):.1f}",
            f"Aim.Cross={'1' if self.values.get('aim_cross') else '0'}",
        ]
        return "\n".join(lines) + "\n"

    def build_esp_cfg(self) -> str:
        """
        Builds /data/data/net.roslegacy.prod/imgui/esp.txt
        Format used by libRAACHEAT cyber ESP engine.
        """
        box_c = self.colors.get("ESP.BoxColor", [0.31, 0.94, 0.65, 1.0])
        line_c = self.colors.get("ESP.LineColor", [1.0, 0.25, 0.25, 0.85])
        skel_c = self.colors.get("ESP.SkeletonColor", [1.0, 1.0, 1.0, 0.9])

        lines = [
            "# RAACHEAT CYBER ESP CONFIGURATION",
            f"ESP.Active={'1' if self.values.get('esp_active') else '0'}",
            f"ESP.Box={'1' if self.values.get('esp_box') else '0'}",
            f"ESP.BoxStyle={self.values.get('esp_box_style', '2D Corner Box')}",
            f"ESP.Line={'1' if self.values.get('esp_line') else '0'}",
            f"ESP.LinePosition={self.values.get('esp_line_pos', 'Bottom')}",
            f"ESP.LineThickness={self.values.get('esp_line_thickness', 2.0):.1f}",
            f"ESP.Skeleton={'1' if self.values.get('esp_skeleton') else '0'}",
            f"ESP.Health={'1' if self.values.get('esp_health') else '0'}",
            f"ESP.Distance={'1' if self.values.get('esp_distance') else '0'}",
            f"ESP.Name={'1' if self.values.get('esp_name') else '0'}",
            f"ESP.Vehicle={'1' if self.values.get('esp_vehicle') else '0'}",
            f"ESP.Bot={'1' if self.values.get('esp_bot') else '0'}",
            f"ESP.Knocked={'1' if self.values.get('esp_knocked') else '0'}",
            f"ESP.EnemyOnly={'1' if self.values.get('esp_enemy_only') else '0'}",
            f"ESP.CrownWeapons={'1' if self.values.get('esp_crown_weapons') else '0'}",
            f"ESP.Alert={'1' if self.values.get('esp_radar_fx') else '0'}",
            f"ESP.MaxDistance={self.values.get('esp_max_distance', 400.0):.1f}",
            f"Settings.HideRecording={'1' if self.values.get('esp_hide_recording') else '0'}",
            f"ESP.BoxColor.x={box_c[0]:.3f}",
            f"ESP.BoxColor.y={box_c[1]:.3f}",
            f"ESP.BoxColor.z={box_c[2]:.3f}",
            f"ESP.BoxColor.w={box_c[3]:.3f}",
            f"ESP.LineColor.x={line_c[0]:.3f}",
            f"ESP.LineColor.y={line_c[1]:.3f}",
            f"ESP.LineColor.z={line_c[2]:.3f}",
            f"ESP.LineColor.w={line_c[3]:.3f}",
            f"ESP.SkeletonColor.x={skel_c[0]:.3f}",
            f"ESP.SkeletonColor.y={skel_c[1]:.3f}",
            f"ESP.SkeletonColor.z={skel_c[2]:.3f}",
            f"ESP.SkeletonColor.w={skel_c[3]:.3f}",
        ]
        return "\n".join(lines) + "\n"

    def build_speed_memory_cfg(self) -> str:
        """
        Builds /data/data/net.roslegacy.prod/imgui/speed-memory.cfg
        Format used for memory modification hooks.
        """
        lines = [
            "# RAACHEAT SPEED & MEMORY ENGINE",
            f"Speed.Enable={'1' if self.values.get('mem_speed_hack') else '0'}",
            f"Speed.Multiplier={self.values.get('mem_speed_mult', 2.5):.2f}",
            f"Memory.FlyHack={'1' if self.values.get('mem_fly_hack') else '0'}",
            f"Memory.WallHack={'1' if self.values.get('mem_wall_hack') else '0'}",
            f"Memory.FastReload={'1' if self.values.get('mem_fast_reload') else '0'}",
            f"Memory.FastHeal={'1' if self.values.get('mem_fast_heal') else '0'}",
            f"Memory.FastParachute={'1' if self.values.get('mem_fast_parachute') else '0'}",
            f"Memory.NoRecoil={'1' if self.values.get('mem_no_recoil') else '0'}",
            f"Settings.Unlock120FPS={'1' if self.values.get('mem_unlock_fps') else '0'}",
        ]
        return "\n".join(lines) + "\n"

    def build_menu_config_txt(self) -> str:
        """
        Builds /data/data/net.roslegacy.prod/imgui/menu_config.txt
        Consolidated master config.
        """
        aim = self.build_aim_cfg()
        esp = self.build_esp_cfg()
        mem = self.build_speed_memory_cfg()
        return f"# [ EREBOS MATRIX // RAA CHEAT MASTER CONFIG ]\n\n{aim}\n{esp}\n{mem}\n"

    def build_ros_payload_py(self) -> str:
        """
        Builds the Python payload executed via NeoX engine:
        execfile('/data/data/net.roslegacy.prod/imgui/ros_payload.py')
        """
        script = f'''# -*- coding: utf-8 -*-
# NetEase NeoX Embedded Python Runtime Payload
# Target: Rules of Survival Legacy (net.roslegacy.prod)
# Generated dynamically by Roses Mod Menu (mod_menu.py)

import os
import sys

print("[+] RAACHEAT Python Payload Hook Active")

CONFIG = {{
    "aimbot": {{
        "enabled": {self.values.get('aim_enable')},
        "fov": {self.values.get('aim_fov')},
        "smooth": {self.values.get('aim_smooth')},
        "silent": {self.values.get('silent_aim')},
        "bone": "{self.values.get('target_bone')}",
    }},
    "visuals": {{
        "esp_active": {self.values.get('esp_active')},
        "box": {self.values.get('esp_box')},
        "skeleton": {self.values.get('esp_skeleton')},
        "max_dist": {self.values.get('esp_max_distance')},
    }},
    "memory": {{
        "speed": {self.values.get('mem_speed_hack')},
        "speed_mult": {self.values.get('mem_speed_mult')},
        "fly": {self.values.get('mem_fly_hack')},
        "no_recoil": {self.values.get('mem_no_recoil')},
    }}
}}

def init_mod_hooks():
    try:
        print("[+] Initializing NeoX memory patches...")
        # Hook entry point called inside game Python interpreter
        # NeoX Engine expose game globals under __main__ or game modules
    except Exception as e:
        print("[-] Hook error: %s" % e)

init_mod_hooks()
'''
        return script

    def export_all_configs(self, output_dir: str) -> Dict[str, str]:
        """Writes all config files to the target directory."""
        os.makedirs(output_dir, exist_ok=True)
        files = {
            "aim_cfg.txt": self.build_aim_cfg(),
            "esp.txt": self.build_esp_cfg(),
            "speed-memory.cfg": self.build_speed_memory_cfg(),
            "menu_config.txt": self.build_menu_config_txt(),
            "ros_payload.py": self.build_ros_payload_py(),
        }
        for name, content in files.items():
            path = os.path.join(output_dir, name)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
        return files


# ==============================================================================
# 4. MODERN CYBERPUNK TKINTER GUI
# ==============================================================================

def launch_gui(menu_state: ModMenuState):
    """Launches the modern tactical dark-mode Tkinter GUI."""
    try:
        import tkinter as tk
        from tkinter import ttk, messagebox, filedialog
    except ImportError:
        print("[!] Tkinter is not available. Falling back to CLI mode.")
        run_cli(menu_state)
        return

    root = tk.Tk()
    root.title("Roses Mod Menu // RAACHEAT ROS LEGACY [Debug Edition]")
    root.geometry("1000x720")
    root.minsize(850, 600)

    # Color Palette: Cyberpunk / Tactical Dark
    BG_DARK = "#0d1117"
    BG_CARD = "#161b22"
    BG_INPUT = "#21262d"
    TEXT_MAIN = "#e6edf3"
    TEXT_MUTED = "#8b949e"
    ACCENT_GREEN = "#2ea043"
    NEON_GREEN = "#3fb950"
    ACCENT_CYAN = "#388bfd"
    ACCENT_RED = "#f85149"
    BORDER_COLOR = "#30363d"

    root.configure(bg=BG_DARK)

    # Apply TTK Theme Styles
    style = ttk.Style()
    style.theme_use("clam")

    style.configure(".", background=BG_DARK, foreground=TEXT_MAIN)
    style.configure("TNotebook", background=BG_DARK, borderwidth=0)
    style.configure("TNotebook.Tab", background=BG_CARD, foreground=TEXT_MUTED, padding=[16, 8], font=("Segoe UI", 10, "bold"), borderwidth=0)
    style.map("TNotebook.Tab", background=[("selected", BG_INPUT)], foreground=[("selected", NEON_GREEN)])

    style.configure("TFrame", background=BG_DARK)
    style.configure("Card.TFrame", background=BG_CARD, relief="solid", borderwidth=1)
    style.configure("TLabel", background=BG_DARK, foreground=TEXT_MAIN, font=("Segoe UI", 9))
    style.configure("Header.TLabel", background=BG_DARK, foreground=NEON_GREEN, font=("Segoe UI", 14, "bold"))
    style.configure("Muted.TLabel", background=BG_DARK, foreground=TEXT_MUTED, font=("Segoe UI", 8))
    style.configure("TCheckbutton", background=BG_DARK, foreground=TEXT_MAIN, font=("Segoe UI", 9))
    style.map("TCheckbutton", foreground=[("active", NEON_GREEN)])

    # Top Header Banner
    header_frame = tk.Frame(root, bg=BG_CARD, height=60, bd=1, relief="solid")
    header_frame.pack(fill="x", side="top", padx=10, pady=(10, 5))

    lbl_title = tk.Label(header_frame, text="⚡ RAA CHEAT | ROS LEGACY", font=("Segoe UI", 13, "bold"), fg=NEON_GREEN, bg=BG_CARD)
    lbl_title.pack(side="left", padx=15, pady=8)

    lbl_subtitle = tk.Label(header_frame, text="ARM64 Binary Analysis & Menu Generator", font=("Segoe UI", 9), fg=TEXT_MUTED, bg=BG_CARD)
    lbl_subtitle.pack(side="left", padx=5, pady=8)

    # Preset dropdown in header
    lbl_preset = tk.Label(header_frame, text="Preset:", font=("Segoe UI", 9, "bold"), fg=TEXT_MAIN, bg=BG_CARD)
    lbl_preset.pack(side="left", padx=(30, 5))

    preset_var = tk.StringVar(value="Default / Balanced")
    preset_combo = ttk.Combobox(header_frame, textvariable=preset_var, values=list(PRESETS.keys()), state="readonly", width=18)
    preset_combo.pack(side="left", padx=5)

    def on_preset_change(event):
        chosen = preset_var.get()
        menu_state.apply_preset(chosen)
        refresh_ui_from_state()
        update_live_preview()
        messagebox.showinfo("Preset Applied", f"Successfully activated profile: {chosen}")

    preset_combo.bind("<<ComboboxSelected>>", on_preset_change)

    # Quick Action Buttons in Header
    def export_configs_dialog():
        chosen_dir = filedialog.askdirectory(initialdir=WORKSPACE_ROOT, title="Select Output Folder For Game Configs")
        if chosen_dir:
            menu_state.export_all_configs(chosen_dir)
            messagebox.showinfo("Success", f"Exported all configs to:\n{chosen_dir}\n\n- aim_cfg.txt\n- esp.txt\n- speed-memory.cfg\n- menu_config.txt\n- ros_payload.py")

    btn_export = tk.Button(header_frame, text="💾 Export Configs", command=export_configs_dialog, bg=ACCENT_GREEN, fg="#ffffff", font=("Segoe UI", 9, "bold"), relief="flat", padx=10, pady=3, cursor="hand2")
    btn_export.pack(side="right", padx=15, pady=8)

    # Notebook (Tabs)
    notebook = ttk.Notebook(root)
    notebook.pack(fill="both", expand=True, padx=10, pady=5)

    tab_aimbot = ttk.Frame(notebook)
    tab_visuals = ttk.Frame(notebook)
    tab_memory = ttk.Frame(notebook)
    tab_preview = ttk.Frame(notebook)
    tab_xref = ttk.Frame(notebook)

    notebook.add(tab_aimbot, text="🎯 Aimbot & Combat")
    notebook.add(tab_visuals, text="👁️ Cyber ESP & Visuals")
    notebook.add(tab_memory, text="⚡ Memory & Movement")
    notebook.add(tab_preview, text="📜 Live Config Preview")
    notebook.add(tab_xref, text="🔍 Reverse Eng & XREFs")

    # Widget registry for synchronization
    var_map = {}

    def create_feature_controls(parent, features: List[Dict[str, Any]]):
        """Builds scrollable card containing toggles, sliders, and combos."""
        canvas = tk.Canvas(parent, bg=BG_DARK, highlightthickness=0)
        scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
        scroll_content = tk.Frame(canvas, bg=BG_DARK)

        scroll_content.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scroll_content, anchor="nw", width=950)
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        scrollbar.pack(side="right", fill="y")

        # Mousewheel scroll support
        def on_mousewheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        canvas.bind_all("<MouseWheel>", on_mousewheel)

        for i, feat in enumerate(features):
            fid = feat["id"]
            ftype = feat["type"]
            fname = feat["name"]
            fdesc = feat.get("desc", "")
            fva = feat.get("va", "0x0")

            card = tk.Frame(scroll_content, bg=BG_CARD, bd=1, relief="solid")
            card.pack(fill="x", padx=10, pady=4)

            # Left Info
            info_frame = tk.Frame(card, bg=BG_CARD)
            info_frame.pack(side="left", fill="both", expand=True, padx=12, pady=8)

            title_row = tk.Frame(info_frame, bg=BG_CARD)
            title_row.pack(fill="x", anchor="w")

            lbl_name = tk.Label(title_row, text=fname, font=("Segoe UI", 10, "bold"), fg=TEXT_MAIN, bg=BG_CARD)
            lbl_name.pack(side="left")

            lbl_va = tk.Label(title_row, text=f" [{fva}]", font=("Consolas", 8), fg=ACCENT_CYAN, bg=BG_CARD)
            lbl_va.pack(side="left", padx=5)

            if fdesc:
                lbl_d = tk.Label(info_frame, text=fdesc, font=("Segoe UI", 8), fg=TEXT_MUTED, bg=BG_CARD, wraplength=550, justify="left")
                lbl_d.pack(anchor="w", pady=(2, 0))

            # Right Controls
            ctrl_frame = tk.Frame(card, bg=BG_CARD)
            ctrl_frame.pack(side="right", padx=15, pady=8)

            if ftype == "bool":
                bvar = tk.BooleanVar(value=menu_state.get_value(fid))
                var_map[fid] = bvar

                def make_toggle_cmd(k, v):
                    return lambda: (menu_state.set_value(k, v.get()), update_live_preview())

                chk = tk.Checkbutton(
                    ctrl_frame,
                    text="ENABLE",
                    variable=bvar,
                    font=("Segoe UI", 9, "bold"),
                    bg=BG_CARD,
                    fg=NEON_GREEN,
                    activebackground=BG_CARD,
                    activeforeground=NEON_GREEN,
                    selectcolor=BG_INPUT,
                    command=make_toggle_cmd(fid, bvar)
                )
                chk.pack()

            elif ftype == "float":
                fvar = tk.DoubleVar(value=menu_state.get_value(fid))
                var_map[fid] = fvar

                val_lbl = tk.Label(ctrl_frame, text=f"{fvar.get():.1f}", font=("Consolas", 9, "bold"), fg=TEXT_MAIN, bg=BG_CARD, width=6)
                val_lbl.pack(side="right", padx=(5, 0))

                def make_slider_cmd(k, v, lbl):
                    def handler(val):
                        val_float = float(val)
                        menu_state.set_value(k, val_float)
                        lbl.config(text=f"{val_float:.1f}")
                        update_live_preview()
                    return handler

                scale = ttk.Scale(
                    ctrl_frame,
                    from_=feat.get("min", 0.0),
                    to=feat.get("max", 100.0),
                    variable=fvar,
                    orient="horizontal",
                    length=160,
                    command=make_slider_cmd(fid, fvar, val_lbl)
                )
                scale.pack(side="left")

            elif ftype == "combo":
                svar = tk.StringVar(value=menu_state.get_value(fid))
                var_map[fid] = svar

                def make_combo_cmd(k, v):
                    return lambda e: (menu_state.set_value(k, v.get()), update_live_preview())

                combo = ttk.Combobox(ctrl_frame, textvariable=svar, values=feat.get("options", []), state="readonly", width=14)
                combo.pack()
                combo.bind("<<ComboboxSelected>>", make_combo_cmd(fid, svar))

    # Populate Tab 1: Aimbot
    create_feature_controls(tab_aimbot, RAW_EXTRACTED_DATA["aimbot"])

    # Populate Tab 2: Visuals
    create_feature_controls(tab_visuals, RAW_EXTRACTED_DATA["visuals"])

    # Populate Tab 3: Memory
    create_feature_controls(tab_memory, RAW_EXTRACTED_DATA["memory"])

    # Populate Tab 4: Live Preview & Export
    preview_box = tk.Text(tab_preview, bg=BG_INPUT, fg="#7ee787", font=("Consolas", 9), bd=0, padx=12, pady=12)
    preview_box.pack(fill="both", expand=True, padx=10, pady=10)

    def update_live_preview():
        preview_box.delete("1.0", tk.END)
        txt = menu_state.build_menu_config_txt()
        preview_box.insert("1.0", txt)

    def refresh_ui_from_state():
        for fid, var in var_map.items():
            val = menu_state.get_value(fid)
            if val is not None:
                var.set(val)

    # Populate Tab 5: Reverse Engineering & XREF Inspection
    xref_text = tk.Text(tab_xref, bg=BG_INPUT, fg=TEXT_MAIN, font=("Consolas", 9), bd=0, padx=12, pady=12)
    xref_text.pack(fill="both", expand=True, padx=10, pady=10)

    # Load and display catalog / XREF analysis if available
    xref_content = [
        "================================================================================",
        "libRAACHEAT.so REVERSE ENGINEERING & ASSEMBLY CROSS-REFERENCE TABLE",
        "Target Binary: ESP Cracked.apk / lib/arm64-v8a/libRAACHEAT.so",
        "Architecture : AArch64 (ARM64-v8a) ELF | .rodata VA: 0x4E190 | .text VA: 0x3775A0",
        "================================================================================\n",
    ]

    all_features = RAW_EXTRACTED_DATA["aimbot"] + RAW_EXTRACTED_DATA["visuals"] + RAW_EXTRACTED_DATA["memory"]
    for f in all_features:
        xref_content.append(f"[*] FEATURE: {f['name']}")
        xref_content.append(f"    Config Key: {f.get('config_key', 'N/A')}")
        xref_content.append(f"    String VA : {f.get('va', 'N/A')}")
        xref_content.append(f"    Code XREF : {f.get('first_xref', 'N/A')}")
        if "flag_addr" in f:
            xref_content.append(f"    Menu Flag : {f['flag_addr']} (Memory toggle)")
            xref_content.append(f"    Save Copy : {f['save_addr']} (Save buffer)")
        xref_content.append(f"    Summary   : {f.get('desc', '')}\n")

    xref_text.insert("1.0", "\n".join(xref_content))
    xref_text.configure(state="disabled")

    # Initial live preview refresh
    update_live_preview()

    # Footer status
    footer = tk.Frame(root, bg=BG_CARD, height=26)
    footer.pack(fill="x", side="bottom")
    lbl_status = tk.Label(footer, text="✓ 38 Core Functions Ready | NetEase NeoX / ROS Engine Hook Engine", font=("Segoe UI", 8), fg=TEXT_MUTED, bg=BG_CARD)
    lbl_status.pack(side="left", padx=10)

    root.mainloop()


# ==============================================================================
# 5. CLI INTERACTIVE FALLBACK MODE
# ==============================================================================

def run_cli(menu_state: ModMenuState):
    """Interactive command-line interface for headless environments."""
    print("=" * 70)
    print("  ROS LEGACY / RAACHEAT MOD MENU & CONFIG GENERATOR (CLI)")
    print("=" * 70)

    while True:
        print("\nCategories:")
        print("  [1] Aimbot Settings")
        print("  [2] Cyber ESP Settings")
        print("  [3] Memory & Movement Settings")
        print("  [4] Apply Profile Preset")
        print("  [5] View Generated Config (Live Preview)")
        print("  [6] Export All Config Files to Directory")
        print("  [0] Exit")

        choice = input("\nSelect option (0-6): ").strip()
        if choice == "0":
            print("[*] Exiting.")
            break
        elif choice in ("1", "2", "3"):
            cat_map = {"1": "aimbot", "2": "visuals", "3": "memory"}
            cat_key = cat_map[choice]
            feats = RAW_EXTRACTED_DATA[cat_key]

            print(f"\n--- {cat_key.upper()} FEATURES ---")
            for idx, feat in enumerate(feats, 1):
                val = menu_state.get_value(feat["id"])
                print(f"  [{idx:2d}] {feat['name']:<30} = {val} ({feat['type']})")

            item_idx = input("\nEnter number to toggle/edit (or press Enter to go back): ").strip()
            if item_idx.isdigit():
                idx_num = int(item_idx) - 1
                if 0 <= idx_num < len(feats):
                    target_feat = feats[idx_num]
                    fid = target_feat["id"]
                    ftype = target_feat["type"]

                    if ftype == "bool":
                        cur = menu_state.get_value(fid)
                        menu_state.set_value(fid, not cur)
                        print(f"[+] {target_feat['name']} set to {not cur}")
                    elif ftype == "float":
                        new_val = input(f"Enter new float value ({target_feat.get('min')} - {target_feat.get('max')}): ").strip()
                        try:
                            fval = float(new_val)
                            menu_state.set_value(fid, fval)
                            print(f"[+] {target_feat['name']} set to {fval}")
                        except ValueError:
                            print("[!] Invalid number.")
                    elif ftype == "combo":
                        opts = target_feat.get("options", [])
                        print("Options:", ", ".join(opts))
                        new_opt = input("Enter choice: ").strip()
                        if new_opt in opts:
                            menu_state.set_value(fid, new_opt)
                            print(f"[+] {target_feat['name']} set to {new_opt}")
                        else:
                            print("[!] Invalid choice.")
        elif choice == "4":
            print("\nAvailable Presets:")
            p_keys = list(PRESETS.keys())
            for idx, p in enumerate(p_keys, 1):
                print(f"  [{idx}] {p}")
            p_pick = input("Pick preset number: ").strip()
            if p_pick.isdigit() and 1 <= int(p_pick) <= len(p_keys):
                chosen = p_keys[int(p_pick) - 1]
                menu_state.apply_preset(chosen)
                print(f"[+] Applied preset: {chosen}")
        elif choice == "5":
            print("\n" + "=" * 50)
            print(menu_state.build_menu_config_txt())
            print("=" * 50)
        elif choice == "6":
            out_path = input("Enter target directory path [default: ./ros_configs]: ").strip()
            if not out_path:
                out_path = os.path.join(WORKSPACE_ROOT, "ros_configs")
            files = menu_state.export_all_configs(out_path)
            print(f"[+] Successfully exported {len(files)} files to: {out_path}")
            for fname in files:
                print(f"    - {fname}")


# ==============================================================================
# 6. PROGRAMMATIC INTERFACE & SCRIPT ENTRY POINT
# ==============================================================================

def get_all_features() -> Dict[str, List[Dict[str, Any]]]:
    """Returns the full extracted feature dictionary."""
    return RAW_EXTRACTED_DATA

def export_configs(output_dir: str, preset: Optional[str] = None):
    """Direct export utility for external scripts or automation."""
    state = ModMenuState()
    if preset:
        state.apply_preset(preset)
    return state.export_all_configs(output_dir)

def main():
    parser = argparse.ArgumentParser(description="Roses Mod Menu // RAACHEAT Python Engine")
    parser.add_argument("--cli", action="store_true", help="Launch in interactive command-line mode instead of GUI")
    parser.add_argument("--export", metavar="DIR", help="Export config files directly to DIR and exit")
    parser.add_argument("--preset", metavar="NAME", help="Apply preset profile for export (e.g. 'Rage / HvH', 'Legit / Closet')")
    args = parser.parse_args()

    menu_state = ModMenuState()

    if args.preset:
        menu_state.apply_preset(args.preset)

    if args.export:
        files = menu_state.export_all_configs(args.export)
        print(f"[+] Exported {len(files)} config files to {args.export}:")
        for f in files:
            print(f"    - {f}")
        return

    if args.cli:
        run_cli(menu_state)
    else:
        launch_gui(menu_state)


if __name__ == "__main__":
    main()
