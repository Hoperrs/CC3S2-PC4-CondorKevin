# Proyecto 8: Generador de manifiestos de Kubernetes parametrizado

- **Nombres**: Kevin Douglas
- **Apellidos**: Condor Chavez
- **Email:**: kcondorc@uni.pe

**URL del repositorio grupal**: https://github.com/Ox-Chema-xO/Generador-de-manifiestos-de-Kubernetes-parametrizado

---

# Práctica Calificada 05

## Tarea Elegida

* **CI/CD** de manifest templates (lint, test, deploy)

## Implementación

Se crearon las carpetas `.github/workflows/` y el archivo `ci.yml` dentro para implementar el flujo de CI/CD en GitHub Actions. Este flujo se encarga de:
- **Linting**: Validación de sintaxis YAML y estilo de código Python.
- **Unit Tests**: Ejecución de pruebas unitarias para verificar la generación de manifiestos y su validez.
- **Deployment**: Despliegue de los manifiestos generados en un clúster de Minikube.
- **E2E Tests**: Pruebas end-to-end para validar el flujo completo desde la generación hasta el despliegue y funcionamiento de la aplicación en Kubernetes.

```python
# .github/workflows/ci.yml
name: CI/CD Manifest Templates

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'templates/**'
      - 'src/**'
      - 'tests/**'
  pull_request:
    branches: [ main, develop ]

env:
  PYTHON_VERSION: '3.12'

jobs:
  lint:
    runs-on: ubuntu-latest
    name: Lint Templates y Código
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
        
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        
    - name: Lint YAML templates
      run: |
        yamllint templates/ helm-chart/app-chart/values.yaml
        
    - name: Lint Python code
      run: |
        flake8 src/ tests/

  unit-test:
    runs-on: ubuntu-latest
    name: Test con Minikube
    needs: lint
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
        
    - name: Start minikube
      uses: medyagh/setup-minikube@master
      with:
        minikube-version: 'latest'
        kubernetes-version: 'v1.33.2'
        
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        
    - name: Run unit tests
      run: |
        python -m pytest tests/test_validacion.py tests/test_validar_values.py -v
        
    - name: Test template generation
      run: |
        python src/manifest_generator.py \
          -t templates/deployment.yaml.template templates/service.yaml.template \
          -v templates/values.yaml \
          -o test-ci-output
        
    - name: Validate generated manifests
      run: |
        kubectl apply --dry-run=client -f test-ci-output/

  deploy:
    runs-on: ubuntu-latest
    name: Deploy to Minikube
    needs: unit-test

    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
        
    - name: Start minikube
      uses: medyagh/setup-minikube@master
      with:
        minikube-version: 'latest'
        kubernetes-version: 'v1.33.2'
        
    - name: Install dependencies
      run: pip install -r requirements.txt
        
    - name: Generate and deploy manifests
      run: |
        python src/manifest_generator.py \
          -t templates/deployment.yaml.template templates/service.yaml.template \
          -v templates/values.yaml \
          -o deploy-output \
          --deploy

  e2e-test:
    runs-on: ubuntu-latest
    name: E2E Tests
    needs: deploy

    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
        
    - name: Start minikube
      uses: medyagh/setup-minikube@master
      with:
        minikube-version: 'latest'
        kubernetes-version: 'v1.33.2'
    
    - name: Install dependencies
      run: pip install -r requirements.txt

    - name: Run E2E test
      run: |
        pytest tests/test_e2e_local.py
```

## Commits

Se realizaron 4 commits para implementar las funcionalidades de CI/CD (1 commit por cada job del flujo), 2 commits para arreglos de errores, y un último commit de merge de la rama `feature/condor-chavez-kevin/ci-cd-templates` a `develop`.

```bash
(.venv) hoperrs@hoperrs:~/Escritorio/Generador-de-manifiestos-de-Kubernetes-parametrizado$ git log -7 --graph
*   commit 75a8cd35ba31a1d06943d1db3ac0aad85de21d1b  (HEAD -> develop, origin/develop)
|\  Merge: 4ca856e b5fd5e4
| | Author: Guido Chipana <168389835+GuidoCh23@users.noreply.github.com>
| | Date:   Wed Jul 2 22:03:27 2025 -0500
| | 
| |     Merge pull request #25 from Ox-Chema-xO/feature/condor-chavez-kevin/ci-cd-templates
| |     
| |     Feature/condor-chavez-kevin/ci-cd-templates
| | 
| * commit b5fd5e471503a9f4dcbfedfa829993e9538fa9f5 (origin/feature/condor-chavez-kevin/ci-cd-templates, feature/condor-chavez-kevin/ci-
cd-templates)
| | Author: hoperrs <kchavezc19@gmail.com>
| | Date:   Wed Jul 2 21:53:47 2025 -0500
| | 
| |     fix: corregir comando pytest en job e2e-test
| |     
| |     Se agrega extensión .py faltante en comando pytest para ejecutar correctamente los tests E2E. Se mantiene consistencia con otros
 jobs del pipeline.
| | 
| * commit 6caad1fcd4a75f4f800c399171ec2ac6b88f5f72
| | Author: hoperrs <kchavezc19@gmail.com>
| | Date:   Wed Jul 2 21:08:32 2025 -0500
| | 
| |     feat: implementar validación E2E en pipeline CI/CD
| |     
| |     Se agrega job independiente para ejecutar tests end-to-end en minikube limpio. Se incluye configuración completa de ambiente Pyt
hon Y Kubernetes para testing de integración.
| | 
| * commit cc8fad5cfae2cf232caec1145da25ef5624d14fd
| | Author: hoperrs <kchavezc19@gmail.com>
| | Date:   Wed Jul 2 10:31:16 2025 -0500
| | 
| |     feat: implementar deployment automático de manifiestos
| |     
| |     Se agrega job deploy que ejecuta manifest_generator.py con flag --deploy. Se configura para ejecutar en minikube después de vali
dar lint y tests.
| | 
| * commit 948850929651e819a83787c0c4395a4759b43a7c
| | Author: hoperrs <kchavezc19@gmail.com>
| | Date:   Wed Jul 2 09:29:54 2025 -0500
| | 
| |     fix: agregar develop a triggers de pull request
| |     
| |     Se incluye branch develop en triggers de PR para consistencia. Permite testing automático en PRs hacia develop además de main.
| | 
| * commit 1d85e5c4b0ebe3d767b0e5ad609caea637e22b64
| | Author: hoperrs <kchavezc19@gmail.com>
| | Date:   Wed Jul 2 09:22:13 2025 -0500
| | 
| |     feat: implementar testing automatizado con minikube
| |     
| |     Se agrega job de testing que inicia minikube local. Se configuran tests unitarios y de validación de templates.
| | 
| * commit ac8485b76c3f2aba9245f44c06cad41ed7d54451
|/  Author: hoperrs <kchavezc19@gmail.com>
|   Date:   Wed Jul 2 09:03:30 2025 -0500
|   
|       feat: agregar workflow básico de GitHub Actions
|       
|       Se configura pipeline inicial con lint de YAML y Python.
```

## Validación

Se verifica el correcto funcionamiento de los 4 jobs del flujo de CI/CD:

<div a<lign="center">
  <img src="https://i.postimg.cc/fbkYJpJJ/Captura-desde-2025-07-03-08-44-10.png" alt="image1" width="600" />
</div>


## Video

https://drive.google.com/file/d/11LgvbwWjN9rsebuPTE17dYjzKfQ8SAiA/view?usp=sharing

---

# Práctica Calificada 04

## Sprint 1
Me encargué de:
- Crear el archivo de configuración `values.yaml` con parámetros para las plantillas de Kubernetes
- Definir estructura base de configuración con nombre de aplicación, imagen, réplicas y puertos necesarios para generar manifiestos dinámicos

## Sprint 2
Me encargué de:
- Implementar función de validación de manifiestos con kubectl (`validar_manifiesto_k8s`)
- Integrar la validación en el flujo principal del generador para garantizar que solo se guarden manifiestos válidos
- Agregar manejo de errores y mensajes claros para el usuario durante la validación

## Sprint 3
Me encargué de:
- Desarrollar pruebas end-to-end completas para validar el flujo desde generación hasta despliegue en Kubernetes
- Implementar prueba de redespliegue con configuración actualizada para verificar cambios en réplicas
- Validar funcionamiento del flag `--deploy` y correcta ejecución de pods y servicios


---

## Commits

```bash
hoperrs@hoperrs:~/Escritorio/Generador-de-manifiestos-de-Kubernetes-parametrizado$ git log --graph --author=hoperrs
* commit 5e05f9ad49a9b77f9c9d7699d2706279c124a070 (origin/feature/e2e-local-tests, feature/e2e-local-tests)
| Author: hoperrs <kchavezc19@gmail.com>
| Date:   Mon Jun 30 03:45:57 2025 -0500
| 
|     style(e2e): corregir formato de código para cumplir con flake8
|     
|     Ajusta espaciado, longitud de líneas y formato del código en las pruebas E2E para 
|     cumplir con las reglas de estilo de flake8.
| 
* commit 343b8e3b6b81be690935ad53213ca0124b6bd528
| Author: hoperrs <kchavezc19@gmail.com>
| Date:   Mon Jun 30 03:37:37 2025 -0500
| 
|     test(e2e): agregar prueba de redespliegue con configuración actualizada
|     
|     Implementa segunda prueba end-to-end que verifica el flujo de actualización donde 
|     el usuario modifica la configuración y redespliega la aplicación. Esta prueba 
|     valida que los cambios en réplicas se aplican correctamente y la aplicación sigue 
|     siendo accesible después de la actualización.
| 
* commit 662d96e752004c8ef02cee3f442acb6738cbab76
  Author: hoperrs <kchavezc19@gmail.com>
  Date:   Mon Jun 30 03:29:47 2025 -0500
  
      test(e2e): implementar prueba de despliegue completo de aplicación
      
      Agrega prueba end-to-end que verifica el flujo completo desde generación hasta 
      aplicación accesible en Kubernetes. Valida funcionamiento del flag --deploy y 
      correcta ejecución de pods y servicios.
  
* commit 50c16f67dfe56763d1153209798bd5ab054862de (origin/feature/validacion-manifiestos-k8s, feature/validacion-manifiestos-k8s)
| Author: hoperrs <kchavezc19@gmail.com>
| Date:   Fri Jun 27 19:21:32 2025 -0500
| 
|     style(validacion): adaptar líneas largas y mejorar legibilidad
|     
|     Se ajustan líneas largas en la función de validación y en los tests usando '\n'.
|     join para cumplir con flake8 y mantener el código más limpio y legible.
| 
* commit 8ad9d0a94f30dfb4dd3f2c30361644e0c6378996
| Author: hoperrs <kchavezc19@gmail.com>
| Date:   Fri Jun 27 18:50:04 2025 -0500
| 
|     feat(validacion): integrar validación de manifiestos en el flujo principal
|     
|     Ahora el manifiesto solo se guarda si es válido para Kubernetes usando kubectl. Se 
|     muestran mensajes claros de validación y error al usuario.
| 
* commit 5486a3714b88806a3ab369842abf279b02a9abc0
  Author: hoperrs <kchavezc19@gmail.com>
  Date:   Fri Jun 27 17:31:02 2025 -0500
  
      feat(validacion): agregar función para validar manifiestos con kubectl
      
      Se implementa la función validar_manifiesto_k8s que utiliza kubectl apply 
      --dry-run=client --validate=true para comprobar la validez de los manifiestos 
      generados. Incluye manejo de errores y mensajes claros para el usuario.
  
* commit 56dd0cba15364132f1b857b62018a0617f37da65 (origin/feature/templates-values, feature/templates-values)
  Author: hoperrs <kchavezc19@gmail.com>
  Date:   Wed Jun 25 18:13:52 2025 -0500
  
      feat(templates): agregar archivo de configuración values.yaml
      
      Crea archivo de configuración con parámetros para las plantillas de Kubernetes. 
      Incluye nombre de aplicación, imagen, réplicas y puertos necesarios para generar 
      manifiestos dinámicos.
```

---

## Makefile

Se implementó un Makefile para facilitar la ejecución de los comando en el proyecto. Los comandos disponibles son:
```shell
Comandos disponibles:
  setup      - Crear entorno virtual e instalar dependencias
  flake8     - Ejecutar linting con flake8
  minikube   - Ejecutar comandos de Minikube
  pytest     - Ejecutar tests con pytest
  all        - Ejecutar todos los comandos en secuencia
  clean      - Limpiar entorno virtual
```
Se recomienda usar el comando `make all` para ejecutar todos los comandos en secuencia.
O ejecutar los comandos de forma individual: `make <comando>`.

**Resultado esperado**:

```bash
(.venv) hoperrs@hoperrs:~/Escritorio/Generador-de-manifiestos-de-Kubernetes-parametrizado$ make all
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
Requirement already satisfied: pip in ./.venv/lib/python3.12/site-packages (24.0)
Collecting pip
  Using cached pip-25.1.1-py3-none-any.whl.metadata (3.6 kB)
Using cached pip-25.1.1-py3-none-any.whl (1.8 MB)
Installing collected packages: pip
  Attempting uninstall: pip
    Found existing installation: pip 24.0
    Uninstalling pip-24.0:
      Successfully uninstalled pip-24.0
Successfully installed pip-25.1.1
.venv/bin/pip install -r requirements.txt
Collecting flake8==7.2.0 (from -r requirements.txt (line 1))
  Using cached flake8-7.2.0-py2.py3-none-any.whl.metadata (3.8 kB)
Collecting jsonschema==4.24.0 (from -r requirements.txt (line 2))
  Using cached jsonschema-4.24.0-py3-none-any.whl.metadata (7.8 kB)
Collecting jinja2==3.1.6 (from -r requirements.txt (line 3))
  Using cached jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Collecting pytest==8.3.5 (from -r requirements.txt (line 4))
  Using cached pytest-8.3.5-py3-none-any.whl.metadata (7.6 kB)
Collecting pytest-cov==6.1.1 (from -r requirements.txt (line 5))
  Using cached pytest_cov-6.1.1-py3-none-any.whl.metadata (28 kB)
Collecting PyYAML==6.0.2 (from -r requirements.txt (line 6))
  Using cached PyYAML-6.0.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (2.1 kB)
Collecting requests==2.31.0 (from -r requirements.txt (line 7))
  Using cached requests-2.31.0-py3-none-any.whl.metadata (4.6 kB)
Collecting mccabe<0.8.0,>=0.7.0 (from flake8==7.2.0->-r requirements.txt (line 1))
  Using cached mccabe-0.7.0-py2.py3-none-any.whl.metadata (5.0 kB)
Collecting pycodestyle<2.14.0,>=2.13.0 (from flake8==7.2.0->-r requirements.txt (line 1))
  Using cached pycodestyle-2.13.0-py2.py3-none-any.whl.metadata (4.5 kB)
Collecting pyflakes<3.4.0,>=3.3.0 (from flake8==7.2.0->-r requirements.txt (line 1))
  Using cached pyflakes-3.3.2-py2.py3-none-any.whl.metadata (3.5 kB)
Collecting attrs>=22.2.0 (from jsonschema==4.24.0->-r requirements.txt (line 2))
  Using cached attrs-25.3.0-py3-none-any.whl.metadata (10 kB)
Collecting jsonschema-specifications>=2023.03.6 (from jsonschema==4.24.0->-r requirements.txt (line 2))
  Using cached jsonschema_specifications-2025.4.1-py3-none-any.whl.metadata (2.9 kB)
Collecting referencing>=0.28.4 (from jsonschema==4.24.0->-r requirements.txt (line 2))
  Using cached referencing-0.36.2-py3-none-any.whl.metadata (2.8 kB)
Collecting rpds-py>=0.7.1 (from jsonschema==4.24.0->-r requirements.txt (line 2))
  Using cached rpds_py-0.26.0-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (4.2 kB)
Collecting MarkupSafe>=2.0 (from jinja2==3.1.6->-r requirements.txt (line 3))
  Using cached MarkupSafe-3.0.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (4.0 kB)
Collecting iniconfig (from pytest==8.3.5->-r requirements.txt (line 4))
  Using cached iniconfig-2.1.0-py3-none-any.whl.metadata (2.7 kB)
Collecting packaging (from pytest==8.3.5->-r requirements.txt (line 4))
  Using cached packaging-25.0-py3-none-any.whl.metadata (3.3 kB)
Collecting pluggy<2,>=1.5 (from pytest==8.3.5->-r requirements.txt (line 4))
  Using cached pluggy-1.6.0-py3-none-any.whl.metadata (4.8 kB)
Collecting coverage>=7.5 (from coverage[toml]>=7.5->pytest-cov==6.1.1->-r requirements.txt (line 5))
  Using cached coverage-7.9.1-cp312-cp312-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (8.9 kB)
Collecting charset-normalizer<4,>=2 (from requests==2.31.0->-r requirements.txt (line 7))
  Using cached charset_normalizer-3.4.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (35 kB)
Collecting idna<4,>=2.5 (from requests==2.31.0->-r requirements.txt (line 7))
  Using cached idna-3.10-py3-none-any.whl.metadata (10 kB)
Collecting urllib3<3,>=1.21.1 (from requests==2.31.0->-r requirements.txt (line 7))
  Using cached urllib3-2.5.0-py3-none-any.whl.metadata (6.5 kB)
Collecting certifi>=2017.4.17 (from requests==2.31.0->-r requirements.txt (line 7))
  Using cached certifi-2025.6.15-py3-none-any.whl.metadata (2.4 kB)
Collecting typing-extensions>=4.4.0 (from referencing>=0.28.4->jsonschema==4.24.0->-r requirements.txt (line 2))
  Using cached typing_extensions-4.14.0-py3-none-any.whl.metadata (3.0 kB)
Using cached flake8-7.2.0-py2.py3-none-any.whl (57 kB)
Using cached jsonschema-4.24.0-py3-none-any.whl (88 kB)
Using cached jinja2-3.1.6-py3-none-any.whl (134 kB)
Using cached pytest-8.3.5-py3-none-any.whl (343 kB)
Using cached pytest_cov-6.1.1-py3-none-any.whl (23 kB)
Using cached PyYAML-6.0.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (767 kB)
Using cached requests-2.31.0-py3-none-any.whl (62 kB)
Using cached charset_normalizer-3.4.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (148 kB)
Using cached idna-3.10-py3-none-any.whl (70 kB)
Using cached mccabe-0.7.0-py2.py3-none-any.whl (7.3 kB)
Using cached pluggy-1.6.0-py3-none-any.whl (20 kB)
Using cached pycodestyle-2.13.0-py2.py3-none-any.whl (31 kB)
Using cached pyflakes-3.3.2-py2.py3-none-any.whl (63 kB)
Using cached urllib3-2.5.0-py3-none-any.whl (129 kB)
Using cached attrs-25.3.0-py3-none-any.whl (63 kB)
Using cached certifi-2025.6.15-py3-none-any.whl (157 kB)
Using cached coverage-7.9.1-cp312-cp312-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl (245 kB)
Using cached jsonschema_specifications-2025.4.1-py3-none-any.whl (18 kB)
Using cached MarkupSafe-3.0.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (23 kB)
Using cached referencing-0.36.2-py3-none-any.whl (26 kB)
Using cached rpds_py-0.26.0-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (386 kB)
Using cached typing_extensions-4.14.0-py3-none-any.whl (43 kB)
Using cached iniconfig-2.1.0-py3-none-any.whl (6.0 kB)
Using cached packaging-25.0-py3-none-any.whl (66 kB)
Installing collected packages: urllib3, typing-extensions, rpds-py, PyYAML, pyflakes, pycodestyle, pluggy, packaging, mccabe, MarkupSafe, iniconfig, idna, coverage, charset-normalizer, certifi, attrs, requests, referencing, pytest, jinja2, flake8, pytest-cov, jsonschema-specifications, jsonschema
Successfully installed MarkupSafe-3.0.2 PyYAML-6.0.2 attrs-25.3.0 certifi-2025.6.15 charset-normalizer-3.4.2 coverage-7.9.1 flake8-7.2.0 idna-3.10 iniconfig-2.1.0 jinja2-3.1.6 jsonschema-4.24.0 jsonschema-specifications-2025.4.1 mccabe-0.7.0 packaging-25.0 pluggy-1.6.0 pycodestyle-2.13.0 pyflakes-3.3.2 pytest-8.3.5 pytest-cov-6.1.1 referencing-0.36.2 requests-2.31.0 rpds-py-0.26.0 typing-extensions-4.14.0 urllib3-2.5.0
.venv/bin/flake8 tests/
Linting completado sin errores
minikube start
😄  minikube v1.36.0 en Ubuntu 24.04
✨  Using the docker driver based on existing profile
💨  For improved Docker performance, enable the overlay Linux kernel module using 'modprobe overlay'
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.47 ...
🏃  Updating the running docker "minikube" container ...
🐳  Preparando Kubernetes v1.33.1 en Docker 28.1.1...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Complementos habilitados: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
.venv/bin/pytest -v
============================================= test session starts =============================================
platform linux -- Python 3.12.3, pytest-8.3.5, pluggy-1.6.0 -- /home/hoperrs/Escritorio/Generador-de-manifiestos-de-Kubernetes-parametrizado/.venv/bin/python3.12
cachedir: .pytest_cache
rootdir: /home/hoperrs/Escritorio/Generador-de-manifiestos-de-Kubernetes-parametrizado
plugins: cov-6.1.1
collected 6 items                                                                                             

tests/test_e2e_local.py::TestE2EManifestGenerator::test_e2e_usuario_despliega_app_completa PASSED       [ 16%]
tests/test_e2e_local.py::TestE2EManifestGenerator::test_e2e_usuario_redespliega_app_actualizada PASSED  [ 33%]
tests/test_validacion.py::test_validar_manifiesto_k8s_valido PASSED                                     [ 50%]
tests/test_validacion.py::test_validar_manifiesto_k8s_invalido PASSED                                   [ 66%]
tests/test_validacion.py::test_validar_manifiesto_k8s_kubectl_no_encontrado PASSED                      [ 83%]
tests/test_validacion.py::test_validar_manifiesto_k8s_exception PASSED                                  [100%]

============================================= 6 passed in 58.73s ==============================================
Todos los comandos ejecutados exitosamente
```

---

## Archivos extras

Se mantuvieron archivos extras creados por el equipo para mantener el correcto funcionamiento del proyecto:

- **`setup.sh`**: Script de automatización para configurar el entorno del proyecto. Instala dependencias, actualiza pip y configura los hooks de Git automáticamente.

- **`hooks/pre-commit`**: Hook de Git que ejecuta validaciones antes de cada commit. Verifica sintaxis YAML de plantillas y ejecuta pruebas de calidad de código.

- **`hooks/commit-msg`**: Hook de Git que valida el formato de mensajes de commit según convenciones estándar (feat, fix, docs, style, etc.).

- **`hooks/pre-push`**: Hook de Git que ejecuta validaciones antes de hacer push al repositorio remoto, asegurando que el código cumple con los estándares de calidad.
  
- **`templates/deployment.yaml.template`**: Plantilla de Kubernetes para Deployment. Define la configuración parametrizada de despliegue de aplicaciones con variables como {{app_name}}, {{replicas}} e {{image}}.

- **`templates/service.yaml.template`**: Plantilla de Kubernetes para Service. Define la configuración parametrizada de servicios de red con variables como {{service_port}} y {{protocol}} para exponer aplicaciones.

- **`README-grupal.md`**: Documentación grupal del proyecto con información detallada sobre la implementación y colaboración del equipo.

Los demás archivos del proyecto no fueron incluidos en este repositorio pero se pueden revisar en el repositorio original del equipo.