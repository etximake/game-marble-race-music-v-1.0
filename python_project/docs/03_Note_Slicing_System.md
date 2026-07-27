# 03 - Note Slicing System

## Muc tieu

Cat bai nhac thanh cac clip nho de Godot phat tung note khi active game mode emit note trigger.

Output:

```text
generated/jobs/job_001/note_clips/
  note_0001.wav
  note_0002.wav
  note_0003.wav
```

## 3 che do slice

### 1. manual_markers

Nguoi dung cung cap danh sach moc thoi gian.

Vi du:

```json
[0.00, 0.18, 0.36, 0.54, 0.72]
```

Python cat cac doan:

```text
0.00 -> 0.18
0.18 -> 0.36
0.36 -> 0.54
```

Day la che do on dinh nhat neu can sync theo bai nhac cu the.

### 2. onset_detect

Python tu phat hien diem bat dau am thanh/note.

Dung khi can cat nhanh tu bai nhac co beat ro.

Rui ro:

- Vocal, bass, drum co the lam detection sai.
- Can co buoc nghe lai va sua tay.

### 3. fixed_interval

Cat theo khoang thoi gian co dinh.

Vi du:

```text
0.20 seconds per note
```

De lam nhung it tu nhien hon onset/manual.

## Quy tac dat ten note

```text
note_0001.wav
note_0002.wav
note_0003.wav
```

Index trong JSON nen bat dau tu 0, nhung file co the bat dau tu 0001.

## Fade ngan

Moi note clip nen co fade in/fade out cuc ngan de tranh click/pop:

```text
fade in: 2-5 ms
fade out: 2-5 ms
```

## Gioi han so note

MVP nen gioi han:

```text
100-400 note clips per video
```

Qua it note thi video thua. Qua nhieu note thi audio va performance de loi.
