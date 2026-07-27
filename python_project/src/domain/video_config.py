from dataclasses import dataclass
from typing import List, Tuple, Dict, Any

@dataclass(frozen=True)
class VideoSettings:
    width: int
    height: int
    fps: int
    duration: float
    output_name: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "width": self.width,
            "height": self.height,
            "fps": self.fps,
            "duration": self.duration,
            "output_name": self.output_name
        }

@dataclass(frozen=True)
class AudioSettings:
    note_mode: str
    note_clips_dir: str
    audio_delay_ms: int
    loop_notes: bool
    notes: List[Dict[str, Any]] # e.g., [{"index": i, "file": "note_0001.wav"}]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "note_mode": self.note_mode,
            "note_clips_dir": self.note_clips_dir,
            "audio_delay_ms": self.audio_delay_ms,
            "loop_notes": self.loop_notes,
            "notes": self.notes
        }

@dataclass(frozen=True)
class GameplaySettings:
    ball: Dict[str, Any]
    arena: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ball": self.ball,
            "arena": self.arena
        }

@dataclass(frozen=True)
class VisualSettings:
    background_color: str
    ball_color: str
    use_glow: bool
    use_rainbow_trail: bool
    trail_mode: str
    trail_persistence: float
    impact_effect: bool
    use_ball_icon: bool = False
    ball_icon_path: str = ""
    icon_silhouette_mode: bool = False
    icon_reveal_phase: str = "final_storm"
    icon_rotation_mode: str = "none"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "background_color": self.background_color,
            "ball_color": self.ball_color,
            "use_glow": self.use_glow,
            "use_rainbow_trail": self.use_rainbow_trail,
            "trail_mode": self.trail_mode,
            "trail_persistence": self.trail_persistence,
            "impact_effect": self.impact_effect,
            "use_ball_icon": self.use_ball_icon,
            "ball_icon_path": self.ball_icon_path,
            "icon_silhouette_mode": self.icon_silhouette_mode,
            "icon_reveal_phase": self.icon_reveal_phase,
            "icon_rotation_mode": self.icon_rotation_mode
        }

@dataclass(frozen=True)
class TextSettings:
    show_text: bool
    top_text: str
    bottom_text: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "show_text": self.show_text,
            "top_text": self.top_text,
            "bottom_text": self.bottom_text
        }

@dataclass(frozen=True)
class PhaseSettings:
    name: str
    start_time: float
    end_time: float
    speed_multiplier: float
    growth_multiplier: float
    trail_multiplier: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "speed_multiplier": self.speed_multiplier,
            "growth_multiplier": self.growth_multiplier,
            "trail_multiplier": self.trail_multiplier
        }

@dataclass(frozen=True)
class VideoConfig:
    project_version: str
    game_mode: str
    video: VideoSettings
    audio: AudioSettings
    gameplay: GameplaySettings
    visual: VisualSettings
    text: TextSettings
    phases: List[PhaseSettings]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "project_version": self.project_version,
            "game_mode": self.game_mode,
            "video": self.video.to_dict(),
            "audio": self.audio.to_dict(),
            "gameplay": self.gameplay.to_dict(),
            "visual": self.visual.to_dict(),
            "text": self.text.to_dict(),
            "phases": [p.to_dict() for p in self.phases]
        }
