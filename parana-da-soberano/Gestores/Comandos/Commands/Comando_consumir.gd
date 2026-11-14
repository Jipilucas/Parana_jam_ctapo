extends Command
class_name ComandoConsumir

func execute(actor: Node) -> void:
	if actor.has_method("Consumir"):
		await actor.Consumir()

func get_command_name() -> String:
	return "Consumir"
