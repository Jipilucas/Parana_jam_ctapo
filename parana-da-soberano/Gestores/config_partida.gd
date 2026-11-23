extends Node

@export_group("Estado Inicial")
@export var dinero: int = 3000
@export var soberania: float = 20.0
@export var tier_ciencia: int = 1
@export var astilleros_nacionales: int = 1

@export_group("Costos de Inversión")
@export var costo_base_ciencia: int = 100
@export var costo_tramo_magdalena: int = 150
@export var tramos_totales_magdalena: int = 5
@export var soberania_total_magdalena: float = 70.0
@export var costo_base_astillero: int = 120

func _ready() -> void:
	Partida.dinero = dinero
	Partida.soberania= soberania
	Partida.tier_ciencia=tier_ciencia
	Partida.astilleros_nacionales=astilleros_nacionales
	Partida.costo_base_ciencia=costo_base_ciencia
	Partida.costo_tramo_magdalena=costo_tramo_magdalena
	Partida.tramos_totales_magdalena=tramos_totales_magdalena
	Partida.soberania_total_magdalena=soberania_total_magdalena
	Partida.costo_base_astillero=costo_base_astillero
