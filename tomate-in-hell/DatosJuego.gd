class_name DatosJuego

static var personaje_actual: Dictionary = {}

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

const CATALOGO_PERSONAJES: Dictionary = {
	"clasico": {
		"nombre": "Tomate Clásico",
		"hp": 100.0,
		"arma": "pistola",
		"desc": "+5% a todas las estadísticas",
		"danio_mult": 1.05,
		"velocidad_mult": 1.05,
		"cadencia_mult": 1.05,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"comando": {
		"nombre": "Comando",
		"hp": 100.0,
		"arma": "subfusil",
		"desc": "+20% daño y +15% cadencia",
		"danio_mult": 1.20,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.15,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"vaquero": {
		"nombre": "Vaquero",
		"hp": 80.0,
		"arma": "revolver",
		"desc": "+20% probabilidad crítica",
		"danio_mult": 1.0,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.20,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"brujo": {
		"nombre": "Brujo",
		"hp": 90.0,
		"arma": "pistola",
		"desc": "+30% daño base",
		"danio_mult": 1.30,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"tanque": {
		"nombre": "Tanque",
		"hp": 160.0,
		"arma": "escopeta",
		"desc": "+5 armadura, -20% velocidad",
		"danio_mult": 1.0,
		"velocidad_mult": 0.80,
		"cadencia_mult": 1.0,
		"armadura": 5.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"artillero": {
		"nombre": "Artillero",
		"hp": 110.0,
		"arma": "escopeta",
		"desc": "+35% daño, -15% cadencia",
		"danio_mult": 1.35,
		"velocidad_mult": 1.0,
		"cadencia_mult": 0.85,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"ninja": {
		"nombre": "Ninja",
		"hp": 70.0,
		"arma": "pistola",
		"desc": "+20% velocidad, +15% esquiva",
		"danio_mult": 1.0,
		"velocidad_mult": 1.20,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.15
	},
	"vampiro": {
		"nombre": "Vampiro",
		"hp": 100.0,
		"arma": "subfusil",
		"desc": "+5% robo de vida al impactar",
		"danio_mult": 1.0,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.05,
		"esquiva": 0.0
	},
	"electrico": {
		"nombre": "Eléctrico",
		"hp": 95.0,
		"arma": "subfusil",
		"desc": "+20% cadencia de disparo",
		"danio_mult": 0.90,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.20,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"piromano": {
		"nombre": "Pirómano",
		"hp": 100.0,
		"arma": "escopeta",
		"desc": "+15% daño explosivo e impacto",
		"danio_mult": 1.15,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"toxico": {
		"nombre": "Tóxico",
		"hp": 110.0,
		"arma": "pistola",
		"desc": "+10 HP extra, -10% velocidad",
		"danio_mult": 1.0,
		"velocidad_mult": 0.90,
		"cadencia_mult": 1.0,
		"armadura": 2.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"codicioso": {
		"nombre": "Codicioso",
		"hp": 100.0,
		"arma": "pistola",
		"desc": "-15% daño, mayor economía",
		"danio_mult": 0.85,
		"velocidad_mult": 1.05,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"francotirador": {
		"nombre": "Francotirador",
		"hp": 80.0,
		"arma": "revolver",
		"desc": "+30% crítico, -25% cadencia",
		"danio_mult": 1.15,
		"velocidad_mult": 1.0,
		"cadencia_mult": 0.75,
		"armadura": 0.0,
		"critico_extra": 0.30,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"berserker": {
		"nombre": "Berserker",
		"hp": 125.0,
		"arma": "escopeta",
		"desc": "+25 HP inicial, alta agresión",
		"danio_mult": 1.10,
		"velocidad_mult": 1.05,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.05,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"invocador": {
		"nombre": "Invocador",
		"hp": 85.0,
		"arma": "subfusil",
		"desc": "+30% radio de recogida",
		"danio_mult": 0.95,
		"velocidad_mult": 1.0,
		"cadencia_mult": 1.0,
		"armadura": 0.0,
		"critico_extra": 0.0,
		"robo_vida": 0.0,
		"esquiva": 0.0
	},
	"caotico": {
		"nombre": "Caótico",
		"hp": 100.0,
		"arma": "revolver",
		"desc": "Estadísticas impredecibles",
		"danio_mult": 1.10,
		"velocidad_mult": 1.10,
		"cadencia_mult": 0.90,
		"armadura": 1.0,
		"critico_extra": 0.10,
		"robo_vida": 0.02,
		"esquiva": 0.05
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
