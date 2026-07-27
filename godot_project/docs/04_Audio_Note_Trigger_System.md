# 04 - Audio Note Trigger System

## Muc tieu

Godot phat note tiep theo khi active game mode emit `note_triggered` event.

Trong mode dau tien `circle_bounce`, valid wall collision se emit `note_triggered`.

## Note order

```text
note_trigger 1 -> note_0001.wav
note_trigger 2 -> note_0002.wav
note_trigger 3 -> note_0003.wav
```

Index runtime:

```text
current_note_index = hit_count % notes.size()
```

neu `loop_notes = true`.

## AudioNotePlayer

Trach nhiem:

- Load note clips tu JSON.
- Phat note theo `note_triggered`.
- Quan ly loop notes.
- Ho tro audio_delay_ms neu can.

AudioNotePlayer khong tinh collision va khong biet rule rieng cua mode.

## Pseudocode

```text
on_note_triggered():
  note = notes[current_note_index]
  play(note)
  current_note_index += 1

  if current_note_index >= notes.size():
    if loop_notes:
      current_note_index = 0
    else:
      stop playing new notes
```

## Chong spam audio

Neu note trigger xay ra qua sat nhau, can co gioi han:

```text
min_note_interval_ms: 120 ms
```

Neu khong, audio co the bi vo/qua day va chong cheo khien nguoi nghe khong nhan dien duoc giai dieu.

## Sync

MVP: phat note truc tiep khi active mode emit `note_triggered`.

Neu co lech sync, dung:

```text
audio_delay_ms
```

trong JSON.

## Luu y

Video dang nay khong can phat full song trong Godot o MVP. Godot chi can phat note clips theo note trigger cua active mode.
