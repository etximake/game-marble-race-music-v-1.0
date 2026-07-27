class MusicBallError(Exception):
    """Base exception for Music Ball application."""
    pass

class InputAudioNotFoundError(MusicBallError):
    """Raised when the input audio file is not found."""
    pass

class UnsupportedAudioFormatError(MusicBallError):
    """Raised when the audio format is not supported."""
    pass

class AudioMetadataReadError(MusicBallError):
    """Raised when reading audio metadata fails."""
    pass

class AudioConversionError(MusicBallError):
    """Raised when audio format conversion fails."""
    pass

class InvalidSlicePlanError(MusicBallError):
    """Raised when the slice plan is invalid."""
    pass

class AudioSlicingError(MusicBallError):
    """Raised when slicing the audio file fails."""
    pass

class VideoConfigValidationError(MusicBallError):
    """Raised when the video config validation fails."""
    pass

class JobWriteError(MusicBallError):
    """Raised when writing the job output fails."""
    pass
