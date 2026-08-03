# 09 - Polygon Bounce Mode Rules

## Muc tieu

Tai lieu nay mo ta rule cua `polygon_bounce` game mode. Khong dua cac rule da giac nay vao runtime chung.

`polygon_bounce` mo phong ball bay trong arena hinh da giac (vuong, ngu giac, luc giac), va cham voi cac canh da giac, moi hit lam ball tien hoa va tao note trigger.

Mode nay dung chung `BallState` va `TrailRenderer` voi `circle_bounce`.

## State cua mode

```text
PolygonBounceState
  ball     # BallState (dung chung voi circle_bounce)
  arena    # PolygonArenaState
  hit_count
```

## State cua polygon arena

```text
PolygonArenaState
  type             # "square" | "pentagon" | "hexagon"
  center           # Vector2 tam da giac
  radius           # ban kinh duong tron ngoai tiep
  line_width       # do day duong ve
  sides            # so canh (4/5/6)
  vertices         # Array[Vector2] cac dinh da giac, tu dong tinh tu center, radius, sides
```

Cac dinh da giac duoc tinh theo cong thuc:

```text
start_angle = -PI / 2  # dinh tren cung
for i in range(sides):
    angle = start_angle + i * TAU / sides
    vertex = center + Vector2(cos(angle), sin(angle)) * radius
```

## Update moi frame

```text
# Xac dinh ten phase hien tai
phase_name = phase.get("name", "")

# Neu dang trong climax_storm, vo hieu hoa va cham arena binh thuong,
# thay vao do ball nay tu do tren toan man hinh
if phase_name == "climax_storm":
    # Bat dau tu toc do 600 * speed_multiplier (toi da max_speed * 1.5)
    # Ban kinh bong phat trien dong: climax_start_radius + time_in_climax * 45 (toi da 300)
    # Ball troi goc ngau nhien ±10 do/giay de tao hieu ung hon loan
    # Va cham voi bien man hinh (1080x1920, cach le 10px)
    # Moi va cham man hinh emit ball_collided + note_triggered
    # climax_start_radius duoc ghi nhan tai thoi diem chuyen pha de phat trien lien tuc
    return events

# Normal Play
# Mo phong trong luc (Gravity Simulation): giong circle_bounce
dir = normalize(velocity)
gravity_effect = 1.0 + (dir.y * 0.175 if dir.y > 0 else dir.y * 0.15)
position += velocity * gravity_effect * delta

check polygon collision with arena
if valid collision:
  apply evolution
  reflect velocity (kem tempo compensation)
  resolve inside arena (push ve tam arena_center)
  emit ball_collided event
  emit note_triggered event
```

## Collision polygon arena

### Tim diem gan nhat tren canh (closest point on segment)

Voi moi canh (a -> b):

```text
ab = b - a
ap = p - a
t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0)
closest_point = a + t * ab
```

### Collision detection

```text
duyet tung canh cua da giac:
    cp = closest_point_on_segment(ball.position, vertex[i], vertex[(i+1)%sides])
    dist = distance(ball.position, cp)
    lay canh co dist nho nhat

neu dist <= ball.radius -> collision

edge_normal = normalize(Vector2(-edge.y, edge.x))
neu edge_normal.dot(arena.center - cp) < 0: edge_normal = -edge_normal
normal = edge_normal
```

### Edge normal

```text
edge = vertex[i+1] - vertex[i]
edge_normal = normalize(Vector2(-edge.y, edge.x))
```

## Reflect velocity

Sau khi co normal tu edge, reflect velocity giong nhu `circle_bounce`:

```text
reflected = velocity - 2 * dot(velocity, normal) * normal
# Giam dan goc phan xa (angle of incidence) ve huong edge normal:
angle_to_center = angle_between(reflected, -normal)
time_ratio = clamp(current_time / duration, 0.0, 1.0)

if hit_count <= 2:
  sign_factor = 1.0 if angle_to_center >= 0 else -1.0
  if abs(angle_to_center) < 0.2:
    sign_factor = 1.0 if rand() > 0.5 else -1.0
  target_angle = (1.25 + 0.087) * sign_factor
  rotation_needed = target_angle - angle_to_center
  reflected = rotate(reflected, rotation_needed)
else:
  decay_rate = lerp(0.008, 0.08, time_ratio)
  reflected = rotate(reflected, angle_to_center * decay_rate)
  
  if decay_rate > 0.02:
    precession_deg = 15.5
    reflected = rotate(reflected, deg_to_rad(precession_deg * (hit_count % 360)))

reflected = rotate(reflected, random(-0.01, 0.01))
cos_theta = abs(dot(normalize(reflected), -normal))
compensation = clamp(cos_theta, tempo_compensation_min, 1.0)
velocity = normalize(reflected) * (ball.current_speed * compensation)
```

Normal la **edge normal** (huong vao trong da giac) thay vi **radial normal** (huong vao tam) nhu `circle_bounce`.

## Resolve inside arena

Sau collision, day ball huong ve tam arena (arena_center) de tranh stuck:

```text
to_center = normalize(arena_center - ball.position)
position += to_center * (penetration + SMALL_MARGIN)
```

Voi `penetration = ball.radius - closest_dist`.

## Evolution sau moi hit

Giong het `circle_bounce` - dung chung `PolygonBouncePhysics.apply_evolution()`:

```text
hit_count += 1
absolute_max_radius = min(max_radius, arena.radius * max_radius_ratio)
effective_growth = 1.0 + (growth_per_hit - 1.0) * growth_multiplier
radius = min(radius * effective_growth, absolute_max_radius)

effective_speed_growth = 1.0 + (speed_growth_per_hit - 1.0) * speed_multiplier
speed = min(current_speed * effective_speed_growth, max_speed)
current_speed = speed
velocity = normalize(velocity) * speed
```

## Arena config (polygon)

```json
"arena": {
  "type": "square",
  "center": [540, 960],
  "radius": 470,
  "line_width": 8,
  "sides": 4
}
```

| sides | type | Hinh dang |
|-------|------|-----------|
| 4 | `"square"` | Vuong |
| 5 | `"pentagon"` | Ngu giac |
| 6 | `"hexagon"` | Luc giac |

## Collision cooldown

Giong `circle_bounce`:

```text
collision_cooldown_ms: 20 ms (COLLISION_COOLDOWN_MS = 20.0)
```

## Arena rendering (PolygonArenaView)

Arena da giac duoc ve bang `draw_polyline()`:

1. **Glow layers**: 8 lop polyline mo rong dan, alpha giam dan (giong circle nhung dung polyline thay vi draw_arc)
2. **Main polygon**: `draw_polyline(vertices, color, line_width, true)`
3. **Edge flashes**: Ve circle tai diem va cham (giong circle_bounce)
4. **Neon pulses**: 6 lop polyline mo rong kem sin-smooth fade khi bong cham canh
5. **Proximity glow**: Tinh khoang cach bong den canh gan nhat de tang cuong do glow
6. **Collision sparks**: Cac tia lua neon ban ra tu diem va cham (so luong va toc do tang theo phase)
7. **Shockwave rings**: Cac vong song xung kich da giac gian no tu arena ra ngoai (3-5 vong, max scale 1.3-1.8 tuy phase), moi vong cach nhau 0.07s, ton tai 0.5s

### Arena fade-out trong climax_storm

Trong giai doan `climax_storm`, toan bo arena (ca polygon chinh, glow, edge flash, neon pulse) tu dong **mo dan va bien mat hoan toan trong 0.6 giay** qua he so `arena_alpha`. ArenaView nhan tham chieu toi controller va danh sach phase de xac dinh thoi diem bat dau fade. Khi `arena_alpha <= 0.001`, arena ngung ve hoan toan.

## File structure

```text
scripts/domain/modes/polygon_bounce/
  PolygonBounceState.gd
  ArenaState.gd          # PolygonArenaState
  PolygonBouncePhysics.gd
  CollisionInfo.gd       # PolygonCollisionInfo

scripts/application/modes/polygon_bounce/
  PolygonBounceModeController.gd

scripts/presentation/modes/polygon_bounce/
  PolygonBounceView.gd
  PolygonArenaView.gd

scenes/modes/polygon_bounce/
  PolygonBounceMode.tscn
  Arena.tscn             # dung PolygonArenaView
  Ball.tscn              # dung lai BallView cua circle_bounce
  TrailRenderer.tscn     # dung lai TrailRenderer cua circle_bounce
```

## Shared components voi circle_bounce

- `BallState` va `BallView`: Hoan toan giong nhau giua 2 mode
- `TrailRenderer`: Hoan toan giong nhau
- `PhaseRules`: Hoan toan giong nhau
- Evolution logic (growth/speed): Giong nhau, chi khac collision detection

## Events emitted

```text
GameEvent type: ball_collided
payload: PolygonCollisionInfo

GameEvent type: note_triggered
payload: NoteTrigger
```

`PolygonCollisionInfo` chua cac field giong `CollisionInfo` cua `circle_bounce`: position, normal (edge normal), hit_count, time, phase_name, ball_radius, ball_speed.
