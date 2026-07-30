import sys
import os
import json
import argparse

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
    # Initialize domain & infrastructure components
    # Resolve the path to the schema.
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser = argparse.ArgumentParser(description="Generate a Music Ball job from a JSON profile")
    parser.add_argument("--profile", default="job_profile.json")
    args = parser.parse_args()
    profile_path = args.profile
    if not os.path.isabs(profile_path):
        profile_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), profile_path)
    with open(profile_path, "r", encoding="utf-8") as profile_file:
        profile = json.load(profile_file)

    input_path = profile["input_path"]
    job_id = profile["job_id"]
    slice_mode_str = profile["slice_mode"]
    interval = profile.get("slice_interval_seconds")
    markers = profile.get("markers", [])
    max_notes = profile.get("max_note_count", 400)
    fade_in_ms = profile.get("fade_in_ms", 3)
    fade_out_ms = profile.get("fade_out_ms", 3)
    target_duration_seconds = profile.get("target_duration_seconds")
    custom_text = profile.get("text")
    custom_job_assets = profile.get("job_assets")

    schema_path = os.path.join(project_root, "shared", "video_config.schema.json")
    
    # Resolve gameplay presets mapping
    presets_list = profile.get("gameplay_presets", ["circle_bounce", "polygon_bounce"])
    gameplay_presets_templates = {}
    for p in presets_list:
        if p == "polygon_bounce":
            gameplay_presets_templates[p] = os.path.join(project_root, "shared", "gameplay_template_polygon.json")
        elif p == "circle_bounce":
            gameplay_presets_templates[p] = os.path.join(project_root, "shared", "gameplay_template.json")
        else:
            gameplay_presets_templates[p] = os.path.join(project_root, "shared", f"gameplay_template_{p}.json")
        
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
        ,target_duration_seconds=target_duration_seconds
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
            custom_text=custom_text,
            custom_job_assets=custom_job_assets,
            gameplay_presets_templates=gameplay_presets_templates,
        )

        print(f"\nJob '{job.job_id}' generated successfully!")
        print(f"Output directory: {job.job_dir}")
        print(f"Config path: {job.video_config_path}")
        print(f"Gameplay config paths: {job.gameplay_config_paths}")
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
