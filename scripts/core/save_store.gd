extends RefCounted

static func default_path(chapter_id := "street_corner", testing := false) -> String:
	# Development writes stay inside the workspace. Exported builds use platform storage.
	var directory = "res://.local/checkpoints" if OS.has_feature("editor") else "user://checkpoints"
	if testing: directory = "res://.local/test_checkpoints"
	return directory.path_join(chapter_id + ".json")

static func write_checkpoint(data: Dictionary, path: String = "") -> String:
	if path.is_empty():
		path = default_path()
	var absolute = ProjectSettings.globalize_path(path)
	var error = DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if error != OK:
		return "无法创建存档目录（%s）" % error
	var temporary = absolute + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "无法写入存档（%s）" % FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(absolute):
		var backup = absolute + ".bak"
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		error = DirAccess.rename_absolute(absolute, backup)
		if error != OK:
			return "无法备份旧存档（%s）" % error
	error = DirAccess.rename_absolute(temporary, absolute)
	return "" if error == OK else "无法提交存档（%s）" % error

static func read_checkpoint(path: String = "") -> Dictionary:
	if path.is_empty():
		path = default_path()
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var json = JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate)) == OK and json.data is Dictionary:
			return json.data
	return {}
