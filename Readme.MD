# Documentación completa del backend de Raíces

Este documento describe de forma explícita qué hace cada archivo del backend, cómo se relacionan entre sí y qué tipo de lógica, clases y funciones contienen. El objetivo es que cualquier persona que entre al proyecto pueda entender rápidamente la arquitectura y el flujo de funcionamiento.

---

## 1. Visión general del proyecto

El backend está construido con FastAPI + SQLAlchemy + PostgreSQL y tiene como propósito gestionar usuarios, inmuebles, búsquedas y resultados de coincidencias entre ambos.

La lógica principal del sistema es la siguiente:

- Un usuario puede registrarse e iniciar sesión.
- Un usuario puede publicar inmuebles.
- Un usuario puede crear búsquedas de inmuebles según criterios como tipo, intención, precio, área, habitaciones, baños, parqueaderos y ubicación.
- El sistema compara automáticamente las búsquedas con los inmuebles publicados y guarda los resultados como coincidencias.
- Luego, el usuario puede consultar esos resultados.

En otras palabras, el backend funciona como un motor de coincidencias inmobiliarias con autenticación y persistencia en base de datos.

---

## 2. Arquitectura general

El proyecto sigue una estructura modular basada en capas:

- Capa de entrada: routers
- Capa de validación: schemas
- Capa de negocio: services
- Capa de persistencia: models y database
- Capa de seguridad: core/security.py
- Capa de configuración: core/config.py

La arquitectura es relativamente simple, pero está bien organizada para que cada parte tenga una responsabilidad concreta.

### Flujo general de una petición

1. El cliente realiza una petición a la API definida en [app/main.py](app/main.py).
2. FastAPI dirige la petición al router correspondiente.
3. El router recibe los datos, valida la entrada con los schemas y usa la sesión de base de datos.
4. Si la operación implica lógica de negocio, se invoca un servicio, por ejemplo el matching engine.
5. El resultado se guarda o se devuelve al cliente en formato JSON.

---

## 3. Dependencias y tecnologías principales

El proyecto usa las siguientes tecnologías:

- FastAPI: para construir la API REST.
- SQLAlchemy: para definir modelos ORM y trabajar con bases de datos relacionales.
- Pydantic: para validar y serializar los datos de entrada y salida.
- PostgreSQL: como motor de base de datos principal.
- python-jose: para manejar JWT.
- passlib / hashlib: para trabajar con contraseñas.
- Faker: para generar datos de prueba.
- python-dotenv: para cargar variables de entorno.

El archivo [requirements.txt](requirements.txt) contiene todas estas dependencias.

---

## 4. Estructura de carpetas y propósito de cada una

### app/main.py
Archivo principal de la aplicación.

Función:
- Crea la instancia de FastAPI.
- Inicializa la base de datos llamando a create_database().
- Registra todos los routers de la API.

Relaciones:
- Importa la conexión a la base de datos desde [app/database/database.py](app/database/database.py).
- Importa los routers de autenticación, usuarios, inmuebles, búsquedas y resultados.

Lógica que contiene:
- Creación de la aplicación.
- Registro de endpoints mediante include_router().

### app/core/
Carpeta que contiene utilidades transversales del sistema.

#### app/core/config.py
Archivo de configuración general.

Función:
- Carga variables de entorno desde el archivo .env.
- Define valores como usuario de PostgreSQL, contraseña, host, puerto, base de datos, secreto JWT y algoritmo de firma.

Relaciones:
- Es consumido por [app/database/database.py](app/database/database.py) para construir la URL de conexión.
- Es usado por [app/core/security.py](app/core/security.py) para crear y validar tokens JWT.

Lógica que contiene:
- Lectura de variables de entorno con os.getenv().
- Conversión de valores numéricos como ACCESS_TOKEN_EXPIRE_MINUTES.

#### app/core/enums.py
Define los enumeradores usados por el sistema.

Función:
- Establece los tipos de inmueble permitidos.
- Define las intenciones de venta o arriendo.
- Define los estratos socioeconómicos permitidos.

Relaciones:
- Es usado por los modelos SQLAlchemy en [app/models/models.py](app/models/models.py).
- Es usado por los schemas de entrada y salida en [app/schemas](app/schemas).

Lógica que contiene:
- Enumeraciones base del dominio inmobiliario.

#### app/core/security.py
Archivo central de seguridad y autenticación.

Función:
- Hash de contraseñas con SHA-256.
- Verificación de contraseñas.
- Creación de tokens JWT de acceso.
- Extracción del usuario autenticado a partir del token.

Relaciones:
- Usa [app/database/database.py](app/database/database.py) para obtener la sesión de base de datos.
- Usa [app/models/models.py](app/models/models.py) para buscar al usuario en la base de datos.
- Usa [app/core/config.py](app/core/config.py) para obtener la configuración del JWT.

Lógica que contiene:
- hash_password()
- verify_password()
- create_access_token()
- get_current_user()

Importante:
- El sistema usa un esquema OAuth2PasswordBearer con tokenUrl="auth/login".
- Un usuario autenticado se puede obtener automáticamente en cualquier ruta que dependa de get_current_user.

### app/database/
Carpeta encargada de la conexión a la base de datos.

#### app/database/database.py
Archivo principal de conexión SQLAlchemy.

Función:
- Crea el engine de SQLAlchemy.
- Define la sesión de base de datos SessionLocal.
- Define la clase Base usada por todos los modelos ORM.
- Proporciona funciones para obtener una sesión y crear o resetear tablas.

Relaciones:
- Es usado por casi todo el backend: routers, services, scripts y seguridad.
- Es la base para que los modelos puedan persistirse en PostgreSQL.

Lógica que contiene:
- create_engine()
- get_db(): contexto de sesión para FastAPI.
- create_database(): crea todas las tablas.
- reset_database(): elimina y vuelve a crear las tablas.

### app/models/
Carpeta donde están definidos los modelos ORM de SQLAlchemy.

#### app/models/models.py
Archivo con la estructura de la base de datos.

Función:
- Define las tablas de usuarios, inmuebles, búsquedas, resultados, ciudades, localidades y barrios.
- Establece relaciones entre entidades.

Entidades principales:
- Usuario: representa a un usuario del sistema.
- Inmueble: representa un inmueble publicado por un propietario.
- Busqueda: representa un criterio de búsqueda definido por un usuario.
- Resultado: conecta una búsqueda con un inmueble que coincidió.
- Ciudad, Localidad, Barrio: representan la estructura geográfica.

Relaciones importantes:
- Un usuario tiene muchos inmuebles y muchas búsquedas.
- Un inmueble pertenece a un propietario y a un barrio.
- Una búsqueda pertenece a un usuario y puede apuntar a una ciudad, localidad o barrio.
- Un resultado representa una coincidencia entre una búsqueda y un inmueble.

Lógica que contiene:
- Definición de tablas con Column, ForeignKey, relationship.
- Definición de cascadas de borrado para mantener consistencia.

### app/schemas/
Carpeta que contiene los modelos Pydantic para validar datos.

#### app/schemas/usuario.py
Define la estructura de entrada y salida para usuarios.

Clases:
- UserBase: atributos comunes del usuario.
- UserCreate: datos necesarios para registrar un usuario.
- UserUpdate: datos permitidos para actualizar un usuario.
- UserResponse: respuesta que se devuelve al cliente.
- ChangePasswordRequest: estructura para cambiar contraseña.

Relación:
- Es usado por [app/routers/usuarios.py](app/routers/usuarios.py).

#### app/schemas/inmueble.py
Define los datos para crear y devolver inmuebles.

Clases:
- InmuebleBase: atributos comunes del inmueble.
- InmuebleCreate: payload para crear un inmueble.
- InmuebleResponse: respuesta enviada al cliente.

Relación:
- Es usado por [app/routers/inmuebles.py](app/routers/inmuebles.py).

#### app/schemas/busqueda.py
Define los datos para filtrar y crear búsquedas.

Clases:
- BusquedaBase: campos de la búsqueda.
- BusquedaCreate: estructura para crear una búsqueda.
- BusquedaResponse: estructura de respuesta.

Relación:
- Es usado por [app/routers/busquedas.py](app/routers/busquedas.py).

#### app/schemas/resultado.py
Define la forma en que se representan los resultados de coincidencia.

Clases:
- ResultadoBase: campos base.
- ResultadoResponse: respuesta al cliente.

Relación:
- Aunque actualmente no se usa directamente como endpoint principal, su estructura está pensada para representar coincidencias.

### app/routers/
Contiene los endpoints HTTP de la API.

#### app/routers/auth.py
Router de autenticación.

Función:
- Autentica un usuario mediante correo y contraseña.
- Devuelve un token JWT si las credenciales son correctas.

Endpoint principal:
- POST /auth/login

Relaciones:
- Usa [app/core/security.py](app/core/security.py) para verificar la contraseña y crear el token.
- Usa [app/database/database.py](app/database/database.py) para consultar al usuario.

#### app/routers/usuarios.py
Router de usuarios.

Función:
- Listar usuarios.
- Crear usuarios.
- Consultar el perfil propio.
- Cambiar la contraseña.
- Actualizar datos del usuario.
- Eliminar el propio usuario.

Endpoints principales:
- GET /users/
- POST /users/
- GET /users/me
- PUT /users/me/change-password
- PUT /users/me/update
- DELETE /users/me

Relaciones:
- Usa [app/schemas/usuario.py](app/schemas/usuario.py).
- Usa [app/core/security.py](app/core/security.py) porque todas las operaciones de perfil propio requieren autenticación.

#### app/routers/inmuebles.py
Router de inmuebles.

Función:
- Crear un inmueble asociado al usuario autenticado.
- Listar todos los inmuebles.
- Actualizar un inmueble.
- Eliminar un inmueble.

Endpoints principales:
- POST /inmuebles/
- GET /inmuebles/
- PUT /inmuebles/{inmueble_id}
- DELETE /inmuebles/{inmueble_id}

Lógica de negocio importante:
- Al crear o actualizar un inmueble, el sistema busca coincidencias con las búsquedas existentes usando el matching engine.
- Luego guarda esos resultados en la tabla resultados.

Relaciones:
- Usa [app/services/matching_engine.py](app/services/matching_engine.py).
- Usa [app/models/models.py](app/models/models.py) para insertar el inmueble.

#### app/routers/busquedas.py
Router de búsquedas.

Función:
- Crear una búsqueda de inmueble.
- Consultar búsquedas.
- Obtener una búsqueda por ID.
- Actualizar una búsqueda.
- Eliminar una búsqueda.

Endpoints principales:
- POST /busquedas/
- GET /busquedas/
- GET /busquedas/{busqueda_id}
- PUT /busquedas/{busqueda_id}
- DELETE /busquedas/{busqueda_id}

Lógica de negocio importante:
- Al crear o actualizar una búsqueda, el sistema compara esa búsqueda con los inmuebles existentes.
- Los resultados se almacenan en la tabla resultados.

Relaciones:
- Usa [app/services/matching_engine.py](app/services/matching_engine.py).
- Usa [app/core/security.py](app/core/security.py) para identificar al usuario autenticado.

#### app/routers/resultados.py
Router de resultados de coincidencia.

Función:
- Mostrar los inmuebles que coincidieron con las búsquedas del usuario.
- Mostrar los resultados de una búsqueda específica.

Endpoints principales:
- GET /resultados/mis_resultados
- GET /resultados/busqueda/{busqueda_id}

Relaciones:
- Usa [app/models/models.py](app/models/models.py) para unir tablas como Resultado, Busqueda e Inmueble.
- No usa directamente el matching engine, porque los resultados ya están calculados y almacenados.

### app/services/
Contiene la lógica de negocio más importante del sistema.

#### app/services/matching_engine.py
Es el corazón funcional del backend.

Función:
- Encontrar todos los inmuebles que coinciden con una búsqueda.
- Encontrar todas las búsquedas que coinciden con un inmueble.
- Guardar esas coincidencias en la tabla resultados.

Funciones principales:
- find_matches(busqueda, db): construye una consulta SQLAlchemy filtrando por tipo, intención, área, habitaciones, baños, parqueaderos, precio y ubicación.
- find_searches(inmueble, db): busca búsquedas que encajen con un inmueble nuevo.
- save_matches(busqueda, resultados, db): elimina los resultados previos de una búsqueda y los reemplaza con nuevos.
- save_matches_from_property(inmueble, busquedas, db): elimina resultados previos para un inmueble y los vuelve a guardar según nuevas búsquedas.

Relaciones:
- Se usa desde [app/routers/inmuebles.py](app/routers/inmuebles.py) y [app/routers/busquedas.py](app/routers/busquedas.py).
- Trabaja directamente con [app/models/models.py](app/models/models.py).

Lógica importante:
- El sistema no realiza coincidencias en tiempo real de forma compleja; las calcula cuando se crean o editan inmuebles o búsquedas.
- Usa joins con Barrio, Localidad y Ciudad para filtrar por ubicación.

#### app/services/notification_service.py
Archivo preparado para futuras notificaciones.

Función actual:
- Está vacío y no tiene lógica implementada.

Relación:
- Está pensado para extender el sistema con notificaciones al usuario cuando se genere una coincidencia nueva.

### app/scripts/
Carpeta con scripts de carga de datos.

#### app/scripts/populate_locations.py
Función:
- Inserta en base de datos la ciudad de Bogotá.
- Inserta sus localidades y barrios.
- Usa el archivo [app/data/Bogota.py](app/data/Bogota.py) como fuente de datos.

#### app/scripts/populate_users.py
Función:
- Crea usuarios de prueba.
- Genera nombres, apellidos, correos y teléfonos con ayuda de DataGenerator.
- Hashea las contraseñas con la función de seguridad del sistema.

#### app/scripts/populate_properties.py
Función:
- Genera inmuebles aleatorios de prueba.
- Asigna aleatoriamente propietarios y barrios.
- Usa DataGenerator para asignar características realistas como área, habitaciones, baños y precio.

### app/generators/
Carpeta con generadores de datos de prueba.

#### app/generators/data_generator.py
Función:
- Genera datos falsos realistas usando Faker.
- Construye valores aleatorios para nombres, correos, teléfonos, tipos de inmueble, intenciones, áreas, habitaciones, baños, parqueaderos, estratos y precios.

Relación:
- Es usado por los scripts de carga de datos.

### app/utils/
Carpeta con funciones auxiliares.

#### app/utils/decode.py
Función:
- Normaliza textos eliminando tildes y caracteres especiales.
- Convierte los textos a minúsculas.

Relación:
- Se usa por los scripts para limpiar nombres de ciudades, localidades y barrios al poblar la base de datos.

### app/data/
Carpeta con datos base estáticos.

#### app/data/Bogota.py
Función:
- Contiene un diccionario con localidades y barrios de Bogotá.
- Incluye datos de estrato mínimo, estrato máximo y valor por metro cuadrado.

Relación:
- Es consumido por [app/scripts/populate_locations.py](app/scripts/populate_locations.py) para poblar la base de datos.

### app/tests/
Carpeta de pruebas o scripts de inicialización.

#### app/tests/test.py
Función:
- Proporciona un flujo de prueba para reiniciar la base de datos y cargar datos de ejemplo.
- Usa populate_users, populate_locations y populate_properties para sembrar datos de prueba.

Relación:
- Es un script de apoyo para pruebas y desarrollo local.

---

## 5. Cómo se conectan los archivos entre sí

### Conexión principal de la API
- [app/main.py](app/main.py) monta la aplicación y registra los routers.

### Conexión de autenticación
- [app/routers/auth.py](app/routers/auth.py) usa [app/core/security.py](app/core/security.py).
- [app/routers/usuarios.py](app/routers/usuarios.py) también depende de esa seguridad para proteger rutas de usuario.

### Conexión entre modelos y base de datos
- [app/models/models.py](app/models/models.py) define las tablas.
- [app/database/database.py](app/database/database.py) crea la conexión y la base común.
- Todo router que inserta o consulta datos usa la sesión obtenida con get_db().

### Conexión entre búsquedas e inmuebles
- [app/routers/inmuebles.py](app/routers/inmuebles.py) y [app/routers/busquedas.py](app/routers/busquedas.py) invocan a [app/services/matching_engine.py](app/services/matching_engine.py).
- Ese servicio compara criterios y genera registros en [app/models/models.py](app/models/models.py) dentro de la tabla Resultado.

### Conexión con validación de datos
- Los endpoints reciben datos con los schemas de [app/schemas](app/schemas).
- Los schemas validan la estructura de entrada/salida usando Pydantic.

---

## 6. Flujo funcional más importante

### Flujo de registro e inicio de sesión
1. El cliente envía datos a /users/.
2. El router crea un usuario en la base de datos.
3. La contraseña se hashea antes de guardarla.
4. Luego, el cliente puede autenticarse en /auth/login.
5. El backend valida las credenciales y devuelve un JWT.

### Flujo de publicación de un inmueble
1. El usuario autenticado envía un inmueble a /inmuebles/.
2. El router inserta el inmueble en la base de datos.
3. El matching engine busca búsquedas compatibles.
4. Se generan registros en resultados.
5. El inmueble queda listo para consultarse.

### Flujo de creación de una búsqueda
1. El usuario autenticado envía una búsqueda a /busquedas/.
2. El router guarda la búsqueda.
3. El matching engine compara esa búsqueda con todos los inmuebles existentes.
4. Se crean resultados que vinculan la búsqueda con los inmuebles que cumplen las condiciones.

### Flujo de consulta de resultados
1. El usuario consulta /resultados/mis_resultados o /resultados/busqueda/{id}.
2. El backend recupera los inmuebles asociados a sus búsquedas.
3. El cliente recibe la lista de coincidencias.

---

## 7. Lógica de negocio principal del sistema

### Autenticación
- Se implementa con JWT.
- La seguridad se centraliza en [app/core/security.py](app/core/security.py).

### Gestión de usuarios
- Se permite crear, consultar y modificar datos personales.
- La contraseña nunca debe guardarse en texto claro; el sistema la hashea.

### Gestión de inmuebles
- Cada inmueble tiene un propietario.
- Se guarda información sobre tipo, intención, estrato, ubicación, características y precio.

### Gestión de búsquedas
- Una búsqueda está compuesta por filtros que permiten encontrar inmuebles adecuados.
- Puede filtrar por ubicación geográfica (ciudad, localidad o barrio).

### Matching o coincidencias
- El sistema compara inmueble contra búsquedas y búsqueda contra inmuebles.
- Usa condiciones lógicas para seleccionar aquellas coincidencias que cumplen los criterios.
- Los resultados se conservan como registros en la tabla Resultado.

---

## 8. Notas de implementación relevantes

- El proyecto usa SQLAlchemy ORM y no SQL puro.
- Las tablas se crean automáticamente al iniciar la aplicación mediante create_database().
- Los schemas de Pydantic protegen la API frente a datos mal formados.
- El sistema está pensado para ser extendido con notificaciones más adelante.
- La carpeta de scripts se usa para poblar la base de datos con datos de prueba.

---

## 9. Resumen rápido del propósito de cada archivo

- [app/main.py](app/main.py): punto de entrada de la aplicación.
- [app/core/config.py](app/core/config.py): configuración del entorno.
- [app/core/enums.py](app/core/enums.py): enumeraciones del dominio inmobiliario.
- [app/core/security.py](app/core/security.py): autenticación y seguridad.
- [app/database/database.py](app/database/database.py): conexión y sesión SQLAlchemy.
- [app/models/models.py](app/models/models.py): modelos ORM y relaciones de la base de datos.
- [app/schemas/usuario.py](app/schemas/usuario.py): validación de usuarios.
- [app/schemas/inmueble.py](app/schemas/inmueble.py): validación de inmuebles.
- [app/schemas/busqueda.py](app/schemas/busqueda.py): validación de búsquedas.
- [app/schemas/resultado.py](app/schemas/resultado.py): validación de resultados.
- [app/routers/auth.py](app/routers/auth.py): login y token JWT.
- [app/routers/usuarios.py](app/routers/usuarios.py): manejo de usuarios.
- [app/routers/inmuebles.py](app/routers/inmuebles.py): manejo de inmuebles.
- [app/routers/busquedas.py](app/routers/busquedas.py): manejo de búsquedas.
- [app/routers/resultados.py](app/routers/resultados.py): consulta de resultados.
- [app/services/matching_engine.py](app/services/matching_engine.py): lógica de coincidencia.
- [app/services/notification_service.py](app/services/notification_service.py): espacio para notificaciones futuras.
- [app/scripts/populate_users.py](app/scripts/populate_users.py): poblar usuarios de prueba.
- [app/scripts/populate_properties.py](app/scripts/populate_properties.py): poblar inmuebles de prueba.
- [app/scripts/populate_locations.py](app/scripts/populate_locations.py): poblar ciudades, localidades y barrios.
- [app/generators/data_generator.py](app/generators/data_generator.py): generador de datos falsos.
- [app/utils/decode.py](app/utils/decode.py): normalización de texto.
- [app/data/Bogota.py](app/data/Bogota.py): catálogo base de barrios de Bogotá.
- [app/tests/test.py](app/tests/test.py): script de pruebas y carga inicial.
- [requirements.txt](requirements.txt): dependencias del proyecto.

---

## 10. Conclusión

El backend de Raíces está organizado como una API REST modular donde cada carpeta cumple una función específica. La pieza más importante del sistema es el motor de coincidencias, que conecta búsquedas con inmuebles y genera resultados automáticamente. La estructura actual es sencilla, clara y escalable, lo que facilita agregar nuevas funcionalidades como notificaciones, filtros avanzados, favoritos o recomendaciones más inteligentes.
