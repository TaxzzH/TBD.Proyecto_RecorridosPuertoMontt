/*
Consulta de todos los horarios de ejecucion de entrada y salida
*/

SELECT 
    -- Identificadores principales
    rrb.ID                               AS id_registro,
    rrb.BUS_PATENTE                      AS patente_bus,
    
    -- Formateo de fechas y horas para presentación en reporte
    TO_CHAR(rrb.HORA_EJECUCION_ENTRADA, 'DD/MM/YYYY HH24:MI') AS fecha_entrada_formateada,
    TO_CHAR(rrb.HORA_EJECUCION_SALIDA,  'DD/MM/YYYY HH24:MI') AS fecha_salida_formateada,
    
    -- Columna calculada: Validación de estado del recorrido
    CASE 
        WHEN rrb.HORA_EJECUCION_SALIDA IS NULL 
            THEN 'PENDIENTE'
        ELSE 
            'RECORRIDO INICIADO'
    END AS estado_recorrido

FROM 
    Registro_Recorrido_Bus rrb

-- Filtro de seguridad para evitar registros huérfanos sin entrada
WHERE 
    rrb.HORA_EJECUCION_ENTRADA IS NOT NULL

-- Ordenamos por la fecha de entrada más reciente (ideal para reportes visuales)
ORDER BY 
    rrb.HORA_EJECUCION_ENTRADA DESC;