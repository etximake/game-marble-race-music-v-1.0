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

        # 2. Job Music semantic validation
        duration = config.video.duration
        # Cho phép giới hạn tối đa 60.0 giây cho các video Shorts dài hơn (hoặc Puzzle được cộng thêm 6s)
        if not (1.0 <= duration <= 60.0):
            raise VideoConfigValidationError(
                f"video.duration ({duration}) must be between 1.0 and 60.0 seconds."
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
