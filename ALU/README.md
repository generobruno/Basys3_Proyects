# Arithmetic-Logic Unit (ALU)

En este informe, se describe la implementación de dos módulos en Verilog: una Unidad Aritmético-Lógica (ALU) parametrizable y su control de entradas. La ALU es una unidad fundamental en la arquitectura de una CPU que realiza operaciones aritméticas y lógicas en datos. El control de entradas permite configurar los operandos y la operación que la ALU debe ejecutar. A continuación, se detalla cada módulo y su funcionalidad.

Integrantes: Bruno A. Genero, Ignacio Ibañez Sala.

## [Módulo ALU](sources/alu.v)

El módulo ALU es una unidad parametrizable que realiza diversas operaciones aritméticas y lógicas en función de la operación seleccionada. Las operaciones disponibles y sus códigos de operación correspondientes son los siguientes:

1. ADD (Suma): Código de operación 100000
2. SUB (Resta): Código de operación 100010
3. AND (AND lógico): Código de operación 100100
4. OR (OR lógico): Código de operación 100101
5. XOR (XOR lógico): Código de operación 100110
6. SRA (Desplazamiento aritmético a la derecha): Código de operación 000011
7. SRL (Desplazamiento lógico a la derecha): Código de operación 000010
8. NOR (NOR lógico): Código de operación 100111

![image](https://github.com/generobruno/Basys3_Proyects/assets/36767810/a6c9573a-4ac6-4e56-b4ee-8273a88fbaf2)

El módulo ALU tiene los siguientes parámetros:

- `N`: Tamaño de los operandos (por defecto, 4 bits).
- `NSel`: Tamaño del código de operación (por defecto, 6 bits).

### Entradas

- `i_alu_A`: Operando A de la ALU (tamaño N bits).
- `i_alu_B`: Operando B de la ALU (tamaño N bits).
- `i_alu_Op`: Código de operación de la ALU (tamaño NSel bits).

### Salida

- `o_alu_Result`: Resultado de la operación de la ALU (tamaño N bits).

### Funcionamiento

El módulo ALU realiza la operación especificada por `i_alu_Op` en los operandos `i_alu_A` e `i_alu_B`. El resultado se almacena en `o_alu_Result`. A continuación, se describe el comportamiento de las operaciones más comunes:

- **ADD (Suma)**: Realiza una suma aritmética y detecta desbordamiento.
- **SUB (Resta)**: Realiza una resta aritmética y detecta desbordamiento.
- **AND (AND lógico)**: Realiza una operación AND lógica entre los operandos.
- **OR (OR lógico)**: Realiza una operación OR lógica entre los operandos.
- **XOR (XOR lógico)**: Realiza una operación XOR lógica entre los operandos.
- **SRA (Desplazamiento aritmético a la derecha)**: Realiza un desplazamiento aritmético de `i_alu_A` a la derecha según el valor en `i_alu_B`.
- **SRL (Desplazamiento lógico a la derecha)**: Realiza un desplazamiento lógico de `i_alu_A` a la derecha según el valor en `i_alu_B`.
- **NOR (NOR lógico)**: Realiza una operación NOR lógica entre los operandos.

## [Módulo ALU Input Control](sources/alu_input_ctrl.v)

El módulo `alu_input_ctrl` se encarga de gestionar las entradas de la ALU utilizando interruptores (switches) y botones para configurar los operandos y la operación que se realizará. Este módulo se utiliza para establecer los valores de `i_alu_A`, `i_alu_B`, e `i_alu_Op`.

![image](https://github.com/generobruno/Basys3_Proyects/assets/36767810/bfce2770-0091-4e22-81fb-2e65298d3445)

El módulo `alu_input_ctrl` tiene los siguientes parámetros:

- `N_SW`: Tamaño de los switches (por defecto, 14 bits).
- `N_OP`: Tamaño del código de operación (por defecto, 6 bits).
- `N_OPERANDS`: Tamaño de los operandos (por defecto, 4 bits).

### Entradas

- `i_clock`: Señal de reloj.
- `i_reset`: Botón de reset.
- `i_sw`: Estado de los switches (N_SW bits).
- `i_button_A`: Botón para actualizar el operando A.
- `i_button_B`: Botón para actualizar el operando B.
- `i_button_Op`: Botón para actualizar el código de operación.

### Salidas

- `o_alu_A`: Operandos A configurados para la ALU (N_OPERANDS bits).
- `o_alu_B`: Operandos B configurados para la ALU (N_OPERANDS bits).
- `o_alu_Op`: Código de operación configurado para la ALU (N_OP bits).

### Funcionamiento

El módulo `alu_input_ctrl` almacena los valores de los switches en `stored_A`, `stored_B`, y `stored_Op` cuando se presionan los botones correspondientes. Estos valores se actualizan cuando no se encuentra en estado de reset. Luego, se utilizan como entradas para la ALU.

## [Módulo ALU Top](sources/alu_top.v)

El módulo `alu_top` es el módulo principal que instancia tanto la ALU como su control de entradas. Este módulo conecta todo el sistema y permite configurar la ALU mediante interruptores y botones.

![image](https://github.com/generobruno/Basys3_Proyects/assets/36767810/c122ee81-f852-4532-8d5b-983ee751fded)

El módulo `alu_top` tiene los siguientes parámetros:

- `N`: Tamaño de los operandos (por defecto, 5 bits).
- `NSel`: Tamaño del código de operación (por defecto, 6 bits).
- `N_SW`: Tamaño de los switches (calculado en función de N y NSel).

### Entradas

- `i_clock`: Señal de reloj.
- `i_reset`: Botón de reset.
- `i_switches`: Estado de los switches (N_SW bits).
- `i_button_A`: Botón para actualizar el operando A.
- `i_button_B`: Botón para actualizar el operando B.
- `i_button_Op`: Botón para actualizar el código de operación.

### Salida

- `o_LED_Result`: Resultado de la ALU visualizado en LEDs (N bits).

### Funcionamiento

El módulo `alu_top` instancia tanto el módulo `alu_input_ctrl` como el módulo `alu`, conectando las señales de entrada y salida correspondientes. De esta manera, el sistema permite configurar la ALU a través de interruptores y botones.

## [Test Bench](tests/alu_tb.v)

Se ha desarrollado un test bench para verificar el funcionamiento de los módulos `alu` y `alu_input_ctrl`. El objetivo de este test bench es validar que la ALU realiza las operaciones correctamente y que el control de entradas configura adecuadamente los operandos y el código de operación. A continuación, se describe el test bench y su funcionamiento.

### Parámetros

El test bench utiliza los siguientes parámetros:

- `N`: Tamaño de los operandos (5 bits).
- `NSel`: Tamaño del código de operación (6 bits).
- `N_SW`: Tamaño de los interruptores (calculado como `(N * 2) + NSel`).

### Generación de Clock

Se genera una señal de reloj `clk` con un período de 25 unidades de tiempo.

### Entradas y Salidas

- `i_sw`: Estado de los interruptores.
- `i_button_A`, `i_button_B`, `i_button_Op`: Botones para actualizar los operandos y el código de operación.
- `i_reset`: Botón de reset.
- `o_alu_A`, `o_alu_B`, `o_alu_Op`: Salidas del control de entradas que se conectan a la ALU.
- `o_alu_Result`: Salida de la ALU que se muestra en LEDs.

### Configuración Inicial

- Se inicializan las entradas y botones en estado bajo (0).
- Se activa el botón de reset durante un breve periodo de tiempo y luego se desactiva para asegurarse de que los módulos comienzan en un estado predecible.

### Generación de Casos de Prueba

El test bench ejecuta 10 casos de prueba diferentes para verificar varias operaciones de la ALU. En cada caso de prueba:

1. Se generan valores aleatorios para los operandos `A_VALUE` y `B_VALUE`.
2. Se selecciona una operación (`OP_VALUE`) de acuerdo al número de caso de prueba.
3. Se configuran los interruptores con los valores de `OP_VALUE`, `B_VALUE`, y `A_VALUE`.
4. Se activan y desactivan los botones correspondientes (`i_button_A`, `i_button_B`, `i_button_Op`) para indicar que se han ingresado los valores.
5. Se espera un breve periodo de tiempo para permitir que la ALU realice la operación.
6. Se calcula el resultado esperado (`expected_res`) de acuerdo a la operación seleccionada.
7. Se verifica si el resultado de la ALU (`o_alu_Result`) coincide con el resultado esperado.

Si los resultados coinciden, se muestra un mensaje indicando que el caso de prueba pasó correctamente. En caso contrario, se muestra un mensaje de error.

### Monitorización

Se utiliza el monitor para mostrar en la consola los valores de los operandos, el código de operación y el resultado de la ALU en cada ciclo de reloj.

### Conclusión

Este test bench permite verificar el correcto funcionamiento de los módulos `alu` y `alu_input_ctrl` al simular su interacción con interruptores y botones, así como la realización de operaciones por parte de la ALU. La verificación exitosa de los casos de prueba demuestra que los módulos operan de acuerdo a las especificaciones.
