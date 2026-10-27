CREATE OR REPLACE PROCEDURE sp_reporte_mensual_recorridos (
   p_mes IN NUMBER DEFAULT 9   -- Mes a consultar (1-12); por defecto Septiembre
) IS

   TYPE t_recorrido_info IS RECORD (
      id_registro       NUMBER,
      fecha_recorrido   DATE,
      rut_conductor     VARCHAR(12),
      nombres_conductor VARCHAR2(100),
      patente_bus       VARCHAR(10),
      nombre_recorrido  VARCHAR2(100)
   );

   v_recorrido t_recorrido_info;

   -- 1er Cursor: Obtiene todos los conductores
   CURSOR c_conductores IS
      SELECT 
         rut,
         nombres,
         apellido_paterno
      FROM DATOS_CONDUCTOR;

   -- 2do Cursor (Complejo): realiza JOINs filtrando por RUT y Mes
   CURSOR c_recorridos(
      p_rut_conductor VARCHAR2, 
      p_mes_recorrido NUMBER
   ) IS
      SELECT 
         rrb.id,
         rrb.fecha_recorrido,
         dc.rut,
         dc.nombres || ' ' || dc.apellido_paterno AS nombres_conductor,
         rrb.bus_patente,
         rec.nombre_recorrido
      FROM REGISTRO_RECORRIDO_BUS rrb
      JOIN DATOS_CONDUCTOR dc ON rrb.datos_conductor_rut = dc.rut
      JOIN RECORRIDOS rec ON rrb.recorridos_id = rec.id
      WHERE dc.rut = p_rut_conductor
         AND EXTRACT(MONTH FROM rrb.fecha_recorrido) = p_mes_recorrido;

   -- Variables y Excepcion personalizada
   v_cont_recorridos NUMBER;
   e_sin_viajes      EXCEPTION;

BEGIN

   DBMS_OUTPUT.PUT_LINE('=================================================='  || chr(10) ||
                        '   REPORTE MENSUAL DE RECORRIDOS POR CONDUCTOR   '   || chr(10) ||
                        '==================================================');

   -- Iterar sobre cada conductor
   FOR r_cond IN c_conductores LOOP
      v_cont_recorridos := 0;
      
      DBMS_OUTPUT.PUT_LINE('--------------------------------------------------'              || chr(10) ||
                           'Conductor: ' || r_cond.nombres || ' ' || r_cond.apellido_paterno ||
                           ' | RUT: ' || r_cond.rut                                          || chr(10) ||
                           '--------------------------------------------------');

      -- Sub-bloque interno para aislamiento de excepciones
      BEGIN
         OPEN c_recorridos(r_cond.rut, p_mes);   -- <-- único cambio dentro del cuerpo
         LOOP
            FETCH c_recorridos INTO 
               v_recorrido.id_registro,
               v_recorrido.fecha_recorrido,
               v_recorrido.rut_conductor,
               v_recorrido.nombres_conductor,
               v_recorrido.patente_bus,
               v_recorrido.nombre_recorrido;
               
            EXIT WHEN c_recorridos%NOTFOUND;

            v_cont_recorridos := v_cont_recorridos + 1;

            DBMS_OUTPUT.PUT_LINE('  > [ID: ' || v_recorrido.id_registro || ']' ||
                                 ' Fecha: ' || TO_CHAR(v_recorrido.fecha_recorrido, 'DD/MM/YYYY') ||
                                 ' | Bus: ' || v_recorrido.patente_bus ||
                                 ' | Ruta: ' || v_recorrido.nombre_recorrido);
         END LOOP;
         CLOSE c_recorridos;

         -- Validar si el conductor tuvo recorridos
         IF v_cont_recorridos = 0 THEN
            RAISE e_sin_viajes;
         ELSE
            DBMS_OUTPUT.PUT_LINE('Total recorridos en el mes: ' || v_cont_recorridos);
         END IF;

      EXCEPTION
         WHEN e_sin_viajes THEN
            DBMS_OUTPUT.PUT_LINE('[ALERTA]: El conductor no registra recorridos en el mes.');
      END;

   END LOOP;

   DBMS_OUTPUT.PUT_LINE('=================================================='  || chr(10) ||
                        '              FIN DEL REPORTE                     '  || chr(10) ||
                        '==================================================');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[ERROR GLOBAL]: Ocurrio un error inesperado - ' || SQLERRM);
END sp_reporte_mensual_recorridos;
/

SET SERVEROUTPUT ON;

EXEC sp_reporte_mensual_recorridos(9);   -- Septiembre
EXEC sp_reporte_mensual_recorridos(8);   -- Agosto