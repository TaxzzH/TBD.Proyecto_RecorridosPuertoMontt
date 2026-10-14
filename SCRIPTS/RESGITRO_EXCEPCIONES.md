# Registro de Expeciones

Todas las "Excepciones Definidas por Usuario" deben ser registradas aqui

* **EXCEPCIÓN -20001: LICENCIA INVÁLIDA**

   
        e_licencia_invalida EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_licencia_invalida, -20001);


* **EXCEPCIÓN -20002: HORA DE ENTRADA INVÁLIDA**

        RAISE_APPLICATION_ERROR(-20002, 'La hora de entrada debe ser anterior a la hora de salida.');

* **EXCEPCIÓN -20003: HORA DE ENTRADA TRASLAPADA**

        RAISE_APPLICATION_ERROR(-20003, 'El bus ya se encuentra asignado a un recorrido en ese horario (traslape).');

* **EXCEPCIÓN -20004: FICHA MANTENCIÓN INVÁLIDA**

        RAISE_APPLICATION_ERROR(-20004, 'La ficha de mantencion del bus se encuentra vencida o el bus no existe.');