import sys
import os
import argparse
import json

# Setup sys.path to resolve src
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.domain.slicing import SlicePlan, SliceMode
from src.domain.errors import MusicBallError
from src.application.generate_video_config import GenerateVideoConfigUseCase
from src.application.generate_job import GenerateJobUseCase
from src.infrastructure.audio.audio_service import PydubAudioService
from src.infrastructure.audio.audio_slicer import PydubAudioSlicer
from src.infrastructure.filesystem.job_repository import FileSystemJobRepository
from src.infrastructure.validation.json_schema_validator import JsonSchemaVideoConfigValidator

import sys
import os
import json

# Setup sys.path to resolve src
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.domain.slicing import SlicePlan, SliceMode
from src.domain.errors import MusicBallError
from src.application.generate_video_config import GenerateVideoConfigUseCase
from src.application.generate_job import GenerateJobUseCase
from src.infrastructure.audio.audio_service import PydubAudioService
from src.infrastructure.audio.audio_slicer import PydubAudioSlicer
from src.infrastructure.filesystem.job_repository import FileSystemJobRepository
from src.infrastructure.validation.json_schema_validator import JsonSchemaVideoConfigValidator

def main():
    # Parameters configured directly inside the program
    input_path = "source/DIA DELÍCIA (Slowed) [AsFdNBMCwPM].mp3"
    job_id = "job_001"
    slice_mode_str = "fixed_interval"
    interval = 0.4
    markers = []
    max_notes = 400
    fade_in_ms = 3
    fade_out_ms = 3
    
    custom_gameplay = None
    custom_visual = None
    custom_text = None

    # Initialize domain & infrastructure components
    # Resolve the path to the schema.
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    schema_path = os.path.join(project_root, "shared", "video_config.schema.json")
    base_jobs_dir = os.path.join(project_root, "generated", "jobs")

    audio_service = PydubAudioService()
    audio_slicer = PydubAudioSlicer()
    job_repo = FileSystemJobRepository(base_jobs_dir)
    video_generator = GenerateVideoConfigUseCase()
    validator = JsonSchemaVideoConfigValidator(schema_path)

    use_case = GenerateJobUseCase(
        audio_service=audio_service,
        audio_slicer=audio_slicer,
        job_repository=job_repo,
        video_config_generator=video_generator,
        validator=validator
    )

    # Determine slice mode
    mode = SliceMode(slice_mode_str)
    slice_plan = SlicePlan(
        mode=mode,
        markers=markers,
        fixed_interval_seconds=interval,
        max_note_count=max_notes,
        fade_in_ms=fade_in_ms,
        fade_out_ms=fade_out_ms
    )

    try:
        print(f"Creating job '{job_id}'...")
        print(f"Input audio: {input_path}")
        print(f"Slice mode: {slice_mode_str}")
        if mode == SliceMode.FIXED_INTERVAL:
            print(f"Interval: {interval}s")
        else:
            print(f"Markers count: {len(markers)}")

        job = use_case.execute(
            source_audio_path=input_path,
            job_id=job_id,
            slice_plan=slice_plan,
            custom_gameplay=custom_gameplay,
            custom_visual=custom_visual,
            custom_text=custom_text
        )

        print(f"\nJob '{job.job_id}' generated successfully!")
        print(f"Output directory: {job.job_dir}")
        print(f"Config path: {job.video_config_path}")
        print(f"Clips directory: {job.note_clips_dir}")
        sys.exit(0)

    except MusicBallError as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}", file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
