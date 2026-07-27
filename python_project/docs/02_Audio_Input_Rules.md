# 02 - Audio Input Rules

## Dinh dang ho tro

MVP nen ho tro:

- `.wav`
- `.mp3`

Khuyen nghi convert ve `.wav` truoc khi slice de tranh loi codec.

## Do dai bai nhac

Cho Shorts, do dai nen nam trong khoang:

```text
30-60 seconds
```

MVP co the cat doan dau tien cua bai nhac hoac doan do nguoi dung chon.

## Quy tac dat ten

```text
input/songs/song_001.wav
input/songs/song_002.wav
input/songs/song_003.wav
```

Ten file nen dung chu thuong, so va dau gach duoi.

## Metadata can lay

Python nen lay:

- duration
- sample rate
- channel count
- format

Sau do ghi vao:

```text
generated/jobs/job_001/metadata.json
```

## Chuan hoa audio

Khuyen nghi:

- sample rate: 44100 Hz hoac 48000 Hz
- channel: mono cho note clips neu can nhe file
- format note clip: wav

## Ranh gioi

Python chi chuan bi audio. Godot moi la noi phat audio theo collision.
