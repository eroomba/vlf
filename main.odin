package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

screen_width:f32 = 1280
screen_height: f32 = 720

frame_rate:f32 = 400
delta:f32 = 0

main :: proc() {

	rl.SetConfigFlags({ .VSYNC_HINT })
	rl.InitWindow(i32(screen_width), i32(screen_height), "VLF")
	rl.SetTargetFPS(500)

    for !rl.WindowShouldClose() {
		delta += rl.GetFrameTime()
		runStep := false

		if delta >= 1 / frame_rate {
			delta = 0
			runStep = true
		}
		
		if (runStep) {
			// run game step
		}

		{
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)

			// draw game step

			rl.EndDrawing()
		}
	}
	rl.CloseWindow()

}


