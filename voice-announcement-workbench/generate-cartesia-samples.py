#!/usr/bin/env python3
"""Discover neutral Cartesia stock voices and generate a four-phrase bake-off."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import certifi

from audio_workbench import inspect_audio, master_audio, write_listening_page


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "cartesia-sample-manifest.json"
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "cartesia-bakeoff"
KEY_ENV = "CARTESIA_API_KEY"


class AuthenticationError(RuntimeError):
    pass


@dataclass(frozen=True)
class VoiceChoice:
    blind_id: str
    blind_name: str
    voice_id: str
    name: str
    gender: str
    score: int
    metadata: dict[str, Any]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument("--discover-only", action="store_true")
    parser.add_argument("--shortlist-only", action="store_true")
    parser.add_argument("--speaker", choices=("masculine", "feminine", "voice-a", "voice-b"))
    parser.add_argument("--phrase")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--remaster", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1 or manifest.get("scope") != "comparison":
        raise ValueError("Cartesia manifest must use schemaVersion 1 and comparison scope")
    if manifest.get("model", {}).get("id") != "sonic-3.6":
        raise ValueError("Cartesia comparison must pin sonic-3.6")
    if len(manifest.get("phrases", [])) != 4:
        raise ValueError("Cartesia comparison requires four phrases")
    if set(manifest.get("selection", {}).get("requiredGenders", [])) != {
        "masculine",
        "feminine",
    }:
        raise ValueError("Cartesia comparison requires masculine and feminine voices")
    return manifest


def api_key() -> str:
    value = os.environ.get(KEY_ENV)
    if not value:
        raise RuntimeError(
            "CARTESIA_API_KEY is not set. Export it before running Cartesia discovery."
        )
    return value


def headers(
    manifest: dict[str, Any],
    auth_scheme: str,
    *,
    json_body: bool = False,
) -> dict[str, str]:
    result = {
        "Cartesia-Version": str(manifest["api"]["version"]),
        "Accept": "application/json",
        "User-Agent": "SweepyBoop-Voice-Workbench/1",
    }
    if auth_scheme == "bearer":
        result["Authorization"] = f"Bearer {api_key()}"
    elif auth_scheme == "x-api-key":
        result["X-API-Key"] = api_key()
    else:
        raise ValueError(f"Unsupported Cartesia authentication scheme: {auth_scheme}")
    if json_body:
        result["Content-Type"] = "application/json"
    return result


def http_request(
    request: urllib.request.Request,
    *,
    attempts: int = 4,
) -> tuple[bytes, dict[str, str]]:
    for attempt in range(attempts):
        try:
            context = ssl.create_default_context(cafile=certifi.where())
            with urllib.request.urlopen(request, timeout=90, context=context) as response:
                return response.read(), dict(response.headers.items())
        except urllib.error.HTTPError as error:
            if error.code in (401, 403):
                raise AuthenticationError(
                    f"Cartesia authentication/permission failed with HTTP {error.code}"
                ) from error
            if error.code == 429 or 500 <= error.code < 600:
                if attempt + 1 < attempts:
                    retry_after = error.headers.get("Retry-After")
                    delay = float(retry_after) if retry_after else float(2**attempt)
                    time.sleep(min(delay, 16.0))
                    continue
            body = error.read(400).decode("utf-8", errors="replace")
            raise RuntimeError(f"Cartesia HTTP {error.code}: {body}") from error
        except urllib.error.URLError as error:
            if attempt + 1 < attempts:
                time.sleep(float(2**attempt))
                continue
            raise RuntimeError(f"Cartesia network request failed: {error.reason}") from error
    raise RuntimeError("Cartesia request exhausted retries")


def authenticated_request(
    manifest: dict[str, Any],
    url: str,
    *,
    method: str,
    data: bytes | None = None,
    json_body: bool = False,
) -> tuple[bytes, dict[str, str], str]:
    failures: list[str] = []
    for scheme in manifest["api"]["authenticationOrder"]:
        request = urllib.request.Request(
            url,
            data=data,
            headers=headers(manifest, scheme, json_body=json_body),
            method=method,
        )
        try:
            body, response_headers = http_request(request)
            return body, response_headers, str(scheme)
        except AuthenticationError as error:
            failures.append(f"{scheme}: {error}")
    raise AuthenticationError(
        "Cartesia rejected every configured authentication scheme: "
        + "; ".join(failures)
    )


def catalog_entries(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        for field in ("data", "voices", "items"):
            value = payload.get(field)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
    raise ValueError("Unexpected Cartesia voices response shape")


def sanitize_voice(voice: dict[str, Any]) -> dict[str, Any]:
    allowed = (
        "id",
        "name",
        "description",
        "gender",
        "language",
        "languages",
        "locale",
        "accent",
        "tags",
        "is_public",
        "is_owner",
        "is_stock",
        "voice_type",
        "created_at",
    )
    return {field: voice.get(field) for field in allowed if field in voice}


def discover(manifest: dict[str, Any], reports: Path) -> list[dict[str, Any]]:
    url = manifest["api"]["baseUrl"] + manifest["api"]["voicesPath"]
    raw, response_headers, auth_scheme = authenticated_request(
        manifest,
        url,
        method="GET",
    )
    payload = json.loads(raw.decode("utf-8"))
    voices = [sanitize_voice(item) for item in catalog_entries(payload)]
    report = {
        "fetchedUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "endpoint": url,
        "apiVersion": manifest["api"]["version"],
        "authenticationScheme": auth_scheme,
        "voiceCount": len(voices),
        "responseRequestId": response_headers.get("x-request-id"),
        "voices": voices,
    }
    reports.mkdir(parents=True, exist_ok=True)
    (reports / "voices-catalog-sanitized.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return voices


def normalized_gender(value: Any) -> str | None:
    text = str(value or "").casefold()
    if text in {"male", "masculine"}:
        return "masculine"
    if text in {"female", "feminine"}:
        return "feminine"
    return None


def combined_text(voice: dict[str, Any]) -> str:
    fields = (
        voice.get("name"),
        voice.get("description"),
        voice.get("accent"),
        voice.get("tags"),
        voice.get("voice_type"),
    )
    return json.dumps(fields, ensure_ascii=True).casefold()


def matching_terms(text: str, terms: list[str]) -> list[str]:
    return sorted(
        term
        for term in terms
        if re.search(rf"(?<!\\w){re.escape(term)}(?!\\w)", text)
    )


def is_english(voice: dict[str, Any]) -> bool:
    values = [voice.get("language"), voice.get("languages"), voice.get("locale")]
    text = json.dumps(values, ensure_ascii=True).casefold()
    return "english" in text or '"en"' in text or "en-us" in text or "en_us" in text


def stock_status(voice: dict[str, Any]) -> tuple[bool, str]:
    text = combined_text(voice)
    if any(term in text for term in ("clone", "cloned", "custom")):
        return False, "catalog metadata identifies a cloned/custom voice"
    if voice.get("is_stock") is False:
        return False, "is_stock is false"
    if voice.get("is_owner") is True and voice.get("is_public") is not True:
        return False, "private account-owned voice"
    if voice.get("is_public") is False:
        return False, "voice is not public"
    return True, "public/stock catalog voice"


def rank_voices(
    manifest: dict[str, Any],
    voices: list[dict[str, Any]],
) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    preferred = [str(value).casefold() for value in manifest["selection"]["preferredTerms"]]
    blocked = [str(value).casefold() for value in manifest["selection"]["blockedTerms"]]
    ranked: dict[str, list[dict[str, Any]]] = {"masculine": [], "feminine": []}
    excluded: list[dict[str, Any]] = []
    for voice in voices:
        voice_id = voice.get("id")
        gender = normalized_gender(voice.get("gender"))
        if not isinstance(voice_id, str) or not voice_id:
            excluded.append({"voice": voice, "reason": "missing voice id"})
            continue
        if gender not in ranked:
            excluded.append({"voice": voice, "reason": "unsupported or missing gender"})
            continue
        if not is_english(voice):
            excluded.append({"voice": voice, "reason": "not identified as English"})
            continue
        stock, stock_reason = stock_status(voice)
        if not stock:
            excluded.append({"voice": voice, "reason": stock_reason})
            continue
        text = combined_text(voice)
        blocked_matches = matching_terms(text, blocked)
        if blocked_matches:
            excluded.append(
                {"voice": voice, "reason": f"blocked style terms: {blocked_matches}"}
            )
            continue
        preferred_matches = matching_terms(text, preferred)
        score = len(preferred_matches) * 10
        if voice.get("is_public") is True:
            score += 3
        if voice.get("is_stock") is True:
            score += 3
        ranked[gender].append(
            {
                "voice": voice,
                "gender": gender,
                "score": score,
                "preferredMatches": preferred_matches,
                "stockReason": stock_reason,
            }
        )
    for gender in ranked:
        ranked[gender].sort(
            key=lambda item: (
                -int(item["score"]),
                str(item["voice"].get("name") or "").casefold(),
                str(item["voice"]["id"]),
            )
        )
    return ranked, excluded


def shortlist(
    manifest: dict[str, Any],
    reports: Path,
    voices: list[dict[str, Any]],
) -> list[VoiceChoice]:
    ranked, excluded = rank_voices(manifest, voices)
    missing = [gender for gender, values in ranked.items() if not values]
    shortlist_report = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "criteria": manifest["selection"],
        "ranked": ranked,
        "excludedCount": len(excluded),
        "excluded": excluded,
    }
    reports.mkdir(parents=True, exist_ok=True)
    (reports / "voices-shortlist.json").write_text(
        json.dumps(shortlist_report, indent=2) + "\n",
        encoding="utf-8",
    )
    if missing:
        (reports / "no-eligible-voices.json").write_text(
            json.dumps({"missingGenders": missing, **shortlist_report}, indent=2) + "\n",
            encoding="utf-8",
        )
        raise RuntimeError(f"No eligible Cartesia stock voices for: {', '.join(missing)}")

    choices: list[VoiceChoice] = []
    for index, gender in enumerate(("masculine", "feminine")):
        item = ranked[gender][0]
        voice = item["voice"]
        choices.append(
            VoiceChoice(
                blind_id=f"voice-{chr(ord('a') + index)}",
                blind_name=f"Voice {chr(ord('A') + index)}",
                voice_id=str(voice["id"]),
                name=str(voice.get("name") or voice["id"]),
                gender=gender,
                score=int(item["score"]),
                metadata=voice,
            )
        )
    (reports / "selected-voices.json").write_text(
        json.dumps(
            {
                "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "voices": [choice.__dict__ for choice in choices],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return choices


def load_selected(reports: Path) -> list[VoiceChoice]:
    payload = json.loads((reports / "selected-voices.json").read_text(encoding="utf-8"))
    return [VoiceChoice(**item) for item in payload["voices"]]


def canonical_fingerprint(body: dict[str, Any]) -> str:
    comparable = {key: value for key, value in body.items() if key != "voice"}
    encoded = json.dumps(comparable, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest().upper()


def tts_body(manifest: dict[str, Any], transcript: str, voice_id: str) -> dict[str, Any]:
    body = {
        "model_id": manifest["model"]["id"],
        "transcript": transcript,
        "voice": voice_id,
        "output_format": manifest["outputFormat"],
        "locale": manifest["locale"],
        "generation_config": manifest["generationConfig"],
    }
    return body


def generate_provider_audio(
    manifest: dict[str, Any],
    voice: VoiceChoice,
    phrase: dict[str, Any],
    destination: Path,
) -> dict[str, Any]:
    transcript = str(phrase["spokenText"])
    if transcript[-1:] not in ".!?":
        transcript += "."
    body = tts_body(manifest, transcript, voice.voice_id)
    started = time.perf_counter()
    raw, response_headers, auth_scheme = authenticated_request(
        manifest,
        manifest["api"]["baseUrl"] + manifest["api"]["ttsPath"],
        method="POST",
        data=json.dumps(body, separators=(",", ":")).encode("utf-8"),
        json_body=True,
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(raw)
    return {
        "generationSeconds": round(time.perf_counter() - started, 3),
        "generationUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "authenticationScheme": auth_scheme,
        "requestFingerprint": canonical_fingerprint(body),
        "requestBodyWithoutVoice": {
            key: value for key, value in body.items() if key != "voice"
        },
        "responseRequestId": response_headers.get("x-request-id"),
    }


def review_manifest(manifest: dict[str, Any], voices: list[VoiceChoice]) -> dict[str, Any]:
    return {
        "model": {"repository": f"Cartesia/{manifest['model']['id']}", "revision": manifest["api"]["version"]},
        "pack": {
            "description": (
                "Blind Cartesia stock-voice comparison. Male and female requests use "
                "identical text, model, format, speed, and volume settings."
            )
        },
        "speakers": [
            {"id": voice.blind_id, "displayName": voice.blind_name}
            for voice in voices
        ],
        "phrases": manifest["phrases"],
        "mastering": manifest["mastering"],
    }


def main() -> int:
    args = parse_args()
    manifest = load_manifest(args.manifest.resolve())
    scratch = args.scratch.resolve()
    reports = scratch / "reports"
    provider_dir = scratch / "provider-original"
    ogg_dir = scratch / "ogg"
    reports.mkdir(parents=True, exist_ok=True)

    if args.verify_only:
        api_key()
        print("Cartesia credential is available; no network request was made.")
        return 0

    catalog_path = reports / "voices-catalog-sanitized.json"
    if args.force or not catalog_path.is_file():
        voices = discover(manifest, reports)
    else:
        voices = json.loads(catalog_path.read_text(encoding="utf-8"))["voices"]
    if args.discover_only:
        print(f"Catalog report: {catalog_path}")
        return 0

    selected_path = reports / "selected-voices.json"
    if args.force or not selected_path.is_file():
        selected = shortlist(manifest, reports, voices)
    else:
        selected = load_selected(reports)
    if args.shortlist_only:
        print(f"Shortlist report: {reports / 'voices-shortlist.json'}")
        print(f"Selected voices: {selected_path}")
        return 0

    if args.speaker:
        selected = [
            choice
            for choice in selected
            if args.speaker in {choice.gender, choice.blind_id}
        ]
    phrases = [
        phrase
        for phrase in manifest["phrases"]
        if not args.phrase or args.phrase.casefold() == str(phrase["id"]).casefold()
    ]
    if not selected or not phrases:
        raise ValueError("The selected Cartesia filters produced no jobs")

    import imageio_ffmpeg

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe())
    prior_report_path = reports / "cartesia-run.json"
    prior_report = (
        json.loads(prior_report_path.read_text(encoding="utf-8"))
        if prior_report_path.is_file()
        else {}
    )
    prior_samples = {
        item.get("outputKey"): item for item in prior_report.get("samples", [])
    }
    samples: list[dict[str, Any]] = []
    for voice in selected:
        for phrase in phrases:
            output_key = f"{voice.blind_id}-{phrase['id']}-take-1"
            provider_path = provider_dir / f"{output_key}.wav"
            generation: dict[str, Any] = {}
            if args.force or not provider_path.is_file():
                print(f"Generating {output_key}: {phrase['spokenText']!r}", flush=True)
                generation = generate_provider_audio(
                    manifest,
                    voice,
                    phrase,
                    provider_path,
                )
            raw_info = inspect_audio(provider_path)
            ogg_path = ogg_dir / f"{output_key}.ogg"
            mastering = None
            if args.force or args.remaster or not ogg_path.is_file():
                print(f"Mastering {output_key}...", flush=True)
                mastering = master_audio(ffmpeg, provider_path, ogg_path, manifest)
            ogg_info = inspect_audio(ogg_path)
            previous = prior_samples.get(output_key)
            if previous and previous.get("providerOriginal", {}).get("sha256") == raw_info["sha256"]:
                if not generation:
                    generation = {
                        key: previous.get(key)
                        for key in (
                            "generationSeconds",
                            "generationUtc",
                            "authenticationScheme",
                            "requestFingerprint",
                            "requestBodyWithoutVoice",
                            "responseRequestId",
                        )
                    }
            if previous and previous.get("ogg", {}).get("sha256") == ogg_info["sha256"]:
                if mastering is None:
                    mastering = previous.get("mastering")
            if ogg_info["channels"] != 1 or ogg_info["durationSeconds"] <= 0:
                raise RuntimeError(f"Invalid mastered Cartesia audio: {ogg_path}")
            if mastering and float(mastering["finalPass"]["output_tp"]) > float(
                manifest["mastering"]["truePeakDb"]
            ) + 0.1:
                raise RuntimeError(f"True peak exceeded for {ogg_path}")
            samples.append(
                {
                    "outputKey": output_key,
                    "speakerId": voice.blind_id,
                    "speakerName": voice.blind_name,
                    "voiceId": voice.voice_id,
                    "voiceDisplayName": voice.name,
                    "gender": voice.gender,
                    "stockVoice": True,
                    "voiceMetadata": voice.metadata,
                    "phraseId": phrase["id"],
                    "displayText": phrase["displayText"],
                    "spokenText": phrase["spokenText"],
                    **generation,
                    "providerOriginal": raw_info,
                    "ogg": ogg_info,
                    "tempo": 1.0,
                    "mastering": mastering,
                    "meetsDurationTarget": ogg_info["durationSeconds"] <= float(
                        manifest["mastering"]["maximumDurationSeconds"]
                    ),
                }
            )

    report = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "provider": "Cartesia",
        "api": manifest["api"],
        "model": manifest["model"],
        "language": manifest["language"],
        "locale": manifest["locale"],
        "generationConfig": manifest["generationConfig"],
        "outputFormat": manifest["outputFormat"],
        "mastering": manifest["mastering"],
        "accountTier": None,
        "termsVerifiedUtc": None,
        "selectedVoices": [choice.__dict__ for choice in selected],
        "samples": samples,
    }
    prior_report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    listening_page = scratch / "listening" / "index.html"
    write_listening_page(
        samples,
        listening_page,
        review_manifest(manifest, selected),
        model_label=f"Cartesia/{manifest['model']['id']} stock voice comparison",
    )
    print(f"Run report: {prior_report_path}")
    print(f"Listening page: {listening_page}")
    print(
        "Samples over one second: "
        f"{sum(not item['meetsDurationTarget'] for item in samples)}/{len(samples)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
