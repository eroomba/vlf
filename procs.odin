package vlf

import "core:fmt"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

polar_delta_wobble :: proc(d:f32, a:f32) -> rl.Vector2 {
    return polar_delta(d, a + (1 - mth.floor(rand.float32() * 3)))
}

polar_delta :: proc(d:f32, a:f32) -> rl.Vector2 {
    return rl.Vector2{ d * mth.cos(a * mth.π / 180), d * mth.sin(a * mth.π / 180) }
}

polar_add :: proc(d:f32, a:f32, c:rl.Vector2) -> rl.Vector2 {
    vals := polar_delta(d, a)
    return rl.Vector2{ c.x + vals.x, c.y + vals.y }
}

vector_add :: proc(a:rl.Vector2, b:rl.Vector2) -> rl.Vector2 {
    ax:f32 = a.x * mth.cos(a.y * mth.π / 180)
    ay:f32 = a.x * mth.sin(a.y * mth.π / 180)
    bx:f32 = b.x * mth.cos(b.y * mth.π / 180)
    by:f32 = b.x * mth.sin(b.y * mth.π / 180)
    nx:f32 = ax + bx
    ny:f32 = ay + by
    return { mth.hypot(nx, ny), mth.atan2(ny, nx) * 180 / mth.π}
}

angle_avg :: proc(a:f32, b:f32) -> f32 {
    ax:f32 = mth.cos(a * mth.π / 180)
    ay:f32 = mth.sin(a * mth.π / 180)
    bx:f32 = mth.cos(b * mth.π / 180)
    by:f32 = mth.sin(b * mth.π / 180)
    nx:f32 = ax + bx
    ny:f32 = ay + by
    return mth.atan2(ny, nx) * 180 / mth.π
}