from enum import Enum
from dataclasses import dataclass, field
from typing import List, Optional
from src.domain.errors import InvalidSlicePlanError

class SliceMode(Enum):
    MANUAL_MARKERS = "manual_markers"
    ONSET_DETECT = "onset_detect"
    FIXED_INTERVAL = "fixed_interval"

@dataclass(frozen=True)
class SlicePlan:
    mode: SliceMode
    markers: List[float] = field(default_factory=list)
    fixed_interval_seconds: Optional[float] = None
    max_note_count: int = 400
    fade_in_ms: int = 3
    fade_out_ms: int = 3
    target_duration_seconds: Optional[float] = None

    def validate(self) -> None:
        if self.mode == SliceMode.FIXED_INTERVAL:
            if self.fixed_interval_seconds is None or self.fixed_interval_seconds <= 0:
                raise InvalidSlicePlanError("fixed_interval_seconds must be positive for fixed_interval mode")
        elif self.mode == SliceMode.MANUAL_MARKERS:
            if not self.markers:
                raise InvalidSlicePlanError("markers list cannot be empty for manual_markers mode")
            # Check sorted and unique
            for i in range(len(self.markers) - 1):
                if self.markers[i] >= self.markers[i+1]:
                    raise InvalidSlicePlanError("markers must be strictly increasing")
            if self.markers[0] < 0:
                raise InvalidSlicePlanError("markers cannot start before 0.0 seconds")
        
        if self.max_note_count <= 0:
            raise InvalidSlicePlanError("max_note_count must be greater than 0")
        if self.fade_in_ms < 0 or self.fade_out_ms < 0:
            raise InvalidSlicePlanError("fade in/out times must be non-negative")
        if self.target_duration_seconds is not None and not (1.0 <= self.target_duration_seconds <= 30.0):
            raise InvalidSlicePlanError("target_duration_seconds must be between 1 and 30 seconds")
