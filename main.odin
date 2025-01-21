package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

screen_width:f32 = 1280
screen_height: f32 = 720

active_width:f32 = screen_height
active_height:f32 = screen_height
active_padding:f32 = 50
active_r:f32 = (screen_height / 2) - active_padding
active_x:f32 = active_r + active_padding
active_y:f32 = active_r + active_padding
active_c:rl.Vector2 = { active_x, active_y }

frame_rate:f32 = 400
delta:f32 = 0

main :: proc() {

	rl.SetConfigFlags({ .VSYNC_HINT })
	rl.InitWindow(i32(screen_width), i32(screen_height), "VLF")
	rl.SetTargetFPS(500)

	vlf_init()

    for !rl.WindowShouldClose() {
		delta += rl.GetFrameTime()
		runStep := false

		if delta >= 1 / frame_rate {
			delta = 0
			runStep = true
		}
		
		if (runStep) {
			vlf_run()
		}

		{
			rl.BeginDrawing()
			
			rl.ClearBackground(rl.BLACK)

			vlf_draw()

			rl.EndDrawing()
		}
	}
	rl.CloseWindow()

}


