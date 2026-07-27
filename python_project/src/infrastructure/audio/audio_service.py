import os
from pydub import AudioSegment
from src.domain.audio import AudioMetadata
from src.domain.errors import AudioMetadataReadError, AudioConversionError

class PydubAudioService:
    def read_metadata(self, path: str) -> AudioMetadata:
        if not os.path.exists(path):
            raise FileNotFoundError(f"Audio file not found at: {path}")
        try:
            # We load with pydub
            audio = AudioSegment.from_file(path)
            # Duration in seconds is milliseconds / 1000.0
            duration = len(audio) / 1000.0
            
            # Extract extension as format
            fmt = os.path.splitext(path)[1].lstrip(".").lower()
            
            return AudioMetadata(
                source_path=path,
                duration_seconds=duration,
                sample_rate=audio.frame_rate,
                channel_count=audio.channels,
                format=fmt
            )
        except Exception as e:
            raise AudioMetadataReadError(f"Failed to read audio metadata for '{path}': {e}")

    def convert_to_wav(self, input_path: str, output_path: str) -> None:
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Input audio file not found at: {input_path}")
        try:
            audio = AudioSegment.from_file(input_path)
            # Export as mono wav at 44100 Hz
            audio = audio.set_frame_rate(44100).set_channels(1)
            audio.export(output_path, format="wav")
        except Exception as e:
            raise AudioConversionError(f"Failed to convert '{input_path}' to WAV at '{output_path}': {e}")
