"""Extract curated temporary audio assets from Don't Starve Together FSB banks."""

from __future__ import annotations

import ctypes
from pathlib import Path
import subprocess
import sys
import tempfile
import wave


DST_ROOT = Path(r"D:\SteamLibrary\steamapps\common\Don't Starve Together")
DST_DLL = DST_ROOT / "bin64" / "fmodex64.dll"
DST_SOUND_DIR = DST_ROOT / "data" / "sound"
OUT_ROOT = Path(r"e:\TuTien\assets\audio")

FMOD_OUTPUTTYPE_NOSOUND = 2
FMOD_CREATESAMPLE = 0x00000002
FMOD_SOFTWARE = 0x00000010
FMOD_TIMEUNIT_PCMBYTES = 4

MANIFEST: list[tuple[str, str, str, str]] = [
    # Music (.ogg)
    ("music/menu_theme.ogg", "music_frontend.fsb", "DST_Theme_Loop", "ogg"),
    ("music/season_autumn.ogg", "music.fsb", "Working_Remix_V1_172bpm_DST", "ogg"),
    ("music/season_winter.ogg", "music.fsb", "DS_Winter_Working", "ogg"),
    ("music/season_spring.ogg", "DLC_music.fsb", "DS_Spring_Working_120bpm", "ogg"),
    ("music/season_summer.ogg", "DLC_music.fsb", "DS_Summer_Working", "ogg"),
    ("music/secret_realm.ogg", "music.fsb", "DS_Ruins_Working_130bpm", "ogg"),
    ("music/combat.ogg", "music.fsb", "DS_Winter_Fight_145bpm", "ogg"),
    ("music/boss.ogg", "music.fsb", "DST_BossFightNo3_V1", "ogg"),
    ("music/stinger_dawn.ogg", "music.fsb", "Dawn_150bpm_3.4time", "ogg"),
    ("music/stinger_dusk.ogg", "music.fsb", "Dusk_150bpm_3.4time", "ogg"),
    # Ambient (.ogg)
    ("ambient/meadow_day.ogg", "forest_stream.fsb", "AMB_meadow_day_LP", "ogg"),
    ("ambient/meadow_night.ogg", "forest_stream.fsb", "AMB_meadow_night_LP", "ogg"),
    ("ambient/marsh_day.ogg", "forest_stream.fsb", "AMB_marsh_day_LP", "ogg"),
    ("ambient/marsh_night.ogg", "forest_stream.fsb", "AMB_marsh_night_LP", "ogg"),
    ("ambient/rocky_day.ogg", "forest_stream.fsb", "AMB_rocky_LP", "ogg"),
    ("ambient/rocky_night.ogg", "forest_stream.fsb", "AMB_rocky_night_LP", "ogg"),
    ("ambient/rain.ogg", "forest_stream.fsb", "AMB_rain_LP", "ogg"),
    ("ambient/wind.ogg", "forest_stream.fsb", "amb_winterwind_LP", "ogg"),
    ("ambient/campfire.ogg", "common.fsb", "campfire_layer1_LP", "ogg"),
    ("ambient/sanity_loop.ogg", "sanity.fsb", "sanity_loop1", "ogg"),
    # SFX: Footsteps (.wav)
    ("sfx/step_grass_1.wav", "sfx.fsb", "footstep_grass_1", "wav"),
    ("sfx/step_grass_2.wav", "sfx.fsb", "footstep_grass_2", "wav"),
    ("sfx/step_grass_3.wav", "sfx.fsb", "footstep_grass_3", "wav"),
    ("sfx/step_dirt_1.wav", "sfx.fsb", "footstep_dirt_1", "wav"),
    ("sfx/step_dirt_2.wav", "sfx.fsb", "footstep_dirt_2", "wav"),
    ("sfx/step_dirt_3.wav", "sfx.fsb", "footstep_dirt_3", "wav"),
    ("sfx/step_snow_1.wav", "sfx.fsb", "footstep_snow_1", "wav"),
    ("sfx/step_snow_2.wav", "sfx.fsb", "footstep_snow_2", "wav"),
    ("sfx/step_snow_3.wav", "sfx.fsb", "footstep_snow_3", "wav"),
    ("sfx/step_mud_1.wav", "sfx.fsb", "footstep_mud_1", "wav"),
    ("sfx/step_mud_2.wav", "sfx.fsb", "footstep_mud_2", "wav"),
    ("sfx/step_mud_3.wav", "sfx.fsb", "footstep_mud_3", "wav"),
    ("sfx/step_woods_1.wav", "sfx.fsb", "footstep_woods_1", "wav"),
    ("sfx/step_woods_2.wav", "sfx.fsb", "footstep_woods_2", "wav"),
    ("sfx/step_woods_3.wav", "sfx.fsb", "footstep_woods_3", "wav"),
    # SFX: Gathering / Work (.wav)
    ("sfx/chop_1.wav", "wilson.fsb", "gather_wood_1", "wav"),
    ("sfx/chop_2.wav", "wilson.fsb", "gather_wood_2", "wav"),
    ("sfx/chop_3.wav", "wilson.fsb", "gather_wood_3", "wav"),
    ("sfx/tree_fall.wav", "forest.fsb", "tree_fall_1", "wav"),
    ("sfx/mine_1.wav", "wilson.fsb", "pickaxe_hitrock_v2", "wav"),
    ("sfx/stone_break.wav", "wilson.fsb", "Stone_break", "wav"),
    ("sfx/dig_1.wav", "wilson.fsb", "Dig_1", "wav"),
    ("sfx/dig_2.wav", "wilson.fsb", "Dig_2", "wav"),
    ("sfx/dig_3.wav", "wilson.fsb", "Dig_3", "wav"),
    ("sfx/harvest_1.wav", "wilson.fsb", "Harvest_berries_1", "wav"),
    ("sfx/harvest_2.wav", "wilson.fsb", "Harvest_berries_2", "wav"),
    ("sfx/harvest_sticks.wav", "wilson.fsb", "Harvest_Sticks_1", "wav"),
    ("sfx/plant.wav", "wilson.fsb", "Plant_seeds", "wav"),
    # SFX: Combat (.wav)
    ("sfx/swing_1.wav", "wilson.fsb", "MakeWhoosh1_1", "wav"),
    ("sfx/swing_2.wav", "wilson.fsb", "MakeWhoosh1_2", "wav"),
    ("sfx/hit_1.wav", "sfx.fsb", "punch_self_bernie_dst-001", "wav"),
    ("sfx/hit_2.wav", "sfx.fsb", "punch_self_bernie_dst-002", "wav"),
    ("sfx/player_hurt_1.wav", "wilson.fsb", "WilsonVoice_hurt_1", "wav"),
    ("sfx/player_hurt_2.wav", "wilson.fsb", "WilsonVoice_hurt_2", "wav"),
    ("sfx/player_death.wav", "wilson.fsb", "DST_death_body_fall_v2", "wav"),
    ("sfx/death_trumpet.wav", "wilson.fsb", "death_voice_trumpet", "wav"),
    # SFX: Inventory / Craft / Build (.wav)
    ("sfx/pickup.wav", "wilson.fsb", "Pickup_item", "wav"),
    ("sfx/drop.wav", "common.fsb", "Drop_generic", "wav"),
    ("sfx/equip.wav", "wilson.fsb", "equip_goldItem", "wav"),
    ("sfx/eat_1.wav", "wilson.fsb", "eat_1", "wav"),
    ("sfx/eat_2.wav", "wilson.fsb", "eat_2", "wav"),
    ("sfx/eat_3.wav", "wilson.fsb", "eat_3", "wav"),
    ("sfx/craft.wav", "common.fsb", "chest_craft", "wav"),
    ("sfx/place.wav", "common.fsb", "genericmachineplace", "wav"),
    ("sfx/cook_sizzle.wav", "wilson.fsb", "Cook_sizzle", "wav"),
    ("sfx/make_soup.wav", "wilson.fsb", "make_soup", "wav"),
    ("sfx/fuel_fire.wav", "common.fsb", "Fire_addFuelFlare", "wav"),
    ("sfx/fire_out.wav", "common.fsb", "fire_out", "wav"),
    ("sfx/tool_break.wav", "wilson.fsb", "Tool_Break", "wav"),
    ("sfx/destroy_wood.wav", "common.fsb", "Destroy_wood", "wav"),
    # SFX: Magic / World (.wav)
    ("sfx/spell_cast.wav", "common.fsb", "book_spellcast", "wav"),
    ("sfx/magic_sparkle.wav", "common.fsb", "magic_sparkle", "wav"),
    ("sfx/portal_open.wav", "common.fsb", "SpawnPortal_open", "wav"),
    ("sfx/ghost_spawn.wav", "common.fsb", "ghost_spawn", "wav"),
    ("sfx/deathpoof.wav", "common.fsb", "deathpoof", "wav"),
    ("sfx/thunder_close.wav", "forest_stream.fsb", "thunder_close_1", "wav"),
    ("sfx/thunder_far.wav", "forest_stream.fsb", "thunder_far_1", "wav"),
    ("sfx/darkness_warn.wav", "sanity.fsb", "shadowhand_creep_1", "wav"),
    ("sfx/whisper_1.wav", "sanity.fsb", "sanity_random_1", "wav"),
    ("sfx/whisper_2.wav", "sanity.fsb", "sanity_random_2", "wav"),
    ("sfx/whisper_3.wav", "sanity.fsb", "sanity_random_3", "wav"),
    ("sfx/hungry.wav", "wilson.fsb", "Hungry_1", "wav"),
    # SFX: UI (.wav)
    ("sfx/ui_click.wav", "sfx.fsb", "click_object", "wav"),
    ("sfx/ui_error.wav", "sfx.fsb", "click_negative", "wav"),
    ("sfx/ui_craft_open.wav", "sfx.fsb", "HUD_craft_open", "wav"),
    ("sfx/ui_craft_close.wav", "sfx.fsb", "HUD_craft_close", "wav"),
    ("sfx/ui_book_open.wav", "wilson.fsb", "book_open_1", "wav"),
    ("sfx/ui_chest_open.wav", "wilson.fsb", "Chest_open", "wav"),
    ("sfx/ui_chest_close.wav", "wilson.fsb", "Chest_close", "wav"),
]


def read_subsound_pcm(dll: ctypes.CDLL, sub_ptr: ctypes.c_void_p) -> tuple[int, int, int, bytes]:
    snd_type = ctypes.c_int()
    snd_fmt = ctypes.c_int()
    channels = ctypes.c_int()
    bits = ctypes.c_int()
    res = dll.FMOD_Sound_GetFormat(
        sub_ptr, ctypes.byref(snd_type), ctypes.byref(snd_fmt), ctypes.byref(channels), ctypes.byref(bits)
    )
    if res != 0:
        raise RuntimeError(f"FMOD_Sound_GetFormat failed: {res}")
    if bits.value != 16:
        raise RuntimeError(f"Expected 16-bit PCM, got {bits.value}-bit (fmt={snd_fmt.value})")

    freq = ctypes.c_float()
    vol = ctypes.c_float()
    pan = ctypes.c_float()
    pri = ctypes.c_int()
    res = dll.FMOD_Sound_GetDefaults(
        sub_ptr, ctypes.byref(freq), ctypes.byref(vol), ctypes.byref(pan), ctypes.byref(pri)
    )
    if res != 0:
        raise RuntimeError(f"FMOD_Sound_GetDefaults failed: {res}")

    pcm_bytes = ctypes.c_uint()
    res = dll.FMOD_Sound_GetLength(sub_ptr, ctypes.byref(pcm_bytes), FMOD_TIMEUNIT_PCMBYTES)
    if res != 0:
        raise RuntimeError(f"FMOD_Sound_GetLength failed: {res}")

    total_len = pcm_bytes.value
    p1 = ctypes.c_void_p()
    p2 = ctypes.c_void_p()
    l1 = ctypes.c_uint()
    l2 = ctypes.c_uint()
    res = dll.FMOD_Sound_Lock(
        sub_ptr,
        0,
        total_len,
        ctypes.byref(p1),
        ctypes.byref(p2),
        ctypes.byref(l1),
        ctypes.byref(l2),
    )
    if res != 0:
        raise RuntimeError(f"FMOD_Sound_Lock failed: {res}")
    try:
        pcm = ctypes.string_at(p1, l1.value) if l1.value > 0 else b""
        if l2.value > 0 and p2.value:
            pcm += ctypes.string_at(p2, l2.value)
    finally:
        dll.FMOD_Sound_Unlock(sub_ptr, p1, p2, l1, l2)

    return int(round(freq.value)), channels.value, bits.value, pcm


def write_wav(path: Path, sample_rate: int, channels: int, bits: int, pcm: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(bits // 8)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm)


def encode_ogg(wav_path: Path, ogg_path: Path) -> None:
    ogg_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg",
        "-y",
        "-loglevel",
        "error",
        "-i",
        str(wav_path),
        "-c:a",
        "libvorbis",
        "-q:a",
        "4",
        str(ogg_path),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"ffmpeg failed for {ogg_path}: {proc.stderr}")


def main() -> int:
    if not DST_DLL.is_file():
        raise FileNotFoundError(f"Missing FMOD DLL: {DST_DLL}")

    dll = ctypes.CDLL(str(DST_DLL))
    sys_ptr = ctypes.c_void_p()
    if dll.FMOD_System_Create(ctypes.byref(sys_ptr)) != 0:
        raise RuntimeError("FMOD_System_Create failed")
    if dll.FMOD_System_SetOutput(sys_ptr, FMOD_OUTPUTTYPE_NOSOUND) != 0:
        raise RuntimeError("FMOD_System_SetOutput failed")
    if dll.FMOD_System_Init(sys_ptr, 32, 0, None) != 0:
        raise RuntimeError("FMOD_System_Init failed")

    by_bank: dict[str, list[tuple[str, str, str]]] = {}
    for rel_out, bank, sub_name, fmt in MANIFEST:
        by_bank.setdefault(bank, []).append((rel_out, sub_name, fmt))

    force = "--force" in sys.argv[1:]
    extracted = 0
    skipped = 0
    try:
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_root = Path(tmp_dir)
            for bank, items in by_bank.items():
                pending = [
                    (rel_out, sub_name, fmt)
                    for rel_out, sub_name, fmt in items
                    if force or not (OUT_ROOT / rel_out).is_file() or (OUT_ROOT / rel_out).stat().st_size == 0
                ]
                skipped += len(items) - len(pending)
                if not pending:
                    continue

                bank_path = DST_SOUND_DIR / bank
                if not bank_path.is_file():
                    raise FileNotFoundError(f"Missing FSB bank: {bank_path}")

                snd_ptr = ctypes.c_void_p()
                res = dll.FMOD_System_CreateSound(
                    sys_ptr,
                    str(bank_path).encode("utf-8"),
                    FMOD_CREATESAMPLE | FMOD_SOFTWARE,
                    None,
                    ctypes.byref(snd_ptr),
                )
                if res != 0:
                    raise RuntimeError(f"CreateSound failed for {bank}: {res}")

                try:
                    num_sub = ctypes.c_int()
                    dll.FMOD_Sound_GetNumSubSounds(snd_ptr, ctypes.byref(num_sub))
                    sub_index_by_name: dict[str, int] = {}
                    name_buf = ctypes.create_string_buffer(256)
                    for idx in range(num_sub.value):
                        sub = ctypes.c_void_p()
                        if dll.FMOD_Sound_GetSubSound(snd_ptr, idx, ctypes.byref(sub)) != 0:
                            continue
                        dll.FMOD_Sound_GetName(sub, name_buf, 256)
                        sname = name_buf.value.decode("utf-8", errors="replace").lower()
                        sub_index_by_name.setdefault(sname, idx)

                    for rel_out, sub_name, fmt in pending:
                        idx = sub_index_by_name.get(sub_name.lower())
                        if idx is None:
                            raise KeyError(f"Subsound '{sub_name}' not found in {bank}")
                        sub = ctypes.c_void_p()
                        if dll.FMOD_Sound_GetSubSound(snd_ptr, idx, ctypes.byref(sub)) != 0:
                            raise RuntimeError(f"GetSubSound failed for {sub_name} in {bank}")
                        rate, ch, bits, pcm = read_subsound_pcm(dll, sub)
                        out_path = OUT_ROOT / rel_out
                        if fmt == "wav":
                            write_wav(out_path, rate, ch, bits, pcm)
                        elif fmt == "ogg":
                            tmp_wav = tmp_root / f"{out_path.stem}.wav"
                            write_wav(tmp_wav, rate, ch, bits, pcm)
                            encode_ogg(tmp_wav, out_path)
                        else:
                            raise ValueError(f"Unsupported format: {fmt}")
                        if not out_path.is_file() or out_path.stat().st_size == 0:
                            raise RuntimeError(f"Empty output file: {out_path}")
                        extracted += 1
                        print(f"[ok] {rel_out} <- {bank}:{sub_name} ({out_path.stat().st_size} bytes)", flush=True)
                finally:
                    dll.FMOD_Sound_Release(snd_ptr)
    finally:
        dll.FMOD_System_Release(sys_ptr)

    print(f"Done: extracted {extracted}, skipped {skipped}, total {len(MANIFEST)} audio files in {OUT_ROOT}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
