#!/usr/bin/env python3
"""Focused catalog and export checks for Spectral Sight and Sting."""

from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path


WORKBENCH = Path(__file__).resolve().parent


def load_module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, WORKBENCH / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module("cartesia_validator", "validate-cartesia-samples.py")
exporter = load_module("addon_exporter", "export-addon-cartesia-assets.py")


class SpectralSightTests(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(
            (WORKBENCH / "cartesia-pack-manifest.json").read_text(encoding="utf-8")
        )

    def test_full_catalog_is_valid(self):
        self.assertEqual(validator.validate_manifest(self.manifest), [])
        exporter.validate_catalog(self.manifest)
        self.assertEqual(len(self.manifest["phrases"]), 80)

    def test_existing_phrase_metadata_is_unchanged(self):
        faction = json.loads(validator.FACTION_MANIFEST.read_text(encoding="utf-8"))
        baseline = [
            phrase for phrase in self.manifest["phrases"]
            if phrase["id"] not in {"spectral-sight", "chimaeral-sting"}
        ]
        self.assertEqual(baseline, faction["phrases"])

    def test_missing_duplicate_or_incorrect_addition_is_rejected(self):
        for mutation in ("missing", "duplicate", "spell", "category", "text", "spec"):
            with self.subTest(mutation=mutation):
                manifest = copy.deepcopy(self.manifest)
                phrase = next(
                    item for item in manifest["phrases"]
                    if item["id"] == "spectral-sight"
                )
                if mutation == "missing":
                    manifest["phrases"].remove(phrase)
                elif mutation == "duplicate":
                    manifest["phrases"].append(copy.deepcopy(phrase))
                elif mutation == "spell":
                    phrase["spellIds"] = [188502]
                elif mutation == "category":
                    phrase["category"] = "offensive"
                elif mutation == "text":
                    phrase["spokenText"] = "Sight"
                else:
                    phrase["specIds"] = [577]
                self.assertTrue(validator.validate_manifest(manifest))

    def test_duplicate_spell_ownership_is_rejected(self):
        self.manifest["phrases"][0]["spellIds"].append(188501)
        with self.assertRaisesRegex(ValueError, "belongs to both"):
            exporter.validate_catalog(self.manifest)

    def test_runtime_maps_to_demon_hunter_opponents(self):
        callouts = exporter.runtime_callouts(self.manifest)
        self.assertEqual(len(callouts), 70)
        spectral = next(item for item in callouts if item["id"] == "spectral-sight")
        self.assertEqual(spectral, validator.SPECTRAL_SIGHT_PHRASE)
        self.assertEqual(exporter.class_file(spectral), "DEMONHUNTER")
        self.assertNotIn("unitTokens", spectral)
        self.assertIn(188501, exporter.ARENA_OPPONENT_BUFF_SPELL_IDS)
        self.assertNotIn(188501, exporter.FRIENDLY_TARGET_DEBUFF_SPELL_IDS)
        self.assertEqual(len(exporter.RUNTIME_AURA_SPELL_IDS), 75)

    def test_promoted_pack_matches_runtime_export(self):
        source = exporter.DEFAULT_SOURCE
        promoted_manifest = json.loads(
            (source / "cartesia-pack-manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(promoted_manifest, self.manifest)
        manifest, report = exporter.load_inputs(source)
        self.assertEqual(manifest, self.manifest)
        sources = exporter.expected_source_files(source, manifest)
        expected_lua = exporter.generate_lua(
            exporter.runtime_callouts(manifest),
            exporter.sha256(source / "cartesia-pack-manifest.json"),
        )
        exporter.validate_export(
            exporter.DEFAULT_SOUNDS, exporter.DEFAULT_DATA,
            manifest, sources, expected_lua,
        )
        hashes = exporter.report_hashes(report)
        for voice in ("alliance", "horde"):
            for callout_id in ("spectral-sight", "chimaeral-sting"):
                path = sources[(voice, callout_id)]
                self.assertEqual(exporter.sha256(path), hashes[path.name])

    def test_sting_maps_initial_debuff_to_friendly_team(self):
        callouts = exporter.runtime_callouts(self.manifest)
        sting = next(item for item in callouts if item["id"] == "chimaeral-sting")
        self.assertEqual(sting["spokenText"], "Sting")
        self.assertEqual(sting["spellIds"], [356723])
        self.assertEqual(sting["castSpellIds"], [356719])
        self.assertEqual(sting["unitTokens"], ["player", "party1", "party2"])
        self.assertEqual(exporter.class_file(sting), "HUNTER")
        self.assertNotIn(356723, exporter.ARENA_OPPONENT_BUFF_SPELL_IDS)
        self.assertNotIn(356719, exporter.RUNTIME_AURA_SPELL_IDS)
        self.assertNotIn(356727, exporter.RUNTIME_AURA_SPELL_IDS)

    def test_sting_cast_id_or_silence_cannot_replace_initial_aura(self):
        for spell_id in (356719, 356727):
            with self.subTest(spell_id=spell_id):
                manifest = copy.deepcopy(self.manifest)
                sting = next(
                    item for item in manifest["phrases"]
                    if item["id"] == "chimaeral-sting"
                )
                sting["spellIds"] = [spell_id]
                self.assertTrue(validator.validate_manifest(manifest))
                with self.assertRaisesRegex(ValueError, "runtime aura callouts"):
                    exporter.runtime_callouts(manifest)

    def test_generated_sting_data_uses_friendly_scope(self):
        lua = exporter.generate_lua(exporter.runtime_callouts(self.manifest), "test")
        start = lua.index('        id = "chimaeral-sting",')
        end = lua.index("    },", start)
        entry = lua[start:end]
        self.assertIn('classFile = "HUNTER"', entry)
        self.assertIn('spokenText = "Sting"', entry)
        self.assertIn('soundFileName = "chimaeral-sting.ogg"', entry)
        self.assertIn("spellIDs = { 356723 }", entry)
        self.assertIn('unitTokens = { "player", "party1", "party2" }', entry)
        self.assertNotIn("356719", entry)
        self.assertNotIn("356727", entry)

    def test_generated_data_uses_spectral_sound_file(self):
        lua = exporter.generate_lua(exporter.runtime_callouts(self.manifest), "test")
        start = lua.index('        id = "spectral-sight",')
        end = lua.index("    },", start)
        entry = lua[start:end]
        self.assertIn('classFile = "DEMONHUNTER"', entry)
        self.assertIn('soundFileName = "spectral-sight.ogg"', entry)
        self.assertIn("iconSpellID = 188501", entry)
        self.assertIn("spellIDs = { 188501 }", entry)
        self.assertNotIn("unitTokens", entry)
        self.assertEqual(exporter.EXPECTED_OGGS, 160)
        self.assertEqual(set(exporter.VOICE_SOURCES), {"alliance", "horde"})


if __name__ == "__main__":
    unittest.main()
