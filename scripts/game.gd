extends Node2D

# ODADAKİ ŞEY — Opening Room v1
# A playable foundation for the cozy pixel-horror room.
# Replace procedural art with production sprite sheets as they are cleaned.

const ROOM := Rect2(42, 48, 876, 410)
const PLAYER_SPEED := 145.0

var player := Vector2(475, 340)
var bunny := Vector2(590, 355)
var facing := Vector2.DOWN
var inspected := {}
var phase := "wake"
var dialogue_open := false
var bunny_moved := false
var room_changed := false
var pulse := 0.0

var story: Label
var prompt: Label
var objective: Label
var dialogue: Panel
var dialogue_text: Label
var dialogue_name: Label
var fade: ColorRect

func _ready() -> void:
    build_ui()
    set_process(true)
    queue_redraw()

func build_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    var title := Label.new()
    title.position = Vector2(28, 12)
    title.text = "ODADAKİ ŞEY"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#e2a8ae"))
    ui.add_child(title)

    var clock := Label.new()
    clock.position = Vector2(820, 12)
    clock.text = "03:13"
    clock.name = "Clock"
    clock.add_theme_font_size_override("font_size", 22)
    clock.add_theme_color_override("font_color", Color("#e2a8ae"))
    ui.add_child(clock)

    objective = Label.new()
    objective.position = Vector2(625, 68)
    objective.size = Vector2(270, 65)
    objective.text = "HEDEF\nOdanı kontrol et."
    objective.add_theme_font_size_override("font_size", 16)
    objective.add_theme_color_override("font_color", Color("#ead9ce"))
    ui.add_child(objective)

    prompt = Label.new()
    prompt.position = Vector2(55, 476)
    prompt.size = Vector2(850, 28)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 15)
    prompt.add_theme_color_override("font_color", Color("#d7b0b2"))
    ui.add_child(prompt)

    dialogue = Panel.new()
    dialogue.position = Vector2(260, 385)
    dialogue.size = Vector2(640, 105)
    dialogue.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#100d16e8")
    style.border_color = Color("#9c6875")
    style.set_border_width_all(2)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    dialogue.add_theme_stylebox_override("panel", style)
    ui.add_child(dialogue)

    dialogue_name = Label.new()
    dialogue_name.position = Vector2(20, 10)
    dialogue_name.text = "Tavşan"
    dialogue_name.add_theme_font_size_override("font_size", 16)
    dialogue_name.add_theme_color_override("font_color", Color("#e5a6ad"))
    dialogue.add_child(dialogue_name)

    dialogue_text = Label.new()
    dialogue_text.position = Vector2(20, 42)
    dialogue_text.size = Vector2(600, 50)
    dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_text.text = "Yine mi uyanıksın?"
    dialogue_text.add_theme_font_size_override("font_size", 17)
    dialogue_text.add_theme_color_override("font_color", Color("#eee0d8"))
    dialogue.add_child(dialogue_text)

    fade = ColorRect.new()
    fade.position = Vector2.ZERO
    fade.size = Vector2(960, 540)
    fade.color = Color(0.02, 0.01, 0.03, 0.0)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(fade)

    update_prompt()

func _process(delta: float) -> void:
    pulse += delta

    if phase == "explore" and not dialogue_open:
        var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        if dir.length() > 0:
            player += dir.normalized() * PLAYER_SPEED * delta
            facing = dir.normalized()
            player.x = clamp(player.x, 75.0, 885.0)
            player.y = clamp(player.y, 145.0, 440.0)

    if phase == "changed" and not bunny_moved:
        bunny = bunny.lerp(Vector2(690, 245), delta * 0.35)
        if bunny.distance_to(Vector2(690,245)) < 3:
            bunny_moved = true

    queue_redraw()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if dialogue_open:
            dialogue_open = false
            dialogue.visible = false
            update_prompt()
        else:
            interact()

    if event.is_action_pressed("inventory"):
        show_message("Envanter", "Şimdilik boş. Ama masanın üzerinde bir anahtar var.")

    if event.is_action_pressed("ui_cancel"):
        if dialogue_open:
            dialogue_open = false
            dialogue.visible = false
        else:
            reset_game()

func interact() -> void:
    match phase:
        "wake":
            phase = "note"
            objective.text = "HEDEF\nMasadaki notu oku."
            show_message("Not", "“Uyumadan önce odanı kontrol et.”\nAltında küçük bir tavşan çizimi var.")
        "note":
            phase = "explore"
            objective.text = "HEDEF\nOdanı kontrol et."
            update_prompt()
        "explore":
            var target := nearest_target()
            if target == "bunny":
                dialogue_open = true
                dialogue.visible = true
                dialogue_text.text = "Yine mi uyanıksın?"
                prompt.text = "E — konuşmayı bitir"
            elif target != "":
                inspect(target)
            else:
                show_message("03:13", "Ev sessiz. Çok sessiz.")
        "changed":
            if nearest_target() == "bunny":
                dialogue_open = true
                dialogue.visible = true
                dialogue_text.text = "Bu kez... beni sen çağırdın."
            else:
                phase = "branch"
                objective.text = "SEÇİM\nNereye bakacaksın?"
                prompt.text = "E — pencereye bak    |    TAB — envanter"
        "branch":
            resolve_branch()

func nearest_target() -> String:
    var targets = {
        "bed": Vector2(205, 285),
        "window": Vector2(650, 145),
        "closet": Vector2(455, 150),
        "desk": Vector2(760, 245),
        "bunny": bunny
    }
    var best := ""
    var best_d := 75.0
    for key in targets:
        var d: float = player.distance_to(targets[key])
        if d < best_d:
            best = key
            best_d = d
    return best

func inspect(target: String) -> void:
    inspected[target] = true
    match target:
        "bed":
            show_message("Yatak", "Yorganın altında bir şey varmış gibi görünüyor.\nAma dokunmaya cesaret edemiyorsun.")
        "window":
            show_message("Pencere", "Yağmur başlamış.\nCamda yansıman bir saniye gecikmeli hareket ediyor.")
        "closet":
            show_message("Dolap", "Kapı kilitli değil.\nİçeriden hafif bir tıkırtı geliyor.")
        "desk":
            show_message("Masa", "Bir anahtar ve eski bir günlük buldun.")
    if inspected.size() >= 4:
        phase = "return"
        objective.text = "HEDEF\nYatağına dön."
    update_prompt()

func show_message(title: String, text: String) -> void:
    dialogue_open = true
    dialogue.visible = true
    dialogue_name.text = title
    dialogue_text.text = text
    prompt.text = "E — devam"

func update_prompt() -> void:
    if dialogue_open:
        return
    if phase == "explore":
        prompt.text = "WASD / Oklar — hareket     E — etkileşim"
    elif phase == "return":
        prompt.text = "E — yatağa dön"
    elif phase == "branch":
        prompt.text = "E — seçimi ilerlet"
    elif phase == "ending":
        prompt.text = "Esc — yeniden başla"
    else:
        prompt.text = "E — devam"

func resolve_branch() -> void:
    phase = "ending"
    objective.text = "SON 1 — YANSIMA"
    dialogue_open = true
    dialogue.visible = true
    dialogue_name.text = "???"
    dialogue_text.text = "Penceredeki kişi sana gülümsedi.\n\nSen gülümsemedin."
    prompt.text = "Esc — yeniden başla"
    fade.color.a = 0.12

func reset_game() -> void:
    get_tree().reload_current_scene()

func _draw() -> void:
    # Background
    draw_rect(Rect2(0,0,960,540), Color("#090811"))
    draw_rect(ROOM, Color("#2b2027"))

    # Walls / lower wood
    draw_rect(Rect2(42,48,876,235), Color("#3d2b31"))
    draw_rect(Rect2(42,283,876,175), Color("#4e3638"))

    # Wallpaper panel lines
    for x in range(55, 910, 85):
        draw_line(Vector2(x,58), Vector2(x,275), Color("#53363d"), 1)

    # Floorboards
    for y in range(295, 458, 23):
        draw_line(Vector2(42,y), Vector2(918,y), Color("#6a4845"), 1)
    for x in range(70, 920, 95):
        draw_line(Vector2(x,295), Vector2(x-30,458), Color("#39272e"), 1)

    # Window + moon
    draw_rect(Rect2(625,85,145,145), Color("#11172a"))
    draw_rect(Rect2(625,85,145,145), Color("#8e5f69"), false, 5)
    draw_line(Vector2(697,85), Vector2(697,230), Color("#8e5f69"), 3)
    draw_line(Vector2(625,157), Vector2(770,157), Color("#8e5f69"), 3)
    draw_circle(Vector2(742,112), 15, Color("#e7d8bd"))
    for i in range(7):
        draw_line(Vector2(635+i*18,95), Vector2(620+i*18,225), Color("#5b6d91"), 1)

    # Bed
    draw_rect(Rect2(95,205,225,155), Color("#5a363d"))
    draw_rect(Rect2(108,220,198,118), Color("#a86c77"))
    draw_rect(Rect2(110,220,196,40), Color("#e5c6b5"))
    draw_rect(Rect2(92,345,232,20), Color("#34232a"))
    draw_circle(Vector2(205,278), 70, Color("#7d4e59"), false, 3)

    # Wardrobe
    draw_rect(Rect2(375,105,160,205), Color("#4c302c"))
    draw_rect(Rect2(375,105,160,205), Color("#956451"), false, 4)
    draw_line(Vector2(455,108), Vector2(455,307), Color("#6e493d"), 3)
    draw_circle(Vector2(445,205), 4, Color("#d5a06d"))
    draw_circle(Vector2(465,205), 4, Color("#d5a06d"))

    # Vanity
    draw_rect(Rect2(600,245,165,55), Color("#714a3d"))
    draw_rect(Rect2(625,190,115,60), Color("#1b1720"))
    draw_rect(Rect2(625,190,115,60), Color("#b37b7c"), false, 4)
    draw_ellipse(Vector2(682,220), Vector2(42,24), Color("#59657c"), false, 3)

    # Desk
    draw_rect(Rect2(760,265,130,45), Color("#6b4439"))
    draw_rect(Rect2(775,310,12,80), Color("#4a302d"))
    draw_rect(Rect2(865,310,12,80), Color("#4a302d"))

    # Rug
    draw_ellipse(Vector2(475,365), Vector2(245,85), Color("#87535c"))
    draw_ellipse(Vector2(475,365), Vector2(225,70), Color("#9d6670"), false, 3)

    # Door
    draw_rect(Rect2(830,170,72,150), Color("#5a352f"))
    draw_rect(Rect2(830,170,72,150), Color("#b07459"), false, 4)
    draw_circle(Vector2(883,245), 4, Color("#d8aa6e"))

    # Chair
    draw_rect(Rect2(790,350,55,65), Color("#68433b"))
    draw_rect(Rect2(800,335,35,20), Color("#805349"))

    # Plants / silhouette corners
    for p in [Vector2(55,415), Vector2(900,420), Vector2(60,150)]:
        draw_circle(p, 28, Color("#10141a"))

    # Player
    draw_player(player, false)

    # Bunny
    draw_bunny(bunny, room_changed)

    # Interaction ring
    if phase == "explore" and not dialogue_open:
        var target := nearest_target()
        if target != "":
            var pos = {"bed":Vector2(205,205),"window":Vector2(697,250),"closet":Vector2(455,95),"desk":Vector2(825,250),"bunny":bunny}[target]
            var r := 12.0 + sin(pulse*3.0)*2.0
            draw_circle(pos, r, Color("#e3a7ad"), false, 2)

    # Horror shadow after transition
    if phase == "changed" or phase == "branch" or phase == "ending":
        draw_circle(Vector2(895,425), 28, Color("#0a0810"))
        draw_circle(Vector2(887,418), 3, Color("#e65b61"))
        draw_circle(Vector2(903,418), 3, Color("#e65b61"))

func draw_player(p: Vector2, scared: bool) -> void:
    var hair := Color("#6a4038")
    var dress := Color("#3e314b")
    draw_circle(p + Vector2(0,-25), 14, Color("#e4b2a3"))
    draw_circle(p + Vector2(0,-30), 16, hair)
    draw_rect(Rect2(p.x-12,p.y-10,24,26), dress)
    draw_line(p+Vector2(-8,16), p+Vector2(-10,29), Color("#e5d3c6"), 5)
    draw_line(p+Vector2(8,16), p+Vector2(10,29), Color("#e5d3c6"), 5)
    draw_circle(p+Vector2(-10,31), 5, Color("#392733"))
    draw_circle(p+Vector2(10,31), 5, Color("#392733"))
    draw_circle(p+Vector2(-13,-37), 5, Color("#242035"))
    draw_circle(p+Vector2(13,-37), 5, Color("#242035"))

func draw_bunny(p: Vector2, horror: bool) -> void:
    var body := Color("#f0d5d0")
    var shadow := Color("#9e6f79")
    draw_circle(p, 17, shadow)
    draw_circle(p+Vector2(0,-13), 14, body)
    draw_circle(p+Vector2(-7,-31), 5, body)
    draw_circle(p+Vector2(7,-31), 5, body)
    draw_circle(p+Vector2(-5,-14), 2, Color("#211a22"))
    draw_circle(p+Vector2(5,-14), 2, Color("#211a22"))
    draw_circle(p+Vector2(0,-9), 2, Color("#bd7078"))
    if horror:
        draw_circle(p+Vector2(-5,-14), 3, Color("#d93645"))
        draw_circle(p+Vector2(5,-14), 3, Color("#d93645"))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color, outline := false, width := 1.0) -> void:
    var points := PackedVector2Array()
    for i in range(40):
        var a := TAU * i / 40.0
        points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
    if outline:
        draw_polyline(points, color, width)
    else:
        draw_colored_polygon(points, color)
