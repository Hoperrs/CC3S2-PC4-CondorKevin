.PHONY: setup flake8 minikube pytest all clean help

# Variables
VENV_DIR = .venv
PYTHON = python3
PIP = $(VENV_DIR)/bin/pip
PYTEST = $(VENV_DIR)/bin/pytest
FLAKE8 = $(VENV_DIR)/bin/flake8

# Visualización por defecto: ayuda
.DEFAULT_GOAL := help
help:
	@echo "Comandos disponibles:"
	@echo "  setup      - Crear entorno virtual e instalar dependencias"
	@echo "  flake8     - Ejecutar linting con flake8"
	@echo "  minikube   - Ejecutar comandos de Minikube"
	@echo "  pytest     - Ejecutar tests con pytest"
	@echo "  all        - Ejecutar todos los comandos en secuencia"
	@echo "  clean      - Limpiar entorno virtual"

# Crear entorno virtual e instalar dependencias
setup:
	$(PYTHON) -m venv $(VENV_DIR)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

# Ejecutar linting con flake8
flake8: setup
	$(FLAKE8) tests/
	@echo "Linting completado sin errores"

# Iniciar Minikube
minikube:
	minikube start

# Ejecutar tests con pytest
pytest: setup
	$(PYTEST) -v

# Ejecutar todos los comandos en secuencia
all: setup flake8 minikube pytest
	@echo "Todos los comandos ejecutados exitosamente"

# Limpiar entorno virtual
clean:
	rm -rf $(VENV_DIR)
	@echo "Entorno virtual eliminado"