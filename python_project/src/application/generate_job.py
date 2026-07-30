import os
import hashlib
import json
from typing import Dict, Any, Optional
from src.domain.slicing import SlicePlan
from src.domain.job import Job
from src.domain.errors import InputAudioNotFoundError, JobWriteError
from src.application.generate_video_config import GenerateVideoConfigUseCase
from src.infrastructure.audio.audio_service import PydubAudioService
from src.infrastructure.audio.audio_slicer import PydubAudioSlicer
from src.infrastructure.filesystem.job_repository import FileSystemJobRepository
from src.infrastructure.validation.json_schema_validator import JsonSchemaVideoConfigValidator

class GenerateJobUseCase:
    BALL_PALETTE = (
        "#00D9FF", "#7C4DFF", "#FF4081", "#00E676",
        "#FFB300", "#FF7043", "#26C6DA", "#EC407A",
    )

    def __init__(
        self,
        audio_service: PydubAudioService,
        audio_slicer: PydubAudioSlicer,
        job_repository: FileSystemJobRepository,
        video_config_generator: GenerateVideoConfigUseCase,
        validator: JsonSchemaVideoConfigValidator,
    ):
        self.audio_service = audio_service
        self.audio_slicer = audio_slicer
        self.job_repository = job_repository
        self.video_config_generator = video_config_generator
        self.validator = validator

    def execute(
        self,
        source_audio_path: str,
        job_id: str,
        slice_plan: SlicePlan,
        custom_text: Optional[Dict[str, Any]] = None,
        custom_job_assets: Optional[Dict[str, Any]] = None,
        gameplay_presets_templates: Optional[Dict[str, str]] = None,
    ) -> Job:
        if not os.path.exists(source_audio_path):
            raise InputAudioNotFoundError(f"Input audio file not found at: {source_audio_path}")
        
        # Validate slice plan domain rules
        slice_plan.validate()

        # 1. Create Job Structure
        presets = list(gameplay_presets_templates.keys()) if gameplay_presets_templates else ["circle_bounce", "polygon_bounce"]
        job = self.job_repository.create_job(job_id, presets)

        try:
            # 2. Get Audio Metadata
            metadata = self.audio_service.read_metadata(source_audio_path)

            # 3. Save Source Audio
            # We want to normalize it and save as wav in source_audio.wav
            self.audio_service.convert_to_wav(
                source_audio_path,
                job.source_audio_path,
                slice_plan.target_duration_seconds,
            )
            
            # Update metadata to reflect normalized source audio
            norm_metadata = self.audio_service.read_metadata(job.source_audio_path)

            # 4. Slice Audio to Note Clips
            note_clips = self.audio_slicer.slice(
                audio_path=job.source_audio_path,
                slice_plan=slice_plan,
                output_dir=job.note_clips_dir
            )

            # Choose a stable palette color per job, unless explicitly overridden.
            job_assets = dict(custom_job_assets or {})
            if not job_assets.get("ball_color"):
                digest = hashlib.sha256(job_id.encode("utf-8")).digest()
                palette_index = int.from_bytes(digest[:2], "big") % len(self.BALL_PALETTE)
                job_assets["ball_color"] = self.BALL_PALETTE[palette_index]

            # 5. Generate Video Config
            video_config = self.video_config_generator.execute(
                metadata=norm_metadata,
                note_clips=note_clips,
                output_name=f"music_ball_{job_id}",
                custom_text=custom_text,
                custom_job_assets=job_assets,
            )

            # 6. Validate Video Config
            self.validator.validate(video_config)

            # 7. Save Video Config & Metadata
            self.job_repository.save_video_config(job, video_config)

            if gameplay_presets_templates:
                for preset, template_path in gameplay_presets_templates.items():
                    if not os.path.exists(template_path):
                        raise JobWriteError(f"Gameplay template for '{preset}' not found at: {template_path}")
                    with open(template_path, "r", encoding="utf-8") as template_file:
                        gameplay_config = json.load(template_file)
                    self.job_repository.save_gameplay_config(job, preset, gameplay_config)
            
            job_metadata = {
                "source_file": source_audio_path,
                "duration": norm_metadata.duration_seconds,
                "sample_rate": norm_metadata.sample_rate,
                "slice_mode": slice_plan.mode.value,
                "note_count": len(note_clips)
            }
            self.job_repository.save_metadata(job, job_metadata)
            
            return job

        except Exception as e:
            # If any failure occurs, cleanup the failed job folder in MVP if needed,
            # but we can let it remain for debugging or raise directly.
            if os.path.exists(job.job_dir):
                try:
                    import shutil
                    shutil.rmtree(job.job_dir)
                except Exception:
                    pass
            raise e
