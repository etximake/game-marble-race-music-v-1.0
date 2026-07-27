import os
import json
from typing import Dict, Any, List
import jsonschema
from src.domain.errors import VideoConfigValidationError
from src.domain.video_config import VideoConfig

class JsonSchemaVideoConfigValidator:
    def __init__(self, schema_path: str):
        self.schema_path = schema_path
        self._schema = None

    @property
    def schema(self) -> Dict[str, Any]:
        if self._schema is None:
            if not os.path.exists(self.schema_path):
                raise FileNotFoundError(f"Schema file not found at: {self.schema_path}")
            with open(self.schema_path, "r", encoding="utf-8") as f:
                self._schema = json.load(f)
        return self._schema

    def validate(self, config: VideoConfig) -> None:
        config_dict = config.to_dict()
        
        # 1. Schema Validation
        try:
            jsonschema.validate(instance=config_dict, schema=self.schema)
        except jsonschema.ValidationError as e:
            path = ".".join(str(p) for p in e.path)
            raise VideoConfigValidationError(
                f"Schema validation error at '{path}': {e.message}"
            )

        # 2. Common Semantic Validation
        duration = config.video.duration
        if not (1.0 <= duration <= 600.0):
            raise VideoConfigValidationError(
                f"video.duration ({duration}) must be between 1.0 and 600.0 seconds."
            )

        # Validate phases semantic rules
        phases = config.phases
        if not phases:
            raise VideoConfigValidationError("At least one phase must be defined.")
        
        # Check sorted by start_time, starting at 0
        sorted_phases = sorted(phases, key=lambda p: p.start_time)
        if sorted_phases[0].start_time != 0.0:
            raise VideoConfigValidationError("The first phase must start at 0.0 seconds.")
        
        for i, p in enumerate(sorted_phases):
            if p.end_time <= p.start_time:
                raise VideoConfigValidationError(
                    f"Phase '{p.name}' has invalid timing: end_time ({p.end_time}) must be greater than start_time ({p.start_time})."
                )
            if i > 0:
                prev_phase = sorted_phases[i-1]
                if abs(p.start_time - prev_phase.end_time) > 1e-5:
                    raise VideoConfigValidationError(
                        f"Phase '{p.name}' start_time ({p.start_time}) does not match previous phase '{prev_phase.name}' end_time ({prev_phase.end_time})."
                    )
        
        # Check last phase end_time matches duration
        last_phase = sorted_phases[-1]
        if abs(last_phase.end_time - duration) > 1e-5:
            raise VideoConfigValidationError(
                f"The last phase '{last_phase.name}' end_time ({last_phase.end_time}) must match video.duration ({duration})."
            )

        # Check audio notes structure
        notes = config.audio.notes
        if not notes:
            raise VideoConfigValidationError("audio.notes list cannot be empty.")
        
        # Validate indexes
        for idx, note in enumerate(notes):
            if note["index"] != idx:
                raise VideoConfigValidationError(
                    f"audio.notes[{idx}] has invalid index: expected {idx}, got {note['index']}."
                )

        # 3. Game Mode Specific Semantic Rules
        if config.game_mode == "circle_bounce":
            ball = config.gameplay.ball
            arena = config.gameplay.arena
            
            start_r = ball["start_radius"]
            max_r = ball["max_radius"]
            arena_r = arena["radius"]

            if max_r < start_r:
                raise VideoConfigValidationError(
                    f"gameplay.ball.max_radius ({max_r}) must be greater than or equal to start_radius ({start_r})."
                )
            if start_r >= arena_r:
                raise VideoConfigValidationError(
                    f"gameplay.ball.start_radius ({start_r}) must be less than gameplay.arena.radius ({arena_r})."
                )
            
            # Start position within arena check
            center = arena["center"]
            pos = ball["start_position"]
            dist_sq = (pos[0] - center[0])**2 + (pos[1] - center[1])**2
            dist = dist_sq ** 0.5
            if dist + start_r > arena_r:
                raise VideoConfigValidationError(
                    "gameplay.ball start position and radius puts it outside the arena bounds."
                )

            # Check velocity is non-zero
            vel = ball["start_velocity"]
            if vel[0] == 0.0 and vel[1] == 0.0:
                raise VideoConfigValidationError("gameplay.ball.start_velocity cannot be [0, 0].")
            
            # Arena type check
            if arena["type"] != "circle":
                raise VideoConfigValidationError("gameplay.arena.type must be 'circle' for game_mode 'circle_bounce'.")
