extends Command
class_name ComandoDespachar

func execute(actor: Node) -> void:
	if actor.has_method("Despachar"):
		await actor.Despachar()

func get_command_name() -> String:
	return "Despachar"
