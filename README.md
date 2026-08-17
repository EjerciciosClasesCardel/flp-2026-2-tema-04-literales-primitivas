# Tema 4 — Interpretación y compilación: literales y primitivas

Fundamentos de Interpretación y Compilación de Lenguajes de Programación
Escuela de Ingeniería de Sistemas y Computación, Universidad del Valle
Carlos Andrés Delgado Saavedra

Ejercicio de autoseguimiento del tema 4. No se califica y no hay que
entregarlo: las pruebas le dicen solas si va bien.

Este es el primer lenguaje completo del curso, del texto al valor. El front-end
lo genera SLLGEN a partir de dos especificaciones que usted escribe: de ahí
salen el escáner y el analizador sintáctico. El back-end es `value-of`, la
función que recorre el árbol y lo evalúa. Lo que viene después —procedimientos,
recursión, asignación, tipos— se construye agregándole producciones a la
gramática y ramas a `value-of`.

## Los programas ahora se escriben como texto

Hasta el tema 3 los programas venían como listas de Scheme, `(let x = 5 in
(- x 3))`, y una función `parse` hecha a mano las traducía a sintaxis
abstracta. Ese `parse` era un andamio: permitía trabajar el árbol sin depender
todavía de un analizador. Desde este tema la sintaxis concreta es texto, la
misma del libro, y el analizador sale de la gramática:

```racket
(scan&parse "let x = 5 in -(x, 3)")
```

El `parse` sobre listas no está en este repositorio y no vuelve a aparecer en
el curso.

## De qué se trata

El lenguaje es LET, recortado a seis producciones (EOPL, sección 3.1):

```
Expression ::= Number                        const-exp  (num)
           ::= Identifier                    var-exp    (var)
           ::= -(Exp , Exp)                  diff-exp   (exp1 exp2)
           ::= zero?(Exp)                    zero?-exp  (exp1)
           ::= if Exp then Exp else Exp      if-exp     (exp1 exp2 exp3)
           ::= let Id = Exp in Exp           let-exp    (var exp1 body)
```

Y el camino que recorre un programa es este:

```
texto  ->  escáner  ->  tokens  ->  parser  ->  árbol  ->  value-of  ->  valor
```

El escáner parte el texto en tokens y descarta espacios y comentarios; el
parser arma el árbol de sintaxis abstracta; `value-of` lo evalúa. SLLGEN genera
el escáner y el parser a partir de la especificación léxica y la especificación
gramatical (EOPL, apéndice B), y de la gramática saca además el
`define-datatype` del árbol.

El valor expresado es lo que devuelve la evaluación de una expresión (EOPL,
sección 3.2). Aquí hay dos, `ExpVal = Int + Bool`, representados con los
números y los booleanos de Scheme.

## Cómo está organizado

```
src/ambiente.rkt                el TAD de ambientes, ya resuelto
src/gramatica.rkt               los puntos 1 y 2
src/interprete.rkt              los puntos 3, 4, 5 y 6
pruebas/interprete-pruebas.rkt  las pruebas, que no se modifican
verificar/                      las reglas del curso, que tampoco se modifican
```

`src/ambiente.rkt` viene resuelto y no hay que tocarlo. Es el ambiente del
tema 2 con la representación de listas, más `init-env`, el ambiente inicial de
la sección 3.2 donde `i` vale 1, `v` vale 5 y `x` vale 10. Las pruebas evalúan
todo contra ese ambiente, así que puede usar esas tres variables en sus
ejemplos sin ligarlas.

En `src/gramatica.rkt` también viene escrita la parte que llama a SLLGEN:
`sllgen:make-define-datatypes`, que genera el datatype del árbol, y
`sllgen:make-string-parser`, que genera el analizador. Lo que falta ahí son las
dos especificaciones que esas llamadas reciben.

## Cómo empezar

1. **Haga fork.** Botón *Fork* arriba a la derecha. El fork queda en su cuenta
   y usted trabaja ahí.

2. **Active las Actions.** Al hacer fork, GitHub deja los workflows apagados.
   Entre a la pestaña *Actions* de **su** fork y pulse el botón verde
   *I understand my workflows, go ahead and enable them*. Sin esto puede hacer
   todos los push que quiera y nunca se va a correr nada.

3. **Clone su fork:**

   ```bash
   git clone https://github.com/SU-USUARIO/flp-2026-2-tema-04-literales-primitivas.git
   cd flp-2026-2-tema-04-literales-primitivas
   ```

4. **Resuelva** los puntos 1 y 2 en `src/gramatica.rkt` y los puntos 3, 4, 5 y
   6 en `src/interprete.rkt`.

5. **Haga push.** Cada push dispara las pruebas.

## Cómo se ejecutan las pruebas

```bash
raco test pruebas/
racket verificar/reglas.rkt
```

Las pruebas miran lo que devuelven sus funciones; el verificador mira cómo
están escritas y avisa qué falta por escribir. También puede trabajar desde
DrRacket, abriendo `pruebas/interprete-pruebas.rkt` y pulsando *Ejecutar*. Si
necesita instalar Racket, use la distribución completa de
[racket-lang.org](https://racket-lang.org): la mínima no trae `#lang eopl`.

## El punto de partida

Al clonar hay 53 pruebas: 3 en verde y 50 en rojo. Las verdes comprueban que
los módulos cargan, que el ambiente inicial está donde debe y que el datatype
del árbol tiene sus seis variantes; que pasen significa que Racket y `eopl`
quedaron bien instalados.

La gramática que trae el repositorio reconoce una sintaxis provisional, con una
palabra clave inventada al frente de cada producción. Está ahí para que el
proyecto compile mientras usted escribe la suya, y ningún programa del lenguaje
pasa por ella. Los nombres de las variantes y sus campos sí se quedan como
están: `value-of` analiza el árbol con esos seis nombres.

## Los seis puntos

### 1. La especificación léxica

En `src/gramatica.rkt`. Cada regla es `(nombre (patrón) acción)`: el nombre de
la categoría, la expresión regular que la reconoce y qué hacer con el texto
reconocido, sea descartarlo con `skip` o convertirlo con `symbol` o `number`.

Las reglas de los espacios y los comentarios ya están. Faltan las dos
categorías con contenido: `identificador`, una letra seguida de cero o más
letras, dígitos, `?` o `$`; y `numero`, un entero con signo menos opcional
adelante. Las palabras del lenguaje y los signos no se declaran aquí, SLLGEN
los saca de la gramática.

### 2. La especificación gramatical

Las seis producciones de la sección 3.1, cada una con su sintaxis concreta y el
nombre de la variante que construye: `(expresion (sintaxis concreta) variante)`.
Las cadenas literales son los signos y las palabras que el programador escribe;
las categorías léxicas y los no terminales son los campos de la variante.

Cuando quede, `(scan&parse "let x = 5 in -(x, 3)")` devuelve el árbol de la
figura 3.4 y `(datatypes-generados)` muestra el `define-datatype` que sale de
su gramática.

### 3. `expval->num` y `expval->bool`

En `src/interprete.rkt`. Los extractores del valor expresado (EOPL, sección
3.2). Cada uno devuelve el valor cuando es del tipo que se pidió y lanza un
error con `eopl:error` cuando no lo es. Como los valores expresados son números
y booleanos de Scheme, el cuerpo es corto: la comprobación es lo único que hay.

Por ahí pasa después todo lo que necesita un tipo concreto. `diff-exp` pide dos
números, `if-exp` pide un booleano, y si el programa entrega otra cosa el error
sale de aquí, no de una operación de Scheme fallando tres marcos más abajo.

### 4. `value-of` para `const-exp` y `var-exp`

Las dos hojas del árbol. El literal se evalúa a sí mismo y la variable se
resuelve contra el ambiente con `apply-env`.

### 5. `value-of` para `diff-exp` y `zero?-exp`

Las dos primitivas. `diff-exp` evalúa las dos subexpresiones, saca los números
con `expval->num` y resta. `zero?-exp` evalúa la suya y devuelve un booleano:
esta es la única producción del lenguaje que fabrica booleanos, y por eso
existe.

### 6. `value-of` para `if-exp` y `let-exp`

`let-exp` evalúa la expresión ligada, extiende el ambiente y evalúa el cuerpo
en el ambiente extendido. `if-exp` tiene su propia regla, la de aquí abajo.

## La regla del `if-exp`

Es la convención del curso y aplica a todos los intérpretes de aquí en
adelante. Al evaluar `if-exp`:

1. evalúe la expresión de prueba con `value-of`;
2. compruebe con `boolean?` que el resultado es un booleano, sea llamando a
   `boolean?` o pasando el valor por `expval->bool`, que es esa misma
   comprobación;
3. si no lo es, lance `eopl:error` con un mensaje que diga qué llegó;
4. solo entonces ramifique.

Lo que no se hace es entregarle al `if` de Scheme el resultado de `value-of`
sin mirar el tipo. Scheme trata como verdadero todo lo que no sea `#f`, así que
`if 5 then 1 else 2` devolvería 1 tan tranquilo y el lenguaje que usted
implementó habría aceptado un programa que no tiene sentido. Hay dos pruebas
que exigen justamente ese error.

## Tres cosas que las pruebas revisan y suelen olvidarse

- **El lenguaje acepta enteros negativos.** `-7` es un literal y `-(x, 3)` es
  una resta. Con las dos reglas de `numero` y la sintaxis concreta de
  `diff-exp` bien escritas, el escáner distingue los dos casos solo.
- **La rama que no se toma no se evalúa.** Evalúe la prueba, decida, y solo
  entonces llame a `value-of` sobre la rama que corresponde. Si evalúa las dos
  y después escoge, `if zero?(0) then 5 else -(1, zero?(0))` revienta en vez
  de dar 5.
- **El `let` no altera el ambiente de afuera.** `extend-env` devuelve un
  ambiente nuevo; el que recibió sigue igual. Después de
  `-(let x = 5 in x, x)` con el ambiente inicial, la `x` de la derecha vale 10
  y el resultado es -5.
