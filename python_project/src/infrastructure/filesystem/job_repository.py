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

    def create_job(self, job_id: str) -> Job:
        job_dir = os.path.join(self.base_jobs_dir, job_id)
        note_clips_dir = os.path.join(job_dir, "note_clips")
        
        try:
            os.makedirs(job_dir, exist_ok=True)
            os.makedirs(note_clips_dir, exist_ok=True)
        except Exception as e:
            raise JobWriteError(f"Failed to create job directories for job '{job_id}': {e}")
        
        return Job(
            job_id=job_id,
            job_dir=job_dir,
            source_audio_path=os.path.join(job_dir, "source_audio.wav"),
            metadata_path=os.path.join(job_dir, "metadata.json"),
            video_config_path=os.path.join(job_dir, "video_config.json"),
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
