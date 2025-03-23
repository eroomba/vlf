package vlf

import "core:fmt"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"

Player_Commands :: enum {
    None,
    Left,
    Right,
    Up,
    Down,
    Action1,
    Action2
}

Settings :: struct {
    commands : struct {
        Left:int,
        Right:int,
        Up:int,
        Down:int,
        Action1:int,
        Action2:int
    },
    mouse : struct {
        Left:Player_Commands,
        Right:Player_Commands,
        Middle:Player_Commands
    }
}

SCREEN_WIDTH:i32 : 1280
SCREEN_HEIGHT:i32 : 720
BOARD_WIDTH:f32 : 1280
BOARD_HEIGHT:f32 : 720
FRAME_RATE:i32 : 500
STEP_RATE:i32 : 96

active_width:f32 = f32(BOARD_WIDTH)
active_height:f32 = f32(BOARD_HEIGHT)
view_width:f32 = f32(SCREEN_WIDTH)
view_height:f32 = f32(SCREEN_HEIGHT)
view_offset:rl.Vector2 = { 0, 0 }

delta:f32 = 0
s_delta:f32 = 0

step:int = 0
step_delta:int = 0

mouse_button_state := []bool{false,false}
mouse_button_timer := []int{0,0}
player_commands := bit_set[Player_Commands]{}
player_settings := Settings{
    commands = {
        Left = 65, // A
        Right = 68, // D
        Up = 87, // W
        Down = 83, // S
        Action1 = 32, // SPACE
        Action2 = 69 // E
    },
    mouse = {
        Left = .Action1,
        Right = .Action2,
        Middle = .None
    }
}

debug_mode := true

main :: proc() {
    rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({ .VSYNC_HINT })
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game")
	rl.SetTargetFPS(FRAME_RATE)
	defer rl.CloseWindow()

    init_graphics()

    game_init()

    for !rl.WindowShouldClose() {
        player_commands_delta := bit_set[Player_Commands]{}

        if rl.IsKeyDown(rl.KeyboardKey.DOWN) || rl.IsKeyDown(rl.KeyboardKey.S) {
            player_commands_delta += { .Down }
        }

        if rl.IsKeyDown(rl.KeyboardKey.UP) || rl.IsKeyDown(rl.KeyboardKey.W) {
            player_commands_delta += { .Up }
        }
        
        if rl.IsKeyDown(rl.KeyboardKey.LEFT) || rl.IsKeyDown(rl.KeyboardKey.A) {
            player_commands_delta += { .Left }
        }

        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) || rl.IsKeyDown(rl.KeyboardKey.D) {
            player_commands_delta += { .Right }
        }

        key := rl.GetKeyPressed()

		// Check if more characters have been pressed on the same frame
		for key != rl.KeyboardKey.KEY_NULL { 

            if key == rl.KeyboardKey.F1 {
                game_state_update(.Paused)
            }

            if int(key) == player_settings.commands.Action1 {
				player_commands_delta += {.Action1}
			}

            if int(key) == player_settings.commands.Action2 {
				player_commands_delta += {.Action2}
			}

			key = rl.GetKeyPressed()  // Check next character in the queue
		}

        for cmd in Player_Commands {
            if cmd in player_commands_delta && !(cmd in player_commands) {
                player_commands += {cmd}
            } else if !(cmd in player_commands_delta) && cmd in player_commands {
                player_commands -= {cmd}
            }
        }

        delta += rl.GetFrameTime()
		s_delta += rl.GetFrameTime()
		runFrame := false
		runStep := false

		if s_delta >= 1 / f32(STEP_RATE) {
			s_delta = 0
			runStep = true
		}

		if delta >= 1 / f32(FRAME_RATE) {
			delta = 0
			runFrame = true
		}

		// run game step
		prev_step:int = step
		if runStep {
			run_step()
		}
		step_delta = step - prev_step

		// run game frame
		if runFrame {
			run_frame()
		}

        {
            rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
    
            // draw game step	
            draw_step()
    
            rl.EndDrawing()
        }
    }

    end_graphics()
}