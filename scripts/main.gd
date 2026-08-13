extends Node2D

# ODADAKİ ŞEY - interactive mini horror prototype
# Godot 4.x

var state := "wake"
var flags := {
    "window": false,
    "closet": false,
    "bed": false,
    "toys": false,
    "rabbit_touched": false,
    "lied": false
}
var ending := ""

@onready var story: Label = $UI/Story
@onready var choices: VBoxContainer = $UI/Choices

func _ready() -> void:
    show_state()

func clear_choices() -> void:
    for child in choices.get_children():
        child.queue_free()

func add_choice(text: String, callback: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 42)
    b.pressed.connect(callback)
    choices.add_child(b)

func show_state() -> void:
    clear_choices()

    match state:
        "wake":
            story.text = "Bir gürültüyle uyandın.\n\nOdan karanlık. Saat 03:13. Ev tamamen sessiz.\n\nMasanda küçük bir not var."
            add_choice("Notu oku", func(): state = "note"; show_state())

        "note":
            story.text = "Notta tek bir cümle yazıyor:\n\n“Uyumadan önce odanı kontrol et.”\n\nAltında küçük bir tavşan çizimi var."
            add_choice("Kontrol etmeye başla", func(): state = "check"; show_state())

        "check":
            story.text = "Odanı kontrol et. Her şey normal görünüyor... şimdilik."
            add_choice(("✓ " if flags.window else "") + "Pencere", func(): inspect("window"))
            add_choice(("✓ " if flags.closet else "") + "Dolap", func(): inspect("closet"))
            add_choice(("✓ " if flags.bed else "") + "Yatak altı", func(): inspect("bed"))
            add_choice(("✓ " if flags.toys else "") + "Oyuncaklar", func(): inspect("toys"))
            if all_flags():
                add_choice("Yatağa dön", func(): state = "return_bed"; show_state())

        "window":
            story.text = "Pencere kilitli. Perdenin arkasında sadece gece var.\n\nAma camda kendi yansımanı göremiyorsun."
            add_choice("Geri dön", func(): state = "check"; show_state())

        "closet":
            story.text = "Dolabı açtın.\n\nBoş.\n\n...Bir dakika. En arka köşede bir tavşan kulağı gördüğüne emin misin?"
            add_choice("Elini uzat", func(): flags.rabbit_touched = true; state = "check"; show_state())
            add_choice("Dolabı kapat", func(): state = "check"; show_state())

        "bed":
            story.text = "Yatağın altına baktın. Toz, birkaç oyuncak parçası ve eski bir çizim var.\n\nÇizimde bir çocuk ve yanında tavşan var."
            add_choice("Çizimi al", func(): flags.bed = true; state = "check"; show_state())

        "toys":
            story.text = "Oyuncakların hepsi yerinde.\n\nAma tavşan oyuncağının yüzü sana dönük."
            add_choice("Tavşanı düzelt", func(): flags.rabbit_touched = true; state = "check"; show_state())
            add_choice("Hiç dokunma", func(): state = "check"; show_state())

        "return_bed":
            story.text = "Her şeyi kontrol ettin.\n\nHiçbir şey yok.\n\nYatağına geri dönüyorsun."
            add_choice("Uyumaya çalış", func(): state = "loop"; show_state())

        "loop":
            story.text = "Gözlerini kapattın.\n\n...\n\nGözlerini açtığında saat yine 03:13."
            add_choice("Odaya bak", func(): resolve_ending(); show_state())

        "ending":
            story.text = ending
            add_choice("Baştan başla", func(): reset_game())

func inspect(target: String) -> void:
    flags[target] = true
    state = target
    show_state()

func all_flags() -> bool:
    return flags.window and flags.closet and flags.bed and flags.toys

func resolve_ending() -> void:
    state = "ending"

    if flags.rabbit_touched and not flags.window:
        ending = "SON 1 — CAM\n\nPencereye baktın. Bu kez yansımanda tavşan var.\n\nAma odada tavşan yok."
    elif flags.rabbit_touched and flags.bed:
        ending = "SON 2 — YATAĞIN ALTINDA\n\nYatağın altındaki çizime tekrar baktın.\n\nÇizimdeki çocuk artık sen değilsin.\n\nÇocuk yatağın altında."
    elif flags.closet and not flags.rabbit_touched:
        ending = "SON 3 — DOLAP\n\nDolabın kapısı yavaşça açıldı.\n\nİçeriden biri fısıldadı:\n“Beni kontrol etmedin.”"
    else:
        ending = "SON 4 — UYKU\n\nHer şey normal.\n\nEn azından sen öyle olduğuna inanıyorsun.\n\nSaat 03:14 oldu.\n\nİlk kez."

func reset_game() -> void:
    flags = {"window": false, "closet": false, "bed": false, "toys": false, "rabbit_touched": false, "lied": false}
    state = "wake"
    ending = ""
    show_state()
