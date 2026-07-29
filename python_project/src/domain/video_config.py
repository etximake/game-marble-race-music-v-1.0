from dataclasses import dataclass
from typing import Any, Dict, List


@dataclass(frozen=True)
class VideoSettings:
    duration: float
    output_name: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "duration": self.duration,
            "output_name": self.output_name,
        }


@dataclass(frozen=True)
class AudioSettings:
    note_mode: str
    note_clips_dir: str
    audio_delay_ms: int
    loop_notes: bool
    notes: List[Dict[str, Any]]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "note_mode": self.note_mode,
            "note_clips_dir": self.note_clips_dir,
            "audio_delay_ms": self.audio_delay_ms,
            "loop_notes": self.loop_notes,
            "notes": self.notes,
        }


@dataclass(frozen=True)
class TextSettings:
    show_text: bool
    top_text: str
    bottom_text: str
    song_name: str = ""

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "show_text": self.show_text,
            "top_text": self.top_text,
            "bottom_text": self.bottom_text,
        }
        if self.song_name:
            result["song_name"] = self.song_name
        return result


@dataclass(frozen=True)
class JobAssets:
    ball_icon_path: str = ""
    ball_color: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ball_icon_path": self.ball_icon_path,
            "ball_color": self.ball_color,
        }


@dataclass(frozen=True)
class VideoConfig:
    """Job Music JSON. Gameplay is owned by Godot's template."""

    video: VideoSettings
    audio: AudioSettings
    text: TextSettings
    job_assets: JobAssets = JobAssets()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "video": self.video.to_dict(),
            "audio": self.audio.to_dict(),
            "text": self.text.to_dict(),
            "job_assets": self.job_assets.to_dict(),
        }
