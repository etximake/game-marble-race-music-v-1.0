import os
import json
import pytest
from src.domain.audio import AudioMetadata
from src.domain.note import NoteClip
from src.application.generate_video_config import GenerateVideoConfigUseCase
from src.infrastructure.validation.json_schema_validator import JsonSchemaVideoConfigValidator

@pytest.fixture
def schema_path():
    # Resolve the shared schema path relative to this test file
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(project_root, "shared", "video_config.schema.json")

def test_generate_and_validate_video_config(schema_path):
    generator = GenerateVideoConfigUseCase()
    validator = JsonSchemaVideoConfigValidator(schema_path)

    metadata = AudioMetadata(
        source_path="dummy.wav",
        duration_seconds=10.0,
        sample_rate=44100,
        channel_count=1,
        format="wav"
    )

    note_clips = [
        NoteClip(index=0, file_name="note_0001.wav", start_time=0.0, end_time=2.0, duration=2.0),
        NoteClip(index=1, file_name="note_0002.wav", start_time=2.0, end_time=4.0, duration=2.0),
        NoteClip(index=2, file_name="note_0003.wav", start_time=4.0, end_time=6.0, duration=2.0),
        NoteClip(index=3, file_name="note_0004.wav", start_time=6.0, end_time=8.0, duration=2.0),
        NoteClip(index=4, file_name="note_0005.wav", start_time=8.0, end_time=10.0, duration=2.0),
    ]

    config = generator.execute(
        metadata=metadata,
        note_clips=note_clips,
        output_name="test_video_output"
    )

    # Verify attributes
    assert config.project_version == "1.0"
    assert config.game_mode == "circle_bounce"
    assert config.video.duration == 10.0
    assert len(config.audio.notes) == 5
    assert len(config.phases) == 3

    # Schema & Semantic validation
    validator.validate(config)
