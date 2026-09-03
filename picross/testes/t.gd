extends SceneTree
func _initialize() -> void:
    for loc in ["pt", "en", "ja", "ru", "de", "ko", "zh"]:
        TranslationServer.set_locale(loc)
        print(loc, ": ", tr("MENU_JOGAR"), " | ", tr("MENU_CONQUISTAS"))
    quit()
