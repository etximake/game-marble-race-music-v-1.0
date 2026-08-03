# 05 - Trail And Visual System

## Muc tieu

Tao cam giac visual ngay cang day, cang bao ve cuoi video. Tai lieu nay mo ta visual cho mode dau tien `circle_bounce`; mode khac co the co visual renderer rieng.

## Kien truc Visual

CircleBounceView la root view node, quan ly 3 child view:
- `ArenaView` — ve arena va cac hieu ung tren arena
- `BallView` — ve ball voi glow, rainbow, shine 3D
- `TrailRenderer` — ve trail stamp doc duong di cua ball

`CircleBounceView.handle_mode_event()` nhan su kien `ball_collided` va phoi hop:
1. Goi `trail_renderer.handle_collision(info)` de queue redraw
2. Goi `arena_view.flash_at(info.position, color)` de tao edge flash + neon pulse
3. Goi `ball_view.trigger_pulse()` de kich hoat pulse animation

**Da loai bo:** Impact rings (song xung kich), web connection lines.

## Visual thanh phan cua circle_bounce

- Background den.
- **Arena circle co glow & color cycling & proximity glow & neon pulse**: Ve outline sac net o trung tam kem theo 8 lop glow ngoai ria. Glow tang cuong do (len den 3x) khi ball tien gan bien arena. Neu bat `use_rainbow_trail`, mau cua vong tron arena tu dong thay doi cham theo dai mau cau vong. Moi va cham kich hoat neon pulse toan vong tron kem edge flash tai diem va cham.
- **Ball co Neon Glow dong bo Rainbow, Pulse va cham, ngoai hinh toi co dien**: Qua bong duoc render voi nen toi sau tham (dark core `Color(0.07, 0.07, 0.09)`), vien ngoai den dam (`Color.BLACK`), va 2 lop neon outline ruc ro (lop ngoai alpha 0.3, lop trong dam net) co mau sac dong bo hoa voi rainbow trail. Tam bong co them mot diem sang bao hoa (white + glow color overlay). Toan bo mau neon duoc tinh toan dong chi dua tren thoi gian thuc de tao hieu ung bien ao lien tuc (`hue = wrapf(time_elapsed * 0.25, 0.0, 1.0)`).
- **Rainbow Stamp Trail co fade thoi gian & gradient theo nhip**: He thong stamp tron chong chen, stamp duoc to mau dua tren chu ky va cham (hit_count) va stamp index de tao cac block mau bao hoa sac net ruc ro. Cac stamp mo dan theo tuoi dua vao elapsed_time, tao hieu ung duoi sao choi.
- Text hook o tren va duoi.

## Trail mode va Stamp System

Visual he thong duong di cua bong trong `circle_bounce` khong phai la cac duong thang noi tiep thong thuong, ma su dung **He thong Stamp (overlapping circles)**:
- Bong di chuyen den dau se de lai cac dau vet tron (stamp) tai do voi khoang cach buoc di chuyen phu thuoc ty le thuan vao ban kinh bong (`step = clampf(ball.radius * 0.28, 6.0, 22.0)`).
- Moi stamp duoc ve voi mot vien ngoai mau den mo dam (alpha = 0.9 × age_factor) co ban kinh `radius`, sau do chong mot vong tron ruot mau sac nho hon vao trong (`radius - 2.0`).
- Khi kich hoat `use_rainbow_trail`, mau sac cua chuoi stamp chuyen doi theo gradient phan bo deu tren toan bo chieu dai trail: `phase = i / stamps_count; hue = wrapf(phase + elapsed_time * 0.25, 0.0, 1.0)`. Cach nay tao dai mau sac lien tuc chuyen dong cham tu dau trail (gan ball) den cuoi trail.

### Fade theo thoi gian (age-based fading)

Thay vi fade dua theo index hoac hit_count, moi stamp co `time` (thoi diem duoc tao) va age = elapsed_time - stamp.time. Age_factor duoc tinh dua tren trail_lifetime cua tung che do:

| trail_mode | trail_lifetime (s) | Max stamps | Mo ta |
|---|---|---|---|
| short | 1.5 | `200 × trail_persistence` | Trail bien mat nhanh, gon gang |
| long | 5.0 | `1200 × trail_persistence` | Trail ton tai lau hon, day dan |
| web | 12.0 | `5000 × trail_persistence` | Trail ton tai rat lau, toi da 5000 stamp |

Cong thuc: `age_factor = clamp(1.0 - (age / trail_lifetime), 0.0, 1.0)`

### Da loai bo

- Web connection lines (duong noi giua cac diem va cham)
- Ball-to-last-collision line
- `points`, `points_time`, `connections` arrays
- Fade dua theo hit_count (thay bang fade dua theo elapsed_time)

## Trail width

Chieu rong cua trail stamp duoc dong bo chat che theo su tien hoa ban kinh cua qua bong (`ball.radius`). Moi stamp luu tru ban kinh tai thoi diem duoc tao, khong thay doi theo thoi gian.

## Rainbow color va Ball Neon Rendering

### Ball (Neon Dark-Core Rendering)
Qua bong duoc ve voi phong cach neon-toi (dark aesthetic) de noi bat tren nen den va trail:
1. **Outer Stroke**: Vong tron vien den hoan toan (`Color(0.0, 0.0, 0.0, 1.0)`) co ban kinh bang radius, phan tach bong voi trail.
2. **Dark Core Background**: Vong tron nen toi tham (`Color(0.07, 0.07, 0.09)`) co ban kinh `radius - 2.5`.
3. **Neon Outline Rings (2 lop)**:
   - Vong trong dam net (`glow_col`, width 2.5) tai `radius - 3.5`.
   - Vong ngoai mo rong (`Color(glow_col.r, glow_col.g, glow_col.b, 0.3)`, width 5.5) tao anh sang neon toa ra nhe.
4. **Saturated Core Dot**: Diem sang mau trang choi (`Color.WHITE`) va overlay glow color tai tam bong (`radius * 0.22`).

Mau neon `glow_col` duoc tinh dong chi dua tren thoi gian thuc:
- `hue = wrapf(time_elapsed * 0.25, 0.0, 1.0)`

### Hien thi Ball Icon va Placeholder (Dynamic Rendering)
Khi dat `use_ball_icon = true`, qua bong se duoc ve bang cach xep chong cac layer sau:
1. **Outer Stroke**: Vien tron den (`Color(0.0, 0.0, 0.0, 1.0)`) voi ban kinh radius.
2. **Icon Image / Placeholder**:
   - Neu co file anh hop le tai `ball_icon_path` (kich thuoc 512x512 px): Ve anh can chinh o giua voi ban kinh giam nhe de nam trong vien den.
   - `_draw_question_placeholder(radius, glow_col)` dung font Montserrat-ExtraBold ve dau hoi cham `?` mau neon glow tren nen trong suot.
3. **Neon Outline**: Neon glow ring (`glow_col`, width 2.5) tai `radius - 2.5` dem lai vien sang quyen ru xung quanh icon.
4. **Xoay theo dong luc hoc (Rotation Mode)**:
   - `"none"`: Giu nguyen huong thang dung.
   - `"velocity"`: Xoay goc mat cua icon huong theo huong bay cua bong (`state.velocity.angle() + PI/2.0`).
   - `"spin"`: Xoay tron deu tu dong theo thoi gian thuc (`time_elapsed * 3.0`).
5. **Bong den bi an (Silhouette Mode)**:
   - Khi `icon_silhouette_mode = true`, hien thi dau hoi cham `?` neon glow tren nen den mo ao cho den khi `time_elapsed` vuot qua thoi gian reveal. Sau reveal, icon that hien thi voi mau sac neon glow day du.

### Arena
- Rainbow cycle cham theo thoi gian thuc: `hue = wrapf(time_elapsed * 0.05, 0.0, 1.0)`.
- Glow cuong do bien doi theo khoang cach ball den bien arena (proximity glow).
- Khi ball trong vong 15% ban kinh gan bien: `glow_intensity = 1.0 + proximity * 2.0` (toi da 3x).

### Trail stamps
- Gradient chuyen doi mau sac theo phan bo deu tren toan bo chieu dai trail: `phase = i / stamps_count; hue = wrapf(phase + elapsed_time * 0.25, 0.0, 1.0)`, tao dai mau sac cau vong lien tuc tu dau den cuoi trail va di chuyen cham theo thoi gian.
- Fade dan theo elapsed_time va trail_lifetime cua tung trail_mode. Safety limit toi da cua stamp array la `20000`.

## Arena neon pulse va Edge flash

Moi va cham hop le kich hoat 2 hieu ung tren ArenaView:

### Edge flash (0.25s)
- 1 vong tron sang tai diem va cham, ban kinh thu nho dan (16px → 4px)
- Kem 1 lop glow ngoai nhe

### Neon pulse toan vong tron (0.35s)
- 6 lop glow neon ve toan bo vong tron arena (TAU), do rong tang dan tu `line_width + 5px` den `line_width + 30px`
- Cuong do su dung `sin(alpha * PI)` de tao hieu ung bung len roi tan muot ma
- Core trang choi `alpha² * 0.8` tao cam giac den neon bung sang
- Toan bo vong tron arena phat sang

## Polygon Arena Shockwave Rings

Danh rieng cho `polygon_bounce` mode. Moi va cham hop le sinh ra cac vong song xung kich (shockwave) gian no tu arena da giac ra ngoai:

- So vong va do gian no toi da thay doi theo phase:
  - `intro`: 3 vong, max scale 1.3 (gian no nhe)
  - `build_up`: 4 vong, max scale 1.5
  - `final_storm` / `climax_storm`: 5 vong, max scale 1.8 (gian no manh)
- Moi vong cach nhau **0.07 giay** delay, tao hieu ung song lien tiep
- Moi vong ton tai **0.5 giay**, scale noi suy tu 1.0 len max_scale
- Alpha noi suy theo life: `alpha = (life / max_life) * 0.55 * arena_alpha`
- Ve bang `draw_polyline()` voi cac dinh da giac da scale tu center, do day `line_width + 4.0 * alpha`

Cac vong cung bi anh huong boi `arena_alpha` (fade-out trong climax_storm).

## Ball Pulse va cham

- Moi va cham: ball trigger pulse (`trigger_pulse()`)
- Scale tang 12% (`pulse_scale = 1.12`) roi co lai ve 1.0 trong 0.15s
- Ease-out quadratic: `lerpf(1.12, 1.0, t²)`
- Pulse chi tac dong len visual (scale ve), khong anh huong den domain radius

## Phase visual

```text
intro:
  trail vua phai (lifetime thap)
  glow arena nhe, ball glow co ban

build_up:
  trail day hon
  glow arena tang, ball glow tang
  neon pulse ro hon

final_storm:
  trail rat day (lifetime cao, nhieu stamp)
  glow arena manh (proximity glow len 3x)
  ball glow toi da, pulse nhieu
  neon pulse lien tuc

climax_storm:
  arena fade-out hoan toan trong 0.6s (arena_alpha → 0)
  ball phat trien han loai (tang truong dong, toi da 300px)
  ball bay tu do toan man hinh, neon glow manh
  trail day dac, phu kin man hinh
  countdown 3-2-1 hien thi truoc reveal voi hieu ung neon + breathing scale
```

## Countdown Overlay (UIOverlay)

Khi quiz duoc bat (`enabled = true`) va `reveal_time > 0`, `Main.gd` cap nhat lien tuc countdown thong qua `UIOverlay.update_countdown()`:
- Hien thi khi thoi gian con lai `<= 3s` va `> 0s`.
- So dem nguoc: `ceili(time_left)` → 3, 2, 1.
- Mau neon thay doi theo so: 3 = neon do (`Color(1.0, 0.2, 0.2)`), 2 = vibrant cam (`Color(1.0, 0.6, 0.0)`), 1 = neon xanh la (`Color(0.1, 1.0, 0.1)`).
- Hieu ung breathing scale: scale tu 1.0 den 1.4 dua tren `fmod(time_left, 1.0)`, tao cam giac "pop" theo nhip giay.

## Arena fade-out trong climax_storm

Trong giai doan `climax_storm`, toan bo arena (ca vong tron chinh, glow, edge flash, neon pulse) tu dong **mo dan va bien mat hoan toan trong 0.6 giay** qua he so `arena_alpha`. ArenaView nhan tham chieu toi controller va danh sach phase de xac dinh thoi diem bat dau fade. Khi `arena_alpha <= 0.001`, arena ngung ve hoan toan.

## Rui ro

Neu trail qua day som, nguoi xem khong thay duoc ball. Can de visual tang theo phase.

Khong dua TrailRenderer cua `circle_bounce` thanh renderer bat buoc cho moi game mode.
