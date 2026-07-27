# 03 - Circle Bounce Mode Rules

## Muc tieu

Tai lieu nay chi mo ta rule cua `circle_bounce` game mode. Khong dua cac rule ball/circle nay vao runtime chung.

`circle_bounce` mo phong ball bay trong arena hinh tron, va cham voi boundary, moi hit lam ball tien hoa va tao note trigger.

## State cua mode

```text
CircleBounceState
  ball
  arena
  hit_count
```

## State cua ball

```text
position
velocity
radius
current_speed
```

## Update moi frame

```text
# Mo phong trong luc (Gravity Simulation): bay xuong (dir.y > 0) tang toc den +17.5%, bay len (dir.y < 0) giam toc den -15%
dir = normalize(velocity)
gravity_effect = 1.0 + (dir.y * 0.175 if dir.y > 0 else dir.y * 0.15)
position += velocity * gravity_effect * delta
check collision with arena
if valid collision:
  apply evolution
  reflect velocity (kem tempo compensation)
  resolve inside arena
  emit ball_collided event
  emit note_triggered event
```

## Collision circle arena

Voi arena:

```text
center = gameplay.arena.center
arena_radius = gameplay.arena.radius
```

Neu:

```text
distance(position, center) + ball.radius >= arena_radius
```

thi co collision.

## Reflect velocity

Normal:

```text
normal = normalize(position - center)
```

Reflect:

```text
reflected = velocity - 2 * dot(velocity, normal) * normal
# Giam dan goc phan xa (angle of incidence) ve huong tam de tao quy dao da giac bop dan thanh duong thang:
angle_to_center = angle_between(reflected, -normal)
time_ratio = clamp(current_time / duration, 0.0, 1.0)

if hit_count <= 2:
  # Va cham dau tien: ep goc lech lon (~71.6 do hay 1.25 rad + 5 do jitter) de bat dau bang da giac nhieu canh
  sign_factor = 1.0 if angle_to_center >= 0 else -1.0
  if abs(angle_to_center) < 0.2:
    sign_factor = 1.0 if rand() > 0.5 else -1.0
  target_angle = (1.25 + 0.087) * sign_factor  # 0.087 rad ~ 5 do
  rotation_needed = target_angle - angle_to_center
  reflected = rotate(reflected, rotation_needed)
else:
  # Va cham tiep theo: giam dan goc huong ve tam theo ty le decay_rate le thuoc vao thoi gian bai hat
  decay_rate = lerp(0.008, 0.08, time_ratio)
  reflected = rotate(reflected, angle_to_center * decay_rate)
  
  # Angular Precession (Tien dong goc): Tranh bong bay qua lai tren cung mot duong kinh (duong nam ngang),
  # ap dung xoay lien tuc theo so lan va cham de xoay duong kinh deu 360 do:
  if decay_rate > 0.02:
    precession_deg = 15.5
    reflected = rotate(reflected, deg_to_rad(precession_deg * (hit_count % 360)))

# Them mot chut jitter ngau nhien rat nho (+/- 0.5 do) de quy dao tu nhien:
reflected = rotate(reflected, random(-0.01, 0.01))
# Bu nhiptempo cho quang duong di chuyen bang cach nhan voi cos(theta):
cos_theta = abs(dot(normalize(reflected), -normal))
compensation = clamp(cos_theta, tempo_compensation_min, 1.0) # tempo_compensation_min mac dinh la 0.45
velocity = normalize(reflected) * (ball.current_speed * compensation)
```

Sau collision, day ball vao ben trong arena de tranh stuck:

```text
position = center + normal * (arena_radius - ball.radius - small_margin)
```

## Evolution sau moi hit

Tang truong su dung **cap so nhan** voi phase multiplier chi tac dong len **phan tram tang**, khong nhan truc tiep len toan bo he so:

```text
hit_count += 1
# Gioi han ban kinh toi da bang max_radius hoac max_radius_ratio so voi arena.radius:
absolute_max_radius = min(max_radius, arena.radius * max_radius_ratio)
# Cong thuc: phase_multiplier chi nhan voi phan tang them (growth_per_hit - 1.0)
effective_growth = 1.0 + (growth_per_hit - 1.0) * growth_multiplier
radius = min(radius * effective_growth, absolute_max_radius)

effective_speed_growth = 1.0 + (speed_growth_per_hit - 1.0) * speed_multiplier
# Su dung state toc do goc (current_speed) de tinh toan tien hoa (tranh bi anh huong boi tempo compensation)
speed = min(current_speed * effective_speed_growth, max_speed)
current_speed = speed
# Cap nhat velocity tam thoi (truoc khi ap dung tempo compensation)
velocity = normalize(velocity) * speed
```

### Vi du

Voi `growth_per_hit = 1.025`:

| Phase | growth_multiplier | effective_growth | Tang moi hit |
|---|---|---|---|
| intro | 1.0 | 1.0 + 0.025 × 1.0 = 1.025 | +2.5% |
| build_up | 2.0 | 1.0 + 0.025 × 2.0 = 1.05 | +5.0% |
| final_storm | 4.0 | 1.0 + 0.025 × 4.0 = 1.10 | +10.0% |

## Phase multiplier va Smooth Interpolation

`circle_bounce` lay phase theo current_time:

```text
intro
build_up
final_storm
```

Thay vi thay doi dot ngot theo tung phase, cac gia tri multiplier (speed_multiplier, growth_multiplier, trail_multiplier) se duoc noi suy tuyen tinh va bo tron muot ma (smoothstep lerp) giua gia tri cua phase truoc do va phase hien tai dua vao thoi gian hien tai (`current_time`):

```text
t = (time - phase_start) / phase_duration
smooth_t = t * t * (3.0 - 2.0 * t)
value = lerp(prev_phase_value, current_phase_value, smooth_t)
```

Final storm nen tang speed/growth/trail manh hon va chuyen tiep muot ma nho co che noi suy nay.

## Collision cooldown

Can co cooldown cuc ngan de tranh mot collision bi tinh nhieu lan:

```text
collision_cooldown_ms: 20 ms (COLLISION_COOLDOWN_MS = 20.0)
```

Cooldown nay la rule cua `circle_bounce`, khong phai rule chung cho moi game mode.

## Events emitted

Valid collision nen emit:

```text
GameEvent type: ball_collided
payload: CollisionInfo

GameEvent type: note_triggered
payload: NoteTrigger
```

`AudioNotePlayer` chi can lang nghe `note_triggered`. `CircleBounceView.handle_mode_event()` lang nghe `ball_collided` va phoi hop cac visual renderer (TrailRenderer, ArenaView.flash_at, BallView.trigger_pulse).
