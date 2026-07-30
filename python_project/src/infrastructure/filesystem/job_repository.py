import os
import shutil
import json
from typing import Dict, Any
from src.domain.job import Job
from src.domain.video_config import VideoConfig
from src.domain.errors import JobWriteError

class FileSystemJobRepository:
    def __init__(self, base_jobs_dir: str):
        self.base_jobs_dir = base_jobs_dir

    def create_job(self, job_id: str, presets: list = None) -> Job:
        if not job_id or job_id in {".", ".."} or os.path.basename(job_id) != job_id:
            raise JobWriteError(f"Invalid job id: {job_id}")
        job_dir = os.path.join(self.base_jobs_dir, job_id)
        note_clips_dir = os.path.join(job_dir, "note_clips")
        
        if presets is None:
            presets = ["circle_bounce", "polygon_bounce"]
        
        try:
            # Regeneration must not leave clips from an older, longer source job.
            if os.path.isdir(job_dir):
                shutil.rmtree(job_dir)
            os.makedirs(job_dir, exist_ok=True)
            os.makedirs(note_clips_dir, exist_ok=True)
            
            # Create subdirectories for gameplay presets
            gameplay_configs_dir = os.path.join(job_dir, "gameplay_configs")
            for preset in presets:
                preset_dir = os.path.join(gameplay_configs_dir, preset)
                os.makedirs(preset_dir, exist_ok=True)
        except Exception as e:
            raise JobWriteError(f"Failed to create job directories for job '{job_id}': {e}")
        
        gameplay_config_paths = {}
        for preset in presets:
            gameplay_config_paths[preset] = os.path.join(job_dir, "gameplay_configs", preset, "gameplay_config.json")
        
        return Job(
            job_id=job_id,
            job_dir=job_dir,
            source_audio_path=os.path.join(job_dir, "source_audio.wav"),
            metadata_path=os.path.join(job_dir, "metadata.json"),
            video_config_path=os.path.join(job_dir, "video_config.json"),
            gameplay_config_paths=gameplay_config_paths,
            note_clips_dir=note_clips_dir
        )

    def save_source_audio(self, job: Job, audio_path: str) -> None:
        try:
            shutil.copy2(audio_path, job.source_audio_path)
        except Exception as e:
            raise JobWriteError(f"Failed to save source audio to {job.source_audio_path}: {e}")

    def save_metadata(self, job: Job, metadata_dict: Dict[str, Any]) -> None:
        try:
            with open(job.metadata_path, "w", encoding="utf-8") as f:
                json.dump(metadata_dict, f, indent=2)
        except Exception as e:
            raise JobWriteError(f"Failed to save metadata to {job.metadata_path}: {e}")

    def save_video_config(self, job: Job, config: VideoConfig) -> None:
        try:
            with open(job.video_config_path, "w", encoding="utf-8") as f:
                json.dump(config.to_dict(), f, indent=2)
        except Exception as e:
            raise JobWriteError(f"Failed to save video config to {job.video_config_path}: {e}")

    def save_gameplay_config(self, job: Job, preset: str, gameplay_config: Dict[str, Any]) -> None:
        path = job.gameplay_config_paths.get(preset)
        if not path:
            path = os.path.join(job.job_dir, "gameplay_configs", preset, "gameplay_config.json")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(gameplay_config, f, indent=2)
        except Exception as e:
            raise JobWriteError(f"Failed to save gameplay config for preset '{preset}' to {path}: {e}")
