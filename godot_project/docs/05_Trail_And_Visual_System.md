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
- **Ball co rainbow, glow phan ung toc do, pulse va cham, hieu ung Glass Sphere 3D**: Qua bong duoc render dang khoi thuy tinh Glass Sphere 3D sang trong, vien ngoai den dam, nen xanh la Vibrant Green, 8 lop radial gradient sang dan vao tam, cung voi nhieu lop glow phan ung theo toc do bong va hieu ung pulse phong to 12% khi va cham.
- **Rainbow Stamp Trail co fade thoi gian & gradient theo nhip**: He thong stamp tron chong chen, stamp duoc to mau dua tren chu ky va cham (hit_count) va stamp index de tao cac block mau bao hoa sac net ruc ro. Cac stamp mo dan theo tuoi dua vao elapsed_time, tao hieu ung duoi sao choi.
- Text hook o tren va duoi.

## Trail mode va Stamp System

Visual he thong duong di cua bong trong `circle_bounce` khong phai la cac duong thang noi tiep thong thuong, ma su dung **He thong Stamp (overlapping circles)**:
- Bong di chuyen den dau se de lai cac dau vet tron (stamp) tai do voi khoang cach buoc di chuyen phu thuoc ty le thuan vao ban kinh bong (`step = clampf(ball.radius * 0.28, 6.0, 22.0)`).
- Moi stamp duoc ve voi mot vien ngoai mau den mo dam (alpha = 0.9 × age_factor) co ban kinh `radius`, sau do chong mot vong tron ruot mau sac nho hon vao trong (`radius - 2.0`).
- Khi kich hoat `use_rainbow_trail`, mau sac cua chuoi stamp chuyen doi theo cong thuc: `hue = wrapf(hit_count * 0.08 + i * 0.0005, 0.0, 1.0)` tao ra cac khoi mau bat mat thay doi theo tung nhip va cham.

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

## Rainbow color va Glass Sphere 3D

### Ball (Glass Sphere 3D Rendering)
De tao hieu ung 3D thuy tinh (Glass Sphere 3D) ruc ro va chan thuc nhu hinh tham khao, Ball duoc ve bang cach xep chong cac layer tu ngoai vao trong:
1. **Outer Stroke**: Vong tron vien den hoan toan (`Color(0.0, 0.0, 0.0, 1.0)`) co ban kinh bang radius.
2. **Base Color**: Vong tron ruot mau xanh la ma sac net (`Color(0.0, 0.75, 0.1)`) co ban kinh `radius - 2.5`.
3. **Radial Gradient Layers**: Xay dung bang cach lap 8 lan tu trong ra ngoai voi ban kinh giam dan:
   - `r_level = (radius - 2.5) * (1.0 - t * 0.1)`
   - `c_alpha = t * 0.18` voi mau sac lam sang trung tam (`Color(0.1, 0.9, 0.2, c_alpha)`).
4. **Soft Center Inner Glow**: Vong tron phat sang mem o tam voi ban kinh `radius * 0.52` (`Color(0.65, 0.98, 0.55, 0.75)`) va vong thu hai ban kinh `radius * 0.36` (`Color(0.85, 1.0, 0.78, 0.90)`).
5. **White Highlight Center**: Vong tron trang loi sang choi co ban kinh `radius * 0.22` (`Color(1.0, 1.0, 1.0, 0.98)`).

Neu `use_rainbow_trail = true`, mau cua ball duoc xac dinh boi 3 yeu to vi tri, van toc va thoi gian:
- `hue = wrapf(pos_hue * 0.4 + dir_hue * 0.3 + time_hue * 0.3, 0.0, 1.0)`
- Trong do `pos_hue = position.x * 0.0003 + position.y * 0.0004`, `dir_hue = (velocity.angle() + PI) / TAU`, va `time_hue = time_elapsed * 0.06`.

### Hien thi Ball Icon va Placeholder (Dynamic Rendering)
Khi dat `use_ball_icon = true`, qua bong se duoc ve bang cach xep chong cac layer sau:
1. **Outer Stroke**: Vien tron den (`Color(0.0, 0.0, 0.0, 1.0)`) voi ban kinh radius.
2. **Icon Image / Placeholder**:
   - Neu co file anh hop le tai `ball_icon_path` (kich thuoc 512x512 px): Ve anh can chinh o giua voi ban kinh giam nhe de nam trong vien den (`dest_rect = Rect2(-radius + 2.5, -radius + 2.5, size, size)`).
   - Neu file anh chua ton tai/loi: Tu dong ve **Question Mark Placeholder** (`?`) dung font Montserrat-ExtraBold (fallback sang ThemeDB default font) tren nen mau tim quiz `#8e44ad` lam noi bat dau hoi cham vector sac net mau trang.
3. **Xoay theo dong luc hoc (Rotation Mode)**:
   - `"none"`: Giu nguyen huong thang dung.
   - `"velocity"`: Xoay goc mat cua icon huong theo huong bay cua bong (`state.velocity.angle() + PI/2.0`).
   - `"spin"`: Xoay tron deu tu dong theo thoi gian thuc (`time_elapsed * 3.0`).
4. **Bong den bi an (Silhouette Mode)**:
   - Khi `icon_silhouette_mode = true`, icon hoac dau hoi cham placeholder se bi to den toan bo (`Color(0.0, 0.0, 0.0, 1.0)`) cho den khi `time_elapsed` vuot qua thoi gian bat dau cua phase reveal (`icon_reveal_phase`, mac dinh `"final_storm"`). Luc do, màu sac goc cua anh/placeholder se duoc hien thi tro lai.
5. **Glass Overlay**: Phap dung 8 lop radial gradient mau trang trong suot (`Color(1.0, 1.0, 1.0, alpha)`) kem cac vong tron highlight o tam de tao do cong bong thuy tinh ma khong lam mat di mau sac that cua icon ben duoi.

### Arena
- Rainbow cycle cham theo thoi gian thuc: `hue = wrapf(time_elapsed * 0.05, 0.0, 1.0)`.
- Glow cuong do bien doi theo khoang cach ball den bien arena (proximity glow).
- Khi ball trong vong 15% ban kinh gan bien: `glow_intensity = 1.0 + proximity * 2.0` (toi da 3x).

### Trail stamps
- Gradient chuyen doi mau sac theo hit_count va stamp index: `hue = wrapf(hit_count * 0.08 + i * 0.0005, 0.0, 1.0)`.
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
```

## Rui ro

Neu trail qua day som, nguoi xem khong thay duoc ball. Can de visual tang theo phase.

Khong dua TrailRenderer cua `circle_bounce` thanh renderer bat buoc cho moi game mode.
