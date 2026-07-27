from dataclasses import dataclass

@dataclass(frozen=True)
class AudioMetadata:
    source_path: str
    duration_seconds: float
    sample_rate: int
    channel_count: int
    format: str
