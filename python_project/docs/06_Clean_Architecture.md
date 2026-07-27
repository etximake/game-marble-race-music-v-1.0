# 06 - Clean Architecture For Python Project

## Muc tieu

Tai lieu nay dinh nghia cach to chuc code Python de tao job data cho Godot mot cach ro rang, de test va de mo rong.

Python project co vai tro:

- Doc audio input.
- Chuan hoa audio neu can.
- Cat audio thanh note clips.
- Tao metadata.
- Tao `video_config.json`.
- Validate JSON theo schema trong `shared`.

Python project khong duoc:

- Render video.
- Chay simulation.
- Tinh collision timeline.
- Phu thuoc vao implementation ben trong cua Godot.

## Nguyen tac kien truc

Ap dung Clean Architecture nhe, uu tien MVP nhung van giu dependency direction sach.

```text
interface -> application -> domain
infrastructure -> application/domain thong qua port
domain khong phu thuoc infrastructure
```

Quy tac quan trong:

- `domain` khong import thu vien audio nhu pydub, librosa, ffmpeg wrapper.
- `domain` khong doc/ghi file.
- `application` dieu phoi use case, khong chua chi tiet codec/file system.
- `infrastructure` chua chi tiet doc file, ghi file, validate schema, cat audio.
- `interface` chi la adapter ben ngoai nhu CLI.

## Cau truc thu muc de xuat

```text
python_project/
  main.py
  README.md
  docs/

  src/
    domain/
      audio.py
      note.py
      slicing.py
      video_config.py
      job.py
      errors.py

    application/
      generate_job.py
      slice_audio.py
      generate_video_config.py
      validate_video_config.py
      ports.py

    infrastructure/
      audio/
        audio_metadata_reader.py
        audio_converter.py
        audio_slicer.py
      filesystem/
        job_repository.py
        path_builder.py
      validation/
        json_schema_validator.py

    interface/
      cli.py

  tests/
    domain/
    application/
    infrastructure/
```

Neu MVP can don gian hon, co the bat dau voi it file hon, nhung van nen giu 4 nhom layer tren.

## Domain layer

Domain layer chua cac khai niem nghiep vu cot loi.

### AudioMetadata

```text
AudioMetadata
  source_path
  duration_seconds
  sample_rate
  channel_count
  format
```

Dung de mo ta audio input sau khi doc metadata.

### SliceMode

```text
SliceMode
  manual_markers
  onset_detect
  fixed_interval
```

MVP nen uu tien `fixed_interval` va `manual_markers`. `onset_detect` co the lam sau vi co rui ro sai cao.

### SlicePlan

```text
SlicePlan
  mode
  markers
  fixed_interval_seconds
  max_note_count
  fade_in_ms
  fade_out_ms
```

Dung de mo ta cach cat audio. Object nay khong tu cat audio, chi mo ta y dinh cat.

### NoteClip

```text
NoteClip
  index
  file_name
  start_time
  end_time
  duration
```

`index` trong JSON bat dau tu 0. Ten file co the bat dau tu `note_0001.wav`.

### VideoConfig

Nen chia thanh cac object nho:

```text
VideoConfig
  project_version
  game_mode
  video
  audio
  gameplay
  visual
  text
  phases

VideoSettings
AudioSettings
GameplaySettings
VisualSettings
TextSettings
PhaseSettings
```

Khong nen truyen raw dictionary qua nhieu function trong application layer.

### Job

```text
Job
  job_id
  job_dir
  source_audio_path
  metadata_path
  video_config_path
  note_clips_dir
```

Domain chi biet cac duong dan duoi dang value. Viec tao folder that su nam o infrastructure.

## Application layer

Application layer chua use case. Use case dieu phoi domain va goi cac port.

### GenerateJobUseCase

Trach nhiem:

```text
Input:
  source audio path
  job id
  slice options
  preset options

Steps:
  validate input path
  create job folder
  read audio metadata
  convert audio to wav if needed
  build slice plan
  slice audio to note clips
  build video config
  validate video config
  write metadata
  write video_config.json

Output:
  generated job info
```

Use case nay la noi duy nhat dieu phoi pipeline chinh.

### SliceAudioUseCase

Trach nhiem:

- Validate `SlicePlan`.
- Goi `AudioSlicer` port.
- Tra ve danh sach `NoteClip`.

### GenerateVideoConfigUseCase

Trach nhiem:

- Nhan audio metadata va note clips.
- Ap dung default preset.
- Tao `VideoConfig` dung contract.
- Tao 3 phase mac dinh theo duration.

### ValidateVideoConfigUseCase

Trach nhiem:

- Validate schema.
- Validate semantic rules.
- Tra ve danh sach loi ro rang.

## Ports

Ports la interface ma application layer can, khong quan tam implementation cu the.

```text
AudioMetadataReader
  read_metadata(path) -> AudioMetadata

AudioConverter
  convert_to_wav(input_path, output_path) -> path

AudioSlicer
  slice(audio_path, slice_plan, output_dir) -> list[NoteClip]

VideoConfigValidator
  validate(config) -> ValidationResult

JobRepository
  create_job(job_id) -> Job
  save_source_audio(job, audio_path)
  save_metadata(job, metadata)
  save_video_config(job, config)
```

## Infrastructure layer

Infrastructure layer implement cac port.

Vi du:

```text
JsonSchemaVideoConfigValidator
  dung jsonschema validate theo shared/video_config.schema.json

FileSystemJobRepository
  tao generated/jobs/job_xxx/
  ghi metadata.json
  ghi video_config.json

FfmpegAudioConverter
  convert mp3/wav ve wav chuan

PydubAudioSlicer
  cat audio thanh note clips wav
```

MVP co the dung mot thu vien audio duy nhat de tranh phuc tap.

## Interface layer

CLI nen mong, chi parse input va goi use case.

Command MVP:

```bash
python main.py --input input/songs/song_001.wav --job job_001
```

Mo rong sau:

```bash
python main.py --input input/songs/song_001.wav --job job_001 --slice-mode fixed_interval --interval 0.2
python main.py --input input/songs/song_001.wav --job job_001 --slice-mode manual_markers --markers markers.json
```

CLI khong nen:

- Tu tao JSON bang raw dict dai.
- Tu cat audio truc tiep.
- Tu validate schema truc tiep.
- Chua business rule.

## Error handling

Nen co cac error ro nghia:

```text
InputAudioNotFoundError
UnsupportedAudioFormatError
AudioMetadataReadError
AudioConversionError
InvalidSlicePlanError
AudioSlicingError
VideoConfigValidationError
JobWriteError
```

Quy tac:

- Python fail fast neu input/config sai.
- Khong tao job folder hoan chinh neu validate fail.
- Neu da tao file tam va loi giua chung, nen danh dau job la failed hoac xoa file tam trong MVP.
- Loi hien ra CLI phai noi ro file/field nao sai.

## Clean code rules

### Ten ro nghia

Nen dung:

```text
GenerateJobUseCase
SlicePlan
NoteClip
VideoConfigValidator
JobRepository
```

Tranh dung qua nhieu:

```text
Manager
Processor
Handler
Helper
Utils
```

### Function mot trach nhiem

Khong nen co function lam tat ca:

```text
process_song_and_make_config_and_write_files()
```

Nen tach:

```text
read_audio_metadata()
build_slice_plan()
slice_audio()
build_video_config()
validate_video_config()
write_job_output()
```

### Han che raw dictionary

Raw dict chi nen xuat hien o boundary:

- Khi doc JSON.
- Khi ghi JSON.
- Khi validate schema.

Ben trong domain/application nen dung object/dataclass.

### Khong hard-code path

Khong nen hard-code nhieu noi:

```text
generated/jobs/job_001/note_clips/
```

Nen co `PathBuilder` hoac `JobRepository` tao path.

## Test strategy

### Domain tests

```text
test_note_filename_generation
test_fixed_interval_slice_plan_validation
test_manual_markers_must_be_ascending
test_phase_defaults_cover_duration
```

### Application tests

```text
test_generate_video_config_from_note_clips
test_validate_video_config_returns_schema_errors
test_generate_job_calls_steps_in_order_with_fake_ports
```

### Infrastructure tests

```text
test_example_config_validates_against_schema
test_job_repository_writes_expected_files
test_audio_slicer_outputs_note_files
```

### Integration test MVP

```text
given sample wav
when run generate job
then generated/jobs/job_xxx contains:
  video_config.json
  source_audio.wav
  metadata.json
  note_clips/*.wav
and video_config validates successfully
```

## MVP implementation order

Nen implement theo thu tu:

1. Domain models va errors.
2. JSON config generator voi default preset.
3. Schema validator.
4. Job repository ghi file/folder.
5. Fixed interval audio slicing.
6. CLI command MVP.
7. Manual markers slicing.
8. Onset detect sau cung neu can.

## Definition of done

Python MVP duoc xem la xong khi:

- Chay duoc command MVP voi file wav.
- Tao dung job folder.
- Tao duoc note clips wav.
- Tao duoc metadata.json.
- Tao duoc video_config.json dung schema.
- Validate semantic rules pass.
- Co it nhat test cho config generator va schema validation.
