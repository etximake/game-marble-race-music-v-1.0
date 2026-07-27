from typing import List, Dict, Any, Optional
from src.domain.audio import AudioMetadata
from src.domain.note import NoteClip
from src.domain.video_config import (
    VideoConfig,
    VideoSettings,
    AudioSettings,
    GameplaySettings,
    VisualSettings,
    TextSettings,
    PhaseSettings,
)

class GenerateVideoConfigUseCase:
    def execute(
        self,
        metadata: AudioMetadata,
        note_clips: List[NoteClip],
        output_name: str,
        custom_gameplay: Optional[Dict[str, Any]] = None,
        custom_visual: Optional[Dict[str, Any]] = None,
        custom_text: Optional[Dict[str, Any]] = None,
    ) -> VideoConfig:
        duration = metadata.duration_seconds

        # Video Settings
        video_settings = VideoSettings(
            width=1080,
            height=1920,
            fps=60,
            duration=duration,
            output_name=output_name,
        )

        # Audio Settings
        notes_list = [
            {"index": clip.index, "file": clip.file_name} for clip in note_clips
        ]
        audio_settings = AudioSettings(
            note_mode="next_note_on_trigger",
            note_clips_dir="note_clips/",
            audio_delay_ms=0,
            loop_notes=True,
            notes=notes_list,
        )

        # Default Circle Bounce Gameplay Settings
        ball_settings = {
            "start_position": [540.0, 515.0],
            "start_velocity": [0.0, 600.0],
            "start_radius": 24.0,
            "max_radius": 320.0,
            "max_radius_ratio": 0.8,
            "growth_per_hit": 1.025,
            "speed_growth_per_hit": 1.012,
            "max_speed": 1600.0,
        }
        if custom_gameplay and "ball" in custom_gameplay:
            ball_settings.update(custom_gameplay["ball"])

        arena_settings = {
            "type": "circle",
            "center": [540, 960],
            "radius": 470.0,
            "line_width": 10.0,
        }
        if custom_gameplay and "arena" in custom_gameplay:
            arena_settings.update(custom_gameplay["arena"])

        gameplay_settings = GameplaySettings(
            ball=ball_settings,
            arena=arena_settings,
        )

        # Default Visual Settings
        visual_data = {
            "background_color": "#050505",
            "ball_color": "#00ffcc",
            "use_glow": True,
            "use_rainbow_trail": True,
            "trail_mode": "web",
            "trail_persistence": 1.0,
            "impact_effect": True,
            "use_ball_icon": False,
            "ball_icon_path": "",
            "icon_silhouette_mode": False,
            "icon_reveal_phase": "final_storm",
            "icon_rotation_mode": "none",
        }
        if custom_visual:
            visual_data.update(custom_visual)

        visual_settings = VisualSettings(
            background_color=visual_data["background_color"],
            ball_color=visual_data["ball_color"],
            use_glow=bool(visual_data["use_glow"]),
            use_rainbow_trail=bool(visual_data["use_rainbow_trail"]),
            trail_mode=visual_data["trail_mode"],
            trail_persistence=float(visual_data["trail_persistence"]),
            impact_effect=bool(visual_data["impact_effect"]),
            use_ball_icon=bool(visual_data.get("use_ball_icon", False)),
            ball_icon_path=str(visual_data.get("ball_icon_path", "")),
            icon_silhouette_mode=bool(visual_data.get("icon_silhouette_mode", False)),
            icon_reveal_phase=str(visual_data.get("icon_reveal_phase", "final_storm")),
            icon_rotation_mode=str(visual_data.get("icon_rotation_mode", "none")),
        )

        # Default Text Settings
        text_data = {
            "show_text": True,
            "top_text": "With every bounce, the ball evolves",
            "bottom_text": "Did you recognize the music?",
        }
        if custom_text:
            text_data.update(custom_text)

        text_settings = TextSettings(
            show_text=bool(text_data["show_text"]),
            top_text=text_data["top_text"],
            bottom_text=text_data["bottom_text"],
        )

        # Default 3 Phases: Phase 1 (5s), Phase 2 (5s), Phase 3 (remainder of duration)
        # Note: If duration is less than or equal to 10s, we adjust boundaries to prevent errors.
        var_phase1_end = 5.0
        var_phase2_end = 10.0
        
        if duration <= 10.0:
            var_phase1_end = duration * 0.3
            var_phase2_end = duration * 0.6
            
        phases = [
            PhaseSettings(
                name="intro",
                start_time=0.0,
                end_time=var_phase1_end,
                speed_multiplier=1.0,
                growth_multiplier=1.0,
                trail_multiplier=1.0,
            ),
            PhaseSettings(
                name="build_up",
                start_time=var_phase1_end,
                end_time=var_phase2_end,
                speed_multiplier=1.2,
                growth_multiplier=1.15,
                trail_multiplier=1.3,
            ),
            PhaseSettings(
                name="final_storm",
                start_time=var_phase2_end,
                end_time=duration,
                speed_multiplier=1.6,
                growth_multiplier=1.35,
                trail_multiplier=2.0,
            ),
        ]

        return VideoConfig(
            project_version="1.0",
            game_mode="circle_bounce",
            video=video_settings,
            audio=audio_settings,
            gameplay=gameplay_settings,
            visual=visual_settings,
            text=text_settings,
            phases=phases,
        )
