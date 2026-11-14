extends Command
class_name ComandoRecibir

func execute(actor: Node) -> void:
	if actor.has_method("Recibir"):
		await actor.Recibir()

func get_command_name() -> String:
	return "Recibir"
