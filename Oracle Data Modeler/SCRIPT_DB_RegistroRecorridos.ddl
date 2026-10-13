-- Generado por Oracle SQL Developer Data Modeler 24.3.1.351.0831
--   en:        2026-09-01 06:37:50 CLT
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE Bus 
    ( 
     Patente                NUMBER  NOT NULL , 
     Marca                  VARCHAR2 (25550 CHAR)  NOT NULL , 
     Modelo                 VARCHAR2 (50)  NOT NULL , 
     Tipo_Motor             VARCHAR2 (30 CHAR)  NOT NULL , 
     Cant_Asientos          NUMBER , 
     Ficha_Mantenimiento_ID NUMBER  NOT NULL , 
     Empresa_ID             NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Bus 
    ADD CONSTRAINT Bus_PK PRIMARY KEY ( Patente ) ;

CREATE TABLE Carril_Terminal 
    ( 
     ID                  NUMBER  NOT NULL , 
     Identificado_Carril VARCHAR2 (20 CHAR)  NOT NULL , 
     Numero              NUMBER  NOT NULL , 
     Terminal_ID         NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Carril_Terminal 
    ADD CONSTRAINT Carril_Terminal_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Datos_Conductor 
    ( 
     RUT                    NUMBER  NOT NULL , 
     Nombres                VARCHAR2 (50 CHAR)  NOT NULL , 
     Apellido_Paterno       VARCHAR2 (50 CHAR)  NOT NULL , 
     Apellido_Materno       VARCHAR2 (50 CHAR)  NOT NULL , 
     Telefono               VARCHAR2 (20 CHAR)  NOT NULL , 
     Telefono_Emergencia    VARCHAR2 (20 CHAR) , 
     Email                  VARCHAR2 (100 CHAR) , 
     Licencias_Conductor_ID NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Datos_Conductor 
    ADD CONSTRAINT Datos_Conductor_PK PRIMARY KEY ( RUT ) ;

CREATE TABLE Direcciones 
    ( 
     ID        NUMBER  NOT NULL , 
     Direccion VARCHAR2 (255 CHAR)  NOT NULL 
    ) 
;

ALTER TABLE Direcciones 
    ADD CONSTRAINT Direcciones_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Empresa 
    ( 
     ID             NUMBER  NOT NULL , 
     Nombre_Empresa VARCHAR2 (100 CHAR)  NOT NULL , 
     RUT            VARCHAR2 (20 CHAR)  NOT NULL , 
     Direcciones_ID NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Empresa 
    ADD CONSTRAINT Empresa_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Ficha_Mantenimiento 
    ( 
     ID                NUMBER  NOT NULL , 
     Fecha_Revision    DATE  NOT NULL , 
     Fecha_Vencimiento UNKNOWN 
--  ERROR: Datatype UNKNOWN is not allowed 
                     NOT NULL , 
     Planta_Revision   VARCHAR2 (100 CHAR)  NOT NULL , 
     Observaciones     CLOB 
    ) 
;

ALTER TABLE Ficha_Mantenimiento 
    ADD CONSTRAINT Ficha_Mantenimiento_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Horarios 
    ( 
     ID        NUMBER  NOT NULL , 
     Hora_Slot VARCHAR2 (5 CHAR)  NOT NULL 
    ) 
;

ALTER TABLE Horarios 
    ADD CONSTRAINT Horarios_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Licencias_Conductor 
    ( 
     ID                NUMBER  NOT NULL , 
     Tipo_Licencia     VARCHAR2 (10 CHAR)  NOT NULL , 
     Fecha_Vencimiento DATE  NOT NULL , 
     "estaHabilitada?" CHAR (1 CHAR) 
    ) 
;

ALTER TABLE Licencias_Conductor 
    ADD 
    CHECK ("estaHabilitada?" IN ('N', 'S')) 
;

ALTER TABLE Licencias_Conductor 
    ADD CONSTRAINT Licencias_Conductor_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Recorridos 
    ( 
     ID               NUMBER  NOT NULL , 
     Nombre_Recorrido VARCHAR2 (30 CHAR)  NOT NULL , 
     Descripcion      CLOB , 
     Direcciones_ID2  NUMBER  NOT NULL , 
     Direcciones_ID   NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Recorridos 
    ADD CONSTRAINT Recorridos_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Registro_Recorrido_Bus 
    ( 
     ID                     NUMBER  NOT NULL , 
     Hora_Ejecucion_Entrada DATE , 
     Hora_Ejecucion_Salida  DATE , 
     Fecha_Recorrido        DATE  NOT NULL , 
     Datos_Conductor_RUT    NUMBER  NOT NULL , 
     Carril_Terminal_ID     NUMBER  NOT NULL , 
     Carril_Terminal_ID2    NUMBER  NOT NULL , 
     Recorridos_ID          NUMBER  NOT NULL , 
     Horarios_ID            NUMBER  NOT NULL , 
     Horarios_ID2           NUMBER  NOT NULL , 
     Bus_Patente            NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Terminal 
    ( 
     ID              NUMBER  NOT NULL , 
     Nombre_Terminal VARCHAR2 (50 CHAR)  NOT NULL , 
     Cant_Carriles   NUMBER  NOT NULL , 
     Direcciones_ID  NUMBER  NOT NULL 
    ) 
;

ALTER TABLE Terminal 
    ADD CONSTRAINT Terminal_PK PRIMARY KEY ( ID ) ;

ALTER TABLE Bus 
    ADD CONSTRAINT Bus_Empresa_FK FOREIGN KEY 
    ( 
     Empresa_ID
    ) 
    REFERENCES Empresa 
    ( 
     ID
    ) 
;

ALTER TABLE Bus 
    ADD CONSTRAINT Bus_Ficha_Mantenimiento_FK FOREIGN KEY 
    ( 
     Ficha_Mantenimiento_ID
    ) 
    REFERENCES Ficha_Mantenimiento 
    ( 
     ID
    ) 
;

ALTER TABLE Carril_Terminal 
    ADD CONSTRAINT Carril_Terminal_Terminal_FK FOREIGN KEY 
    ( 
     Terminal_ID
    ) 
    REFERENCES Terminal 
    ( 
     ID
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Datos_Conductor 
    ADD CONSTRAINT Datos_Conductor_Licencias_Conductor_FK FOREIGN KEY 
    ( 
     Licencias_Conductor_ID
    ) 
    REFERENCES Licencias_Conductor 
    ( 
     ID
    ) 
;

ALTER TABLE Empresa 
    ADD CONSTRAINT Empresa_Direcciones_FK FOREIGN KEY 
    ( 
     Direcciones_ID
    ) 
    REFERENCES Direcciones 
    ( 
     ID
    ) 
;

ALTER TABLE Recorridos 
    ADD CONSTRAINT Recorridos_Direcciones_FK FOREIGN KEY 
    ( 
     Direcciones_ID
    ) 
    REFERENCES Direcciones 
    ( 
     ID
    ) 
;

ALTER TABLE Recorridos 
    ADD CONSTRAINT Recorridos_Direcciones_FKv2 FOREIGN KEY 
    ( 
     Direcciones_ID2
    ) 
    REFERENCES Direcciones 
    ( 
     ID
    ) 
;

ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Bus_FK FOREIGN KEY 
    ( 
     Bus_Patente
    ) 
    REFERENCES Bus 
    ( 
     Patente
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Carril_Terminal_FK FOREIGN KEY 
    ( 
     Carril_Terminal_ID
    ) 
    REFERENCES Carril_Terminal 
    ( 
     ID
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Carril_Terminal_FKv2 FOREIGN KEY 
    ( 
     Carril_Terminal_ID2
    ) 
    REFERENCES Carril_Terminal 
    ( 
     ID
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Datos_Conductor_FK FOREIGN KEY 
    ( 
     Datos_Conductor_RUT
    ) 
    REFERENCES Datos_Conductor 
    ( 
     RUT
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Horarios_FK FOREIGN KEY 
    ( 
     Horarios_ID
    ) 
    REFERENCES Horarios 
    ( 
     ID
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Horarios_FKv2 FOREIGN KEY 
    ( 
     Horarios_ID2
    ) 
    REFERENCES Horarios 
    ( 
     ID
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE Registro_Recorrido_Bus 
    ADD CONSTRAINT Registro_Recorrido_Bus_Recorridos_FK FOREIGN KEY 
    ( 
     Recorridos_ID
    ) 
    REFERENCES Recorridos 
    ( 
     ID
    ) 
;

ALTER TABLE Terminal 
    ADD CONSTRAINT Terminal_Direcciones_FK FOREIGN KEY 
    ( 
     Direcciones_ID
    ) 
    REFERENCES Direcciones 
    ( 
     ID
    ) 
;



-- Informe de Resumen de Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                            11
-- CREATE INDEX                             0
-- ALTER TABLE                             27
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   8
-- WARNINGS                                 0
