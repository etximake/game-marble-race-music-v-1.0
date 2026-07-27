from typing import Any, Dict, List, Optional

from src.domain.audio import AudioMetadata
from src.domain.note import NoteClip
from src.domain.video_config import (
    AudioSettings,
    JobAssets,
    TextSettings,
    VideoConfig,
    VideoSettings,
)


class GenerateVideoConfigUseCase:
    def execute(
        self,
        metadata: AudioMetadata,
        note_clips: List[NoteClip],
        output_name: str,
        custom_text: Optional[Dict[str, Any]] = None,
        custom_job_assets: Optional[Dict[str, Any]] = None,
    ) -> VideoConfig:
        text_data = {
            "show_text": True,
            "top_text": "With every bounce, the ball evolves",
            "bottom_text": "Did you recognize the music?",
        }
        if custom_text:
            text_data.update(custom_text)

        assets = custom_job_assets or {}
        notes = [{"index": clip.index, "file": clip.file_name} for clip in note_clips]

        return VideoConfig(
            video=VideoSettings(
                duration=metadata.duration_seconds,
                output_name=output_name,
            ),
            audio=AudioSettings(
                note_mode="next_note_on_trigger",
                note_clips_dir="note_clips/",
                audio_delay_ms=0,
                loop_notes=True,
                notes=notes,
            ),
            text=TextSettings(
                show_text=bool(text_data["show_text"]),
                top_text=str(text_data["top_text"]),
                bottom_text=str(text_data["bottom_text"]),
            ),
            job_assets=JobAssets(
                ball_icon_path=str(assets.get("ball_icon_path", "")),
                ball_color=str(assets.get("ball_color", "")),
            ),
        )
