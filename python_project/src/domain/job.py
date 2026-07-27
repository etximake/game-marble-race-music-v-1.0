from dataclasses import dataclass

@dataclass(frozen=True)
class Job:
    job_id: str
    job_dir: str
    source_audio_path: str
    metadata_path: str
    video_config_path: str
    gameplay_config_path: str
    note_clips_dir: str
