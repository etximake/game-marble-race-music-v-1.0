import os
from typing import List
from pydub import AudioSegment
from src.domain.note import NoteClip
from src.domain.slicing import SlicePlan, SliceMode
from src.domain.errors import AudioSlicingError

class PydubAudioSlicer:
    def slice(self, audio_path: str, slice_plan: SlicePlan, output_dir: str) -> List[NoteClip]:
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file for slicing not found at: {audio_path}")
        
        try:
            audio = AudioSegment.from_file(audio_path)
            total_duration_ms = len(audio)
            total_duration_sec = total_duration_ms / 1000.0
            
            markers: List[float] = []

            # 1. Determine markers based on slice mode
            if slice_plan.mode == SliceMode.FIXED_INTERVAL:
                interval = slice_plan.fixed_interval_seconds
                if not interval or interval <= 0:
                    raise AudioSlicingError("Invalid fixed interval value.")
                
                current = 0.0
                while current < total_duration_sec:
                    markers.append(current)
                    current += interval
                markers.append(total_duration_sec)
                
            elif slice_plan.mode == SliceMode.MANUAL_MARKERS:
                markers = list(slice_plan.markers)
                # Ensure the end of the audio is covered if not already present
                if not markers or markers[-1] < total_duration_sec:
                    markers.append(total_duration_sec)
            else:
                raise AudioSlicingError(f"Unsupported slice mode: {slice_plan.mode}")

            # 2. Limit the number of note clips
            max_notes = slice_plan.max_note_count
            
            note_clips: List[NoteClip] = []
            
            for i in range(len(markers) - 1):
                if len(note_clips) >= max_notes:
                    break
                
                start_sec = markers[i]
                end_sec = markers[i+1]
                
                # Check bounds
                if start_sec >= total_duration_sec:
                    break
                if end_sec > total_duration_sec:
                    end_sec = total_duration_sec
                
                duration = end_sec - start_sec
                if duration <= 0:
                    continue
                
                # Slicing
                start_ms = int(start_sec * 1000)
                end_ms = int(end_sec * 1000)
                
                clip_segment = audio[start_ms:end_ms]
                
                # Apply short fade in / fade out to avoid clicks
                if slice_plan.fade_in_ms > 0 and len(clip_segment) > slice_plan.fade_in_ms:
                    clip_segment = clip_segment.fade_in(slice_plan.fade_in_ms)
                if slice_plan.fade_out_ms > 0 and len(clip_segment) > slice_plan.fade_out_ms:
                    clip_segment = clip_segment.fade_out(slice_plan.fade_out_ms)
                
                # Write file
                file_name = f"note_{len(note_clips) + 1:04d}.wav"
                clip_output_path = os.path.join(output_dir, file_name)
                
                clip_segment.export(clip_output_path, format="wav")
                
                note_clips.append(
                    NoteClip(
                        index=len(note_clips),
                        file_name=file_name,
                        start_time=start_sec,
                        end_time=end_sec,
                        duration=duration
                    )
                )
                
            return note_clips
        except Exception as e:
            raise AudioSlicingError(f"Error occurred during audio slicing: {e}")
