class_name DatosJuego

# Fórmulas de escalado infinito
static func calcular_vida_enemigo(hp_base: float, oleada: int) -> float:
	var mult: float = 1.0 + (0.10 * oleada) + (0.0025 * pow(oleada, 2))
	return hp_base * mult

static func calcular_vida_boss(hp_base: float, oleada: int) -> float:
	var mult: float = 1.0 + (0.06 * oleada) + (0.001 * pow(oleada, 2))
	return hp_base * mult

static func calcular_danio_enemigo(danio_base: float, oleada: int) -> float:
	var mult: float = 1.0 + (0.055 * oleada) + (0.0012 * pow(oleada, 2))
	return danio_base * mult

static func calcular_coste_nivel(nivel: int) -> int:
	return int(20.0 + 8.0 * (nivel - 1) + 0.6 * pow(nivel - 1, 2))

static func duracion_oleada(oleada: int) -> float:
	if oleada <= 4:
		return 45.0
	elif oleada <= 14:
		return 50.0
	return 60.0

const CATALOGO_ARMAS: Dictionary = {
	"pistola": {
		"nombre": "Pistola 9 mm",
		"tipo": "pistola",
		"danio_base": 22.0,
		"cadencia": 2.5,
		"alcance": 700.0,
		"velocidad_bala": 1200.0,
		"critico": 0.05,
		"mult_critico": 1.5,
		"penetracion": 0,
		"precio": 25
	},
	"revolver": {
		"nombre": "Revólver",
		"tipo": "pistola",
		"danio_base": 45.0,
		"cadencia": 1.25,
		"alcance": 750.0,
		"velocidad_bala": 1300.0,
		"critico": 0.10,
		"mult_critico": 1.75,
		"penetracion": 0,
		"precio": 40
	},
	"escopeta": {
		"nombre": "Escopeta",
		"tipo": "escopeta",
		"danio_base": 9.0,
		"perdigones": 7,
		"cadencia": 1.0,
		"alcance": 425.0,
		"velocidad_bala": 1000.0,
		"critico": 0.05,
		"mult_critico": 1.5,
		"penetracion": 0,
		"precio": 45
	},
	"subfusil": {
		"nombre": "Subfusil",
		"tipo": "automatica",
		"danio_base": 8.0,
		"cadencia": 7.5,
		"alcance": 575.0,
		"velocidad_bala": 1100.0,
		"critico": 0.03,
		"mult_critico": 1.5,
		"penetracion": 0,
		"precio": 50
	}
}

const MEJORAS_STATS: Array[Dictionary] = [
	{"id": "danio", "nombre": "+8% Daño Físico", "stat": "danio_mult", "valor": 0.08},
	{"id": "cadencia", "nombre": "+10% Cadencia de Ataque", "stat": "cadencia_mult", "valor": 0.10},
	{"id": "critico", "nombre": "+5% Probabilidad Crítica", "stat": "critico", "valor": 0.05},
	{"id": "vida", "nombre": "+15 Vida Máxima", "stat": "vida_max", "valor": 15.0},
	{"id": "velocidad", "nombre": "+7% Velocidad de Movimiento", "stat": "velocidad_mult", "valor": 0.07},
	{"id": "armadura", "nombre": "+2 Armadura", "stat": "armadura", "valor": 2.0},
	{"id": "vampirismo", "nombre": "+2% Robo de Vida", "stat": "robo_vida", "valor": 0.02},
	{"id": "recogida", "nombre": "+25% Rango de Recogida", "stat": "recogida_mult", "valor": 0.25}
]
