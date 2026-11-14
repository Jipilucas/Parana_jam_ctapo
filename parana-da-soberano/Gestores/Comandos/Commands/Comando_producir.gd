extends Command
class_name ComandoProducir

func execute(actor: Node) -> void:
	if actor.has_method("Producir"):
		await actor.Producir()

func get_command_name() -> String:
	return "Producir"
