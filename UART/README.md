# Universal Asynchronous Receiver/Transmitter (UART)

El UART (Universal Asynchronous Receiver/Transmitter) es un componente fundamental para la comunicación serial. Este informe discute la implementación de un UART en Verilog para un proyecto más grande. El proyecto implica recibir instrucciones de un UART, pasarlas a una Unidad de Lógica Aritmética (ALU) para su procesamiento y transmitir los resultados de regreso al UART. El módulo de nivel superior para este proyecto se llama "uart_alu_top.v".

El flujo de datos del proyecto se puede resumir de la siguiente manera:

1. Las instrucciones se reciben desde una fuente externa a través del receptor UART (`uart_rx.v`).
2. Estas instrucciones se envían a la ALU (`alu.v`) para su procesamiento a través del módulo de interfaz UART-ALU (`uart_alu_interface.v`).
3. La ALU calcula el resultado y lo envía de vuelta al UART a través de la misma interfaz.
4. El transmisor UART (`uart_tx.v`) transmite los resultados a un dispositivo externo.

Cabe mencionar que el proyecto esta implementado para un UART con un Baud-Rate de 19200, 8 bits de datos, 1 bit de parada y 0 bits de paridad.

Integrantes: Bruno A. Genero, Ignacio Ibañez Sala.

## [Módulo ALU](sources/alu.v)

El módulo alu.v representa la Unidad de Lógica Aritmética (ALU). Es responsable de realizar varias operaciones aritméticas y lógicas basadas en las instrucciones recibidas del UART. La ALU es un componente crucial en el pipeline de procesamiento de datos del proyecto.

Este módulo ALU es parametrizable y realiza varias operaciones aritméticas y lógicas según la operación especificada en i_alu_Op. Las operaciones disponibles y sus códigos de operación se detallan en los comentarios. Los resultados de las operaciones se almacenan en alu_Result y se envían a la salida o_alu_Result. El módulo se instancia con parámetros personalizables N y NSel para ajustar el tamaño de la ALU y el tamaño de la operación ALU según las necesidades del proyecto.

## [Módulo FIFO](sources/fifo.v)

El módulo fifo.v implementa un búfer de tipo Primero en Entrar, Primero en Salir (FIFO). Los FIFO son esenciales para gestionar el flujo de datos en el proyecto. Permite operaciones de escritura y lectura, y rastrea su estado para indicar si está lleno o vacío. Aquí hay una explicación de sus principales características:

1. Operaciones de Escritura y Lectura: El módulo fifo.v permite dos operaciones principales: escritura (i_wr) y lectura (i_rd). Cuando la señal de escritura (i_wr) se activa, los datos de entrada se escriben en el búfer. Cuando la señal de lectura (i_rd) se activa, se elimina el primer elemento del FIFO (el que está en la cabeza), y el siguiente elemento se vuelve accesible.

2. Almacenamiento Interno: Utiliza un array de registros (array_reg) para almacenar los datos escritos. Los registros se organizan como una cola circular con dos punteros: el "puntero de escritura" apunta a la cabeza de la cola, y el "puntero de lectura" apunta a la cola de la cola. Estos punteros avanzan una posición con cada operación de escritura o lectura.

3. Señales de Estado: El módulo también incluye señales de estado o_full (lleno) y o_empty (vacío) para indicar el estado del búfer FIFO. Cuando o_full está activo, el FIFO no puede recibir más datos, y cuando o_empty está activo, no se pueden realizar más operaciones de lectura.

4. Mecanismo para Detectar Estado Lleno o Vacío: Para determinar si el FIFO está lleno o vacío, el módulo utiliza dos registros de tipo D para llevar un seguimiento de los estados o_full y o_empty. Estos registros se inicializan durante la inicialización del sistema y se modifican en cada ciclo de reloj, según los valores de las señales i_wr e i_rd.

5. Lógica de Control: La lógica de control se encarga de gestionar los punteros de escritura y lectura, así como de actualizar las señales de estado o_full y o_empty. Se utilizan registros para mantener los valores actuales y próximos de los punteros y señales de estado. La lógica de control se encarga de avanzar los punteros y gestionar el estado de lleno o vacío en función de las operaciones de escritura y lectura.

6. Tamaño Parametrizable: El tamaño del búfer FIFO es parametrizable, lo que permite adaptarlo a las necesidades del sistema. Los parámetros B y W permiten especificar el número de bits en una palabra y el número de bits de dirección, respectivamente.

## [Módulo Mod-M Counter](sources/mod_m_counter.v)

El módulo mod_m_counter es un contador parametrizado que cuenta desde 0 hasta M-1, donde M es un parámetro especificado. Aquí está una descripción de sus características:

1. Parámetros Parametrizados: El módulo utiliza dos parámetros: M, que especifica el límite superior para el contador (m), y N, que se calcula como log2(M) y especifica el número de bits necesarios para representar todos los valores posibles.

2. Registros y Lógica de Contador: Utiliza un registro (r_reg) para mantener el valor actual del contador. La lógica de control asegura que el contador se reinicie cuando alcanza el valor M-1 y avance en cada ciclo de reloj.

3. Lógica de Salida: Las salidas del módulo incluyen o_ticks, que representa el valor actual del contador, y o_max_tick, que indica si el contador ha alcanzado su valor máximo (M-1).

4. Función log2: Se incluye una función log2 que calcula el logaritmo en base 2 de un número entero. Esto se utiliza para calcular el valor de N a partir de M.

El módulo mod_m_counter es útil para implementar contadores modulares con límites personalizables en sistemas digitales. El contador cuenta de 0 a M-1 y luego se reinicia.

## [Módulo UART RX](sources/uart_rx.v)

El módulo `uart_rx.v` es una parte fundamental del sistema de comunicación UART. En un UART, hay tanto un transmisor como un receptor. El transmisor funciona como un registro de desplazamiento especial que carga datos en paralelo y los envía bit a bit a una velocidad específica. El receptor, por otro lado, recibe los datos bit a bit y los reensambla. La línea serial se encuentra en estado alto (1) cuando no está transmitiendo datos (inactiva).

La transmisión de datos comienza con un bit de inicio (start bit) que siempre es 0, seguido de los bits de datos y, en algunos casos, un bit de paridad opcional. La transmisión concluye con bits de parada (stop bits) que siempre son 1. La cantidad de bits de datos puede ser 6, 7 u 8, y el bit de paridad opcional se utiliza para la detección de errores en la comunicación.

Es importante destacar que no se transmite información de reloj a través de la línea serial. Por lo tanto, antes de que la transmisión de datos comience, tanto el transmisor como el receptor deben ponerse de acuerdo en una serie de parámetros, que incluyen la velocidad de baudios (número de bits por segundo), el número de bits de datos y bits de parada, así como el uso del bit de paridad. Las velocidades de baudios comúnmente utilizadas son 2400, 4800, 9600 y 19,200 baudios.

Para el diseño del sistema de recepción UART (`uart_rx.v`), se utiliza un esquema de sobremuestreo (oversampling) para estimar los puntos medios de los bits transmitidos. En este esquema, cada bit serial se muestrea 16 veces, lo que significa que se toma una muestra de la señal 16 veces durante la duración de un bit. El procedimiento de sobremuestreo funciona de la siguiente manera:

1. Se espera a que la señal entrante alcance 0, que indica el comienzo del bit de inicio. En este punto, se inicia un contador de ticks de muestreo.

2. Cuando el contador alcanza el valor 7, la señal entrante ha llegado al punto medio del bit de inicio. En este momento, se reinicia el contador.

3. Cuando el contador alcanza 15, la señal entrante ha avanzado un bit y llega al punto medio del primer bit de datos. En este punto, se captura el valor del bit de datos, se desplaza a un registro y se reinicia el contador. Este proceso se repite N-1 veces para recuperar los bits de datos restantes.

4. Si se utiliza un bit de paridad opcional, se repite el paso 3 una vez más para obtener el bit de paridad.

5. Se repite el paso 3 M veces más para obtener los bits de parada.

Este esquema de sobremuestreo desempeña la función de una señal de reloj. En lugar de utilizar el flanco de subida de una señal de reloj para indicar cuándo la señal de entrada es válida, se utiliza un sistema de muestreo múltiple para estimar el punto medio de cada bit. Aunque el receptor no tiene información sobre el momento exacto en que comienza el bit de inicio, la estimación puede desviarse como máximo en 1/16 de la duración del bit. Las recuperaciones de bits de datos subsiguientes también tienen una desviación de como máximo 1/16 desde el punto medio. Esto permite que la velocidad de baudios sea solo una pequeña fracción de la velocidad del reloj del sistema, por lo que este esquema no es adecuado para tasas de datos muy altas.

A continuación se explica el funcionamiento de este módulo.

**Parámetros:**

- `DBIT`: Número de bits de datos. Esto se configura para indicar cuántos bits de datos se esperan recibir.
- `SB_TICK`: Número de ticks de muestreo para los bits de parada. En un UART, generalmente hay uno o más bits de parada que siguen a los bits de datos.

**Estado y Registros:**

- El módulo `uart_rx` opera en diferentes estados, que incluyen "idle" (espera), "start" (procesamiento del bit de inicio), "data" (procesamiento de los bits de datos) y "stop" (procesamiento de los bits de parada).
- Utiliza varios registros para llevar un seguimiento de su estado interno, como el estado actual, el número de ticks de muestreo, el número de bits de datos recibidos y los bits de datos reensamblados.

Operación del Módulo:

- El módulo `uart_rx` opera en función de la detección de ticks de muestreo que se generan a una tasa específica, generalmente 16 veces la velocidad de baudios.
- Comienza en el estado "idle", donde espera a que la señal entrante sea 0, lo que indica el comienzo del bit de inicio.
- Cuando se detecta el bit de inicio, cambia al estado "start" y comienza a contar los ticks de muestreo para estimar el punto medio del bit de inicio.
- Cuando se alcanza el punto medio del bit de inicio, se cambia al estado "data" y comienza a procesar los bits de datos.
- En el estado "data", se continúa contando los ticks de muestreo y se recopilan los bits de datos a medida que se detectan. Esto se repite hasta que se han recopilado todos los bits de datos configurados (según el parámetro `DBIT`).
- Después de recibir todos los bits de datos, se pasa al estado "stop" y se comienza a contar los bits de parada (según el parámetro `SB_TICK`).
- Una vez que se han recibido todos los bits de parada, el módulo vuelve al estado "idle" y establece la señal `o_rx_done_tick` en 1 para indicar que se ha completado la recepción de datos.

Salida de Datos:

- La salida de datos procesados se proporciona a través de la señal `o_data`, que contiene los bits de datos que se han reensamblado durante el proceso de recepción.

## [Módulo UART TX](sources/uart_tx.v)

El módulo `uart_tx` es una parte del subsistema de transmisión de un UART. Similar al subsistema de recepción, el subsistema de transmisión consta de tres componentes principales: el transmisor UART, el generador de velocidad de baudios y el circuito de interfaz.

1. **Transmisor UART:** El transmisor UART es responsable de enviar los datos por la línea serial. Utiliza un registro de desplazamiento para enviar los bits de datos a una velocidad específica. La velocidad de transmisión puede controlarse mediante habilitaciones de ciclo de reloj generadas por el generador de velocidad de baudios. A diferencia del subsistema de recepción que utiliza sobremuestreo, el transmisor no necesita ese mecanismo. En su lugar, se controla mediante ciclos de reloj habilitados a una frecuencia que es 16 veces más lenta que la del receptor UART.

2. **Generador de Velocidad de Baudios:** El generador de velocidad de baudios es responsable de generar las señales de habilitación de ciclo de reloj para controlar la velocidad de transmisión. El transmisor comparte este generador con el receptor UART y utiliza un contador interno para llevar un registro del número de habilitaciones de ciclo de reloj.

3. **Circuito de Interfaz:** El circuito de interfaz facilita la comunicación entre el sistema principal y el transmisor UART. Al igual que en el subsistema de recepción, se utilizan señales de control para indicar cuándo se deben enviar los datos. En el subsistema de transmisión, el sistema principal establece la señal "FF" o escribe en un búfer FIFO, y el transmisor UART se encarga de leer el búfer FIFO y borrar la señal "FF."

La operación del transmisor UART se basa en un diagrama de estado finito (ASMD) similar al del receptor UART. Cuando se activa la señal `tx-start`, el transmisor carga la palabra de datos y avanza gradualmente a través de los estados de inicio, datos y parada para enviar los bits correspondientes. Una vez que se han enviado todos los bits, el transmisor señala la finalización mediante la activación de la señal `tx-done-tick` durante un ciclo de reloj. Para asegurar la integridad de la señal transmitida, se utiliza un búfer de 1 bit llamado `tx-reg` para filtrar posibles glitches o errores en la transmisión.

En resumen, el módulo `uart_tx` es responsable de transmitir datos a través de una línea serial en un sistema UART. Utiliza un registro de desplazamiento y un generador de velocidad de baudios para controlar la transmisión de datos a una velocidad específica y se comunica con el sistema principal mediante señales de control.

## [Módulo UART Top](sources/uart_top.v)

El módulo `uart_top` es aquel que modela al UART. Su función principal es proporcionar una interfaz unificada para gestionar la comunicación serial UART, lo que incluye la transmisión y recepción de datos.

Se encarga de coordinar las operaciones de transmisión y recepción en un sistema UART. Para lograr esto, se comunica con varios módulos internos, que incluyen un generador de velocidad de baudios, unidades de recepción y transmisión UART, así como búferes FIFO para la gestión de datos.

**Configuración Predeterminada:**

El módulo `uart_top` se configura con los siguientes parámetros predeterminados:

- **Baud Rate:** La velocidad de baudios predeterminada es de 19200.
- **Bits de Datos:** El número de bits de datos predeterminado es 8.
- **Bits de Parada:** El número de bits de parada predeterminado es 1.
- **FIFO:** La profundidad del búfer FIFO es de 2 palabras.

**Entradas:**

- `i_clk` (Clock): Señal de reloj utilizada para sincronizar las operaciones en el módulo UART.
- `i_reset` (Reset): Señal de reinicio que pone en estado de reinicio el módulo UART y establece varios estados y señales en sus valores iniciales.
- `i_rd_uart` (FIFO Receiver Read): Señal de lectura de FIFO para el receptor UART.
- `i_wr_uart` (FIFO Transmitter Write): Señal de escritura en el FIFO para el transmisor UART.
- `i_rx` (UART Receiver Input): Señal de entrada del receptor UART que contiene los datos recibidos.
- `i_w_data` (Data to be Transmitted): Datos que deben ser transmitidos por el UART.

**Salidas:**

- `o_tx_full` (Transmitter FIFO Full): Señal que indica si el FIFO del transmisor está lleno.
- `o_rx_empty` (Receiver FIFO Empty): Señal que indica si el FIFO del receptor está vacío.
- `o_tx` (Transmitted Data): Datos transmitidos por el UART.
- `o_tx_done_tick` (Transmission Done Signal): Señal que indica que la transmisión se ha completado.
- `o_r_data` (Received Data): Datos recibidos por el UART.

## [Módulo UART-ALU Interface](sources/uart_alu_interface.v)

El módulo llamado `uart_alu_interface` sirve como una interfaz entre el UART y la ALU. Su función es recibir datos del UART, procesarlos en la ALU y luego transmitir los resultados de nuevo a través del UART. El módulo funciona mediante una máquina de estados que coordina las diversas etapas del proceso.

A continuación, se explican las partes clave del código:

**Parámetros:**

- `DATA_WIDTH`: Es el ancho de los datos, que se define como 8 bits.
- `SAVE_COUNT`: Indica el número de palabras de datos que se deben guardar.
- `OP_SZ`: Tamaño de los operandos en bits, que se establece igual que `DATA_WIDTH`.
- `OPCODE_SZ`: Tamaño del campo de opcode, que se establece en 6 bits.

**Entradas:**

- `i_clk`: La señal de reloj utilizada para sincronizar las operaciones.
- `i_reset`: Una señal de reinicio que pone en estado de reinicio el módulo y establece varios estados y señales en sus valores iniciales.
- `i_rx_empty`: Indica si el FIFO del receptor UART está vacío.
- `i_tx_full`: Indica si el FIFO del transmisor UART está lleno.
- `i_tx_done_tick`: Señal que indica la finalización de la transmisión.
- `i_r_data`: Los datos recibidos por el UART.
- `i_result_data`: Datos resultantes de la ALU.

**Salidas:**

- `o_w_data`: Datos que se transmiten a través del UART.
- `o_wr_uart`: Señal que controla la escritura en el FIFO del receptor UART.
- `o_rd_uart`: Señal que controla la lectura del FIFO del transmisor UART.
- `o_op_a`: Operandos para la ALU.
- `o_op_b`: Operandos para la ALU.
- `o_op_code`: Código de operación para la ALU.

**Máquina de Estados:**

- El módulo implementa una máquina de estados de 8 estados (`IDLE`, `SAVE_OP1`, `SAVE_OP2`, `COMPUTE_ALU`, `SEND_RESULT`, `HOLD`, y `DEFAULT`) que controla el flujo de datos y el procesamiento.

**Operación del Módulo:**

- En el estado `IDLE`, el módulo espera a que los datos del UART estén disponibles.
- Los estados `SAVE_OP1` y `SAVE_OP2` se utilizan para guardar los datos recibidos en las variables `op1` y `op2`.
- En el estado `COMPUTE_ALU`, se obtiene el código de operación del UART y se pasa a la ALU junto con los operandos `op1` y `op2` para realizar el cálculo.
- El estado `SEND_RESULT` se encarga de transmitir los resultados de vuelta a través del UART.
- El estado `HOLD` se utiliza cuando el módulo debe esperar antes de continuar con el siguiente estado.
- Cuando se completa una transmisión, el módulo regresa al estado `IDLE`.

Este módulo permite la comunicación bidireccional entre el UART y la ALU y coordina la transmisión y recepción de datos a través del UART junto con las operaciones de la ALU. La máquina de estados garantiza que el proceso se ejecute de manera eficiente y controlada.

## [Módulo UART-ALU Top](sources/uart_alu_top.v)

El módulo `uart_top` es el nivel más alto del proyecto que coordina la comunicación UART, incluyendo la recepción y transmisión de datos. Aquí se explican las partes clave del código:

**Parámetros:**

- `DBIT`: Este parámetro define la cantidad de bits de datos en cada trama, establecido en 8 bits.
- `SB_TICK`: Indica la cantidad de "ticks" necesarios para los bits de parada, lo que permite adaptarse a diferentes configuraciones de bits de parada (1, 1.5 o 2 bits de parada). En este caso, se establece en 16 para configuración de 1 bit de parada.
- `DVSR`: Define el divisor de la velocidad de baudios (baud rate) que se utiliza para la comunicación UART.
- `FIFO_W`: Número de bits necesarios para direccionar las palabras en la memoria FIFO. Esto permite configurar el tamaño de la FIFO.

**Entradas:**

- `i_clk`: La señal de reloj que sincroniza todas las operaciones.
- `i_reset`: Una señal de reinicio utilizada para restablecer el módulo y sus registros a un estado inicial.
- `i_rd_uart`: Señal que indica la solicitud de lectura de la FIFO del receptor UART.
- `i_wr_uart`: Señal que indica la solicitud de escritura en la FIFO del transmisor UART.
- `i_rx`: La señal de entrada del receptor UART.
- `i_w_data`: Los datos de entrada provenientes del receptor UART y destinados a ser transmitidos.

**Salidas:**

- `o_tx_full`: Indica si la FIFO del transmisor UART está llena.
- `o_rx_empty`: Indica si la FIFO del receptor UART está vacía.
- `o_tx`: Los datos transmitidos por el UART.
- `o_tx_done_tick`: Señal que indica que la transmisión se ha completado.
- `o_r_data`: Los datos recibidos por el receptor UART.

**Señales Internas:**

- `tick`: Una señal interna utilizada para contar "ticks" para la velocidad de baudios en el módulo de contador.
- `rx_done_tick`: Una señal interna que indica que el receptor UART ha completado una transmisión.
- `tx_done_tick`: Una señal interna que indica que el transmisor UART ha completado una transmisión.
- `tx_empty`: Indica si la FIFO del transmisor UART está vacía.
- `tx_fifo_not_empty`: Una señal interna que indica si la FIFO del transmisor UART no está vacía.
- `tx_fifo_out`: Datos que se envían desde la FIFO del transmisor UART al UART para su transmisión.
- `rx_data_out`: Datos que se envían desde el receptor UART a la FIFO del receptor UART.

**Instantiaciones:**

- Este módulo incluye instantiaciones de otros módulos, como el módulo de contador de velocidad de baudios (`mod_m_counter`), el módulo de recepción UART (`uart_rx`), dos módulos FIFO para la recepción y transmisión (`fifo`), y el módulo de transmisión UART (`uart_tx`). Cada uno de estos módulos realiza una función específica en la comunicación UART.

**Asignaciones:**

- `assign tx_fifo_not_empty = ~tx_empty;` y `assign o_tx_done_tick = tx_done_tick;` se utilizan para definir señales en función de otros valores internos del módulo.

## [Módulo UART-ALU TestBench](tests/uart_alu_tb.v)

TODO

## [Input Script](/input_script.py)

Es un script de Python que se encarga de realizar una comunicación serie con la placa Basys 3 a través de un puerto serial (UART). El usuario ingresa una cadena con un formato específico "OPCODE OP1,OP2", que se interpreta y envía al dispositivo a través del puerto serial, y luego se imprime la respuesta del dispositivo. Aquí está la explicación paso a paso del script:

1. Se importa la biblioteca `serial` para la comunicación serial y el módulo `re` para realizar coincidencias con expresiones regulares.

2. Se configura la comunicación serial en el puerto `/dev/ttyUSB1` con una velocidad de baudios de 19200, 8 bits de datos, paridad desactivada, un bit de parada y un tiempo de espera de 1 segundo.

3. Se define un diccionario `opcode_map` que asigna códigos hexadecimales a cadenas de operaciones como "ADD", "SUB", "AND", etc. Esto permite al usuario especificar operaciones en lugar de valores hexadecimales.

4. La función `send_data(opcode, op1, op2)` se define para procesar y enviar los datos ingresados por el usuario. Realiza las siguientes acciones:
   - Verifica si el `opcode` ingresado es válido según el `opcode_map`.
   - Convierte `op1` y `op2` en bytes con el bit más significativo (MSB) establecido en 1 para números enteros con signo.
   - Imprime los datos que se enviarán al dispositivo.
   - Si hay un puerto serial disponible, envía los datos al dispositivo en el orden: op1, op2, opcode, y luego espera una respuesta.
   - Imprime la respuesta en formato binario.

5. El bucle principal `while True` permite al usuario ingresar comandos repetidamente hasta que escriba "exit". El usuario puede ingresar comandos con el formato "OPCODE OP1,OP2".

6. Se utiliza una expresión regular (`re.match`) para validar el formato de entrada del usuario y extraer el `opcode`, `op1` y `op2`.

7. Si el formato de entrada es válido, los valores se convierten a enteros y se llama a la función `send_data` para enviar los datos al dispositivo a través del puerto serial. Si el formato de entrada no es válido, se muestra un mensaje de error.

8. El bucle se puede interrumpir con la combinación de teclas "Ctrl+C", lo que muestra un mensaje de salida.

9. Finalmente, después de salir del bucle, el script verifica si hay un puerto serial abierto y, de ser así, lo cierra.

Este script permite a los usuarios interactuar con un dispositivo que comprende ciertas operaciones (definidas en `opcode_map`) y enviar datos a través de un puerto serial para realizar cálculos o acciones específicas en el dispositivo.

## Análisis con Osciloscopio

TODO
