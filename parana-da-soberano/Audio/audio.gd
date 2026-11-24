extends Node


func _ready() -> void:
	#Music sounds
	AudioSignals.Musica.connect(reproductor_musica)
	AudioSignals.Ambiente.connect(reproductor_ambiente)
	
#	 UI Sounds
	AudioSignals.Soberania_play.connect(play_soberania)
	AudioSignals.Moneda_Play.connect(play_moneda)
	AudioSignals.FleteTierra_Play.connect(play_flete_tierra)
	AudioSignals.FleteMar_Play.connect(play_flete_mar)
	
func reproductor_musica(estado:bool):
	if estado: $Musica.play()
	if !estado : $Musica.stop()
	pass
func reproductor_ambiente(estado:bool):
	if estado : $Ambiente.play()
	if !estado : $Ambiente.stop()
	pass
	
func play_soberania():
	$Soberania.play()
	pass

func play_moneda():
	$Moneda.play()
	pass
	
func play_flete_tierra():
	$FleteTierra.play()
	pass
	
func play_flete_mar():
	$FleteMar.play()
	pass
