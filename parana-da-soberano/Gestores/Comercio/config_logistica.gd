class_name ConfigLogistica
extends Resource

enum TipoEntidad {
	MATERIA_PRIMA,
	MANUFACTURA,
	PUERTO,
	CIUDAD
}

enum Faccion {
	NEUTRAL,
	PROPIO,
	ENEMIGO
}

enum TipoBien {
	NINGUNO,
	MATERIA_PRIMA,
	MANUFACTURA
}

enum ModoPuerto {
	EXPORTADOR,
	IMPORTADOR_MANUFACTURA,
	MIXTO
}

@export_group("Identidad")
@export var nombre_mostrar: String = "Entidad"
@export var tipo_entidad: TipoEntidad = TipoEntidad.MATERIA_PRIMA
@export var faccion_inicial: Faccion = Faccion.NEUTRAL
@export var modo_puerto: ModoPuerto = ModoPuerto.MIXTO

@export_group("Conversión de Recursos")
@export var bien_entrada: TipoBien = TipoBien.NINGUNO
@export var cantidad_consumo: int = 5
@export var bien_salida: TipoBien = TipoBien.MATERIA_PRIMA
@export var cantidad_produccion: int = 10
@export var stock_inicial_entrada: int = 0
@export var stock_inicial_salida: int = 10

@export_group("Economía y Soberanía (Por Ciclo)")
## Dinero generado por ciclo si la entidad es PROPIA o CIUDAD
@export var ganancia_propio: int = 25
## Dinero dejado por regalía mínima si la entidad es ENEMIGA (o negativo si cuesta importar)
@export var ganancia_enemigo: int = 2
## Costo de importar manufactura en el puerto para abastecer a la ciudad
@export var costo_importacion_puerto: int = 8
## Cambio en Soberanía (%) por ciclo cuando opera como PROPIA o CIUDAD abastecida
@export var impacto_soberania_propio: float = 2.0
## Cambio en Soberanía (%) por ciclo cuando opera como ENEMIGA (usualmente negativo)
@export var impacto_soberania_enemigo: float = -1.5

@export_group("Compra / Nacionalización")
@export var costo_compra: int = 120
@export var tier_ciencia_requerido: int = 2


static func nombre_bien(bien: TipoBien) -> String:
	match bien:
		TipoBien.MATERIA_PRIMA:
			return "Mat. Prima"
		TipoBien.MANUFACTURA:
			return "Manufactura"
		_:
			return "Ninguno"


static func nombre_faccion(faccion: Faccion) -> String:
	match faccion:
		Faccion.NEUTRAL:
			return "NEUTRAL"
		Faccion.PROPIO:
			return "PROPIO"
		Faccion.ENEMIGO:
			return "ENEMIGO"
		_:
			return ""
