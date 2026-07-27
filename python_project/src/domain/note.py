from dataclasses import dataclass

@dataclass(frozen=True)
class NoteClip:
    index: int
    file_name: str
    start_time: float
    end_time: float
    duration: float
