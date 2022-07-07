DROP DATABASE BuenasNoches
CREATE DATABASE BuenasNoches
GO
USE BuenasNoches

CREATE TABLE Hotel
(
	ID_Hotel INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	Nombre VARCHAR(50) NOT NULL,
	Direccion VARCHAR(150) NOT NULL,
	Telefono VARCHAR(11) NOT NULL
)
GO

CREATE TABLE Habitacion
(
	ID_Habitacion INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	Num_huesp INT NOT NULL,
	Nombre VARCHAR(60) NOT NULL,
	Precio_Noche MONEY NOT NULL,
	Disponible BIT NOT NULL DEFAULT(1),
	ID_Hotel INT NOT NULL,
	CONSTRAINT FK_HabitacionHotel FOREIGN KEY (ID_Hotel) 
		REFERENCES Hotel(ID_Hotel)
)
GO

GO
--Función para calcular el total a pagar por una habitación
CREATE FUNCTION dbo.FN_CalcularTotalHab
(
	@ID_Habitacion INT,
	@FechaInicio DATE,
	@FechaFin DATE
)
RETURNS MONEY
BEGIN
	DECLARE @TotalNoches MONEY
	SET @TotalNoches = (SELECT Habitacion.Precio_Noche
					    FROM Habitacion
	                    WHERE ID_Habitacion = @ID_Habitacion) * DATEDIFF(DAY, @FechaInicio,@FechaFin)
	RETURN @TotalNoches
END

GO

CREATE TABLE Cliente
(
	ID_Cliente VARCHAR(10) NOT NULL PRIMARY KEY,
	Nombre VARCHAR(50) NOT NULL,
	Apellido_Pat VARCHAR(20) NOT NULL,
	Apellido_Mat VARCHAR(20) NOT NULL,
	Telefono VARCHAR(11) NOT NULL,
	Correo VARCHAR(50) NOT NULL,
	RFC VARCHAR(13) NOT NULL,
	Num_Cuenta VARCHAR(30) NOT NULL,
	Num_Cuenta_Op VARCHAR(30)
)
GO

CREATE TABLE Reservacion
(
	ID_Reservacion INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	Fecha_Inicio DATE NOT NULL,
	Fecha_Fin DATE NOT NULL,
	Fecha_CheckIn DATE NOT NULL,
	Hora_CheckIn TIME NOT NULL,
	Fecha_CheckOut DATE,
	Hora_CheckOut TIME,
	ID_Habitacion INT NOT NULL,
	ID_Cliente VARCHAR(10) NOT NULL,
	Total_Estadia AS dbo.FN_CalcularTotalHab(ID_Habitacion, Fecha_Inicio, Fecha_Fin),
	Total_Cargos MONEY NOT NULL DEFAULT (0),
	CONSTRAINT FK_ReservacionHab FOREIGN KEY (ID_Habitacion) 
		REFERENCES Habitacion(ID_Habitacion),
	CONSTRAINT FK_ReservacionCli FOREIGN KEY (ID_Cliente) 
		REFERENCES Cliente(ID_Cliente),
	CONSTRAINT CK_FechaCheckIO 
		CHECK (Fecha_CheckOut > Fecha_CheckIn),
	CONSTRAINT CK_FechaInicioFin 
		CHECK (Fecha_Fin > Fecha_Inicio)
)
GO

CREATE TABLE Empleado
(	
	ID_Empleado VARCHAR(10) NOT NULL PRIMARY KEY,
	Nombre VARCHAR(50) NOT NULL,
	Apellido_Pat VARCHAR(20) NOT NULL,
	Apellido_Mat VARCHAR(20) NOT NULL,
	Fecha_Nac DATE NOT NULL,
	RFC VARCHAR(13) NOT NULL,
	ID_Jefe VARCHAR(10),
	Fecha_Ingreso DATE NOT NULL,
	Sueldo_Mes MONEY NOT NULL,
	Activo BIT NOT NULL,
	Fecha_Baja DATE,
	ID_Hotel INT NOT NULL,
	CONSTRAINT FK_EmpleadoHotel FOREIGN KEY (ID_Hotel) 
		REFERENCES Hotel(ID_Hotel),
	CONSTRAINT FK_EmpleadoJefe FOREIGN KEY (ID_Jefe) 
		REFERENCES Empleado(ID_Empleado),
	CONSTRAINT CK_EmpleadoJefe 
		CHECK (ID_Empleado != ID_Jefe)
)
GO

CREATE TABLE CategoriaRest
(
	ID_Categoria INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	Categoria VARCHAR(20)
)
GO

CREATE TABLE Restaurante
(
	ID_Restaurante VARCHAR(5) NOT NULL PRIMARY KEY,
	Nombre VARCHAR(50) NOT NULL,
	ID_Categoria INT NOT NULL,
	ID_Hotel INT NOT NULL,
	CONSTRAINT FK_RestauranteCategoria FOREIGN KEY (ID_Categoria) 
		REFERENCES CategoriaRest(ID_Categoria),
	CONSTRAINT FK_RestauranteHotel FOREIGN KEY (ID_Hotel) 
		REFERENCES Hotel(ID_Hotel),
)
GO

CREATE TABLE Menu
(
	ID_Platillo VARCHAR(5) NOT NULL PRIMARY KEY,
	Nombre VARCHAR(50) NOT NULL,
	Precio MONEY NOT NULL
)
GO

CREATE TABLE Menu_Restaurante
(
	ID_Restaurante VARCHAR(5) NOT NULL,
	ID_Platillo VARCHAR(5) NOT NULL,
	CONSTRAINT FK_MenuRest_Rest FOREIGN KEY(ID_Restaurante) 
		REFERENCES Restaurante(ID_Restaurante),
	CONSTRAINT FK_MenuRest_Menu FOREIGN KEY (ID_Platillo) 
		REFERENCES Menu(ID_Platillo),
	CONSTRAINT CPK_Rest_Platillo PRIMARY KEY (ID_Restaurante, ID_Platillo)
)
GO

--Encabezado de un pedido de platillos consumidos
CREATE TABLE Registro_Consumo
(
	ID_Consumo INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	ID_Reservacion INT NOT NULL,
	Fecha_Consumo DATE  NOT NULL,
	Total MONEY NOT NULL DEFAULT(0),
	CONSTRAINT FK_RegistroConRes FOREIGN KEY (ID_Reservacion) 
		REFERENCES Reservacion(ID_Reservacion)
)
GO

--Función para calcular el total a pagar por cierta cantidad de un platillo
CREATE FUNCTION dbo.FN_CalcularTotalPlatillo
(
	@ID_Platillo VARCHAR(5),
	@Cantidad INT
)
RETURNS MONEY
BEGIN
	DECLARE @TotalPlatillo MONEY
	SET @TotalPlatillo = (SELECT Precio
					      FROM Menu
	                      WHERE ID_Platillo = @ID_Platillo) * @Cantidad
	RETURN @TotalPlatillo 
END

GO

--Listado de platillos consumidos de un pedido
CREATE TABLE Menu_Consumido
(
	ID_Consumo INT NOT NULL,
	ID_Restaurante VARCHAR(5) NOT NULL,
	ID_Platillo VARCHAR(5) NOT NULL,
	Cantidad INT NOT NULL,
	Total AS dbo.FN_CalcularTotalPlatillo(ID_Platillo, Cantidad),
	CONSTRAINT FK_MenuCon_Consumo FOREIGN KEY (ID_Consumo) 
		REFERENCES Registro_Consumo(ID_Consumo),
	CONSTRAINT FK_MenuCon_Rest FOREIGN KEY (ID_Restaurante, ID_Platillo) 
		REFERENCES Menu_Restaurante(ID_Restaurante, ID_Platillo),
	CONSTRAINT CPK_MenuCon_Plat PRIMARY KEY (ID_Consumo, ID_Restaurante, ID_Platillo),
)
GO

--Procedimiento para generar ID de un cliente
CREATE PROC SP_GenerarID
(
	@Nombre AS VARCHAR(50),
	@Apellido_Pat AS VARCHAR(20),
	@Apellido_Mat AS VARCHAR(20),
	@ID VARCHAR(10) OUTPUT --Parámetro de salida
)
AS
BEGIN
	SET @ID = UPPER(SUBSTRING(@Nombre,1,3) + SUBSTRING(@Apellido_Pat,1,1) 
		+ SUBSTRING(@Apellido_Mat,1,1)) + CONVERT(VARCHAR(5), FLOOR(RAND() *1000))  
	
	--Mientras exista un registro con ese ID, vuelvara a generar otro
	WHILE EXISTS(SELECT *
				 FROM Cliente
				 WHERE ID_Cliente =	@ID)
	BEGIN
		SET @ID = UPPER(SUBSTRING(@Nombre,1,3) + SUBSTRING(@Apellido_Pat,1,1) 
			+ SUBSTRING(@Apellido_Mat,1,1)) + CONVERT(VARCHAR(5), FLOOR(RAND() *1000))
	END
	SELECT @ID
END

GO
--1. Procedimiento para registrar un huesped
CREATE PROC SP_RegistrarHuesped 
(
	@Nombre VARCHAR(50),
	@Apellido_Pat VARCHAR(20),
	@Apellido_Mat VARCHAR(20),
	@Telefono VARCHAR(11),
	@Correo VARCHAR(50),
	@RFC VARCHAR(13),
	@Num_Cuenta VARCHAR(30),
	@Num_Cuenta_Op VARCHAR(30)
)
AS
BEGIN
	DECLARE @ID_Cliente VARCHAR(10)
	EXEC SP_GenerarID @Nombre, @Apellido_Pat, @Apellido_Mat, @ID_Cliente OUTPUT --El último parámetro es de salida
	INSERT INTO Cliente VALUES (@ID_Cliente, @Nombre,@Apellido_Pat, @Apellido_Mat, 
									@Telefono, @Correo, @RFC, @Num_Cuenta, @Num_Cuenta_Op)
	SELECT * FROM Cliente WHERE ID_Cliente = @ID_Cliente
END
GO

--2. Procedimiento para registrar una reversación
CREATE PROC SP_RegistrarReservacion
(
	@Fecha_Inicio DATE,
	@Fecha_Fin DATE,
	@Fecha_CheckIn DATE,
	@Hora_CheckIn TIME,
	@Fecha_CheckOut DATE,
	@Hora_CheckOut TIME,
	@ID_Habitacion INT,
	@ID_Cliente VARCHAR(10)
)
AS
BEGIN
	BEGIN TRY
		IF EXISTS (SELECT *
				   FROM Habitacion
			       WHERE ID_Habitacion = @ID_Habitacion AND Disponible = 1)
		BEGIN
			INSERT INTO Reservacion(Fecha_Inicio,Fecha_Fin,Fecha_CheckIn,Hora_CheckIn,Fecha_CheckOut,
						Hora_CheckOut, ID_Habitacion,ID_Cliente) 
			VALUES (@Fecha_Inicio, @Fecha_Fin, @Fecha_CheckIn, @Hora_CheckIn, 
					@Fecha_CheckOut, @Hora_CheckOut, @ID_Habitacion, @ID_Cliente)

			UPDATE Habitacion
			SET Disponible = 0
			WHERE ID_Habitacion = @ID_Habitacion

			SELECT *
			FROM Reservacion
			WHERE ID_Habitacion = @ID_Habitacion
			SELECT 'Reservación registrada existosamente'
		END
		ELSE
		BEGIN
			SELECT 'Lo sentimos. La habitación no está disponible por el momento'
		END
	END TRY
	BEGIN CATCH
		IF NOT EXISTS(SELECT * FROM Cliente WHERE ID_Cliente = @ID_Cliente)
			SELECT 'ERROR. El cliente no está registrado'
		IF NOT EXISTS(SELECT * FROM Habitacion WHERE ID_Habitacion = @ID_Habitacion)
			SELECT 'ERROR. La habitación no está registrada'
	END CATCH
END
GO


--3. Procedimiento para consultar una reservacion por email o RFC y la fecha de inicio
CREATE PROC SP_ConsultarReservacion
(
	@Fecha_Inicio DATE,
	@Correo VARCHAR(50),
	@RFC VARCHAR(50)
)
	
AS
BEGIN
	SELECT *
	FROM Reservacion INNER JOIN Cliente ON Reservacion.ID_Cliente = Cliente.ID_Cliente
	WHERE Fecha_Inicio = @Fecha_Inicio AND (Correo = @Correo OR RFC = @RFC) 
END
GO

--4. Procedimiento para el registro de consumo de un platillo en un restaurant
CREATE PROC SP_RegistrarConsumo
(
	@ID_Reservacion INT,
	@ID_Restaurante VARCHAR(5),
	@ID_Platillo VARCHAR(5),
	@Cantidad VARCHAR,
	@Fecha_Consumo DATE
)
AS
BEGIN
	IF EXISTS(SELECT *
			  FROM Reservacion
			  WHERE ID_Reservacion = @ID_Reservacion)	
	BEGIN
		IF EXISTS(SELECT *
				  FROM Menu_Restaurante
			      WHERE ID_Restaurante = @ID_Restaurante AND @ID_Platillo = ID_Platillo)
		BEGIN
			INSERT INTO Registro_Consumo(ID_Reservacion, Fecha_Consumo) VALUES(@ID_Reservacion, @Fecha_Consumo)
			DECLARE @ID_Consumo INT
			SET @ID_Consumo = (SELECT TOP 1 ID_Consumo
							  FROM Registro_Consumo
							  ORDER BY ID_Consumo DESC)
			INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante, ID_Platillo, Cantidad) 
			VALUES(@ID_Consumo, @ID_Restaurante, @ID_Platillo, @Cantidad)
		END
		ELSE
		BEGIN
			SELECT 'ERROR. El platillo no existe.'
		END
	END
	ELSE
	BEGIN
		SELECT 'ERROR. La reservación no existe.'
	END
END 
GO

--5. Procedimiento para consultar la cuenta de un restaurante
ALTER PROC SP_ConsultarCuentaRestaurant
(
	@ID_Habitacion INT,
	@ID_Restaurante VARCHAR(5)
)
AS
BEGIN
	SELECT M.Nombre, M.Precio, MC.Cantidad, MC.Total, RC.Fecha_Consumo
	FROM Menu_Consumido MC INNER JOIN Registro_Consumo RC ON MC.ID_Consumo = RC.ID_Consumo 
		INNER JOIN Reservacion R ON RC.ID_Reservacion = R.ID_Reservacion
		INNER JOIN Menu_Restaurante MR ON MC.ID_Platillo = MR.ID_Platillo 
		INNER JOIN Menu M ON M.ID_Platillo = MR.ID_Platillo
		INNER JOIN Restaurante Re ON Re.ID_Restaurante = MR.ID_Restaurante
		INNER JOIN Habitacion H ON R.ID_Habitacion = H.ID_Habitacion
	WHERE H.ID_Habitacion = @ID_Habitacion AND Re.ID_Restaurante = @ID_Restaurante
END
GO

--6. Función para calcular la cuenta total (estadia + cargos)
CREATE FUNCTION FN_Cuenta
(
	@ID_Reservacion INT
)
RETURNS MONEY
AS
BEGIN 
	DECLARE @TotalCuenta MONEY
	SET @TotalCuenta = (SELECT Total_Estadia + Total_Cargos
						FROM Reservacion R
						WHERE R.ID_Reservacion = @ID_Reservacion)
	RETURN @TotalCuenta
END
GO

--7. Procedimiento para consultar reservaciones en un invervalo de fechas de checkout
CREATE PROC SP_ConsultarReservaciones
(
	@FechaInicial DATE,
	@FechaFinal DATE
)
AS
BEGIN
SELECT C.Nombre + ' ' + C.Apellido_Pat + C.Apellido_Mat Cliente, H.ID_Habitacion M, R.Fecha_CheckIn, R.Fecha_CheckOut, [dbo].FN_Cuenta(R.ID_Reservacion) 'Total Reservación'
	FROM Reservacion R INNER JOIN Cliente C ON R.ID_Cliente = C.ID_Cliente
		INNER JOIN Habitacion H ON R.ID_Habitacion = H.ID_Habitacion
	WHERE R.Fecha_CheckOut BETWEEN @FechaInicial AND @FechaFinal
END
GO

--8. Procedimiento para consultar habitaciones disponibles
CREATE PROC SP_ConsultarHabDisp
AS
BEGIN
	SELECT *
	FROM Habitacion H
	WHERE H.Disponible = 1
END
GO

--Trigger para que se acumulen los mismos platillos en un menu consumido 
CREATE TRIGGER TR_AcumularMismoPlatillo
ON Menu_Consumido
INSTEAD OF INSERT 
AS
BEGIN
	DECLARE @ID_Consumo INT, @ID_Restaurante VARCHAR(5), @ID_Platillo VARCHAR(5), @Cantidad INT
	SELECT @ID_Consumo = [ID_Consumo],  @ID_Restaurante = [ID_Restaurante], @ID_Platillo = [ID_Platillo], @Cantidad =[Cantidad]
	FROM INSERTED

	IF EXISTS (SELECT * 
			   FROM Registro_Consumo RC
			   WHERE RC.ID_Consumo = @ID_Consumo)
	BEGIN
		IF EXISTS(SELECT * 
				  FROM Menu_Consumido 
				  WHERE ID_Consumo = @ID_Consumo AND ID_Restaurante = @ID_Restaurante  
						AND ID_Platillo = @ID_Platillo)
		BEGIN
			DECLARE @CantidadActual INT
			SET @CantidadActual = (SELECT Cantidad
								   FROM Menu_Consumido 
								   WHERE ID_Consumo = @ID_Consumo AND ID_Restaurante = @ID_Restaurante  
										 AND ID_Platillo = @ID_Platillo)
			UPDATE Menu_Consumido 
			SET Cantidad = @CantidadActual + @Cantidad 
			WHERE ID_Consumo = @ID_Consumo AND ID_Restaurante = @ID_Restaurante  
				  AND ID_Platillo = @ID_Platillo
			
			SELECT 'Se actualizó la cantidad de ' + Nombre 
			FROM Menu
			WHERE ID_Platillo = @ID_Platillo
		END 
		ELSE
		BEGIN 
			INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
			VALUES (@ID_Consumo, @ID_Restaurante, @ID_Platillo, @Cantidad)
		END
	END
	ELSE 
	BEGIN 
		SELECT 'Favor de generar primero el encabezado del consumo'
	END
END
GO

--Procedimiento para actualizar el total del registro consumo
CREATE PROC SP_ActualizarConsumo
(
	@ID_Consumo AS INT
)
AS
BEGIN 
	UPDATE Registro_Consumo 
	SET Total =  (SELECT SUM(MC.Total)
				 FROM Registro_Consumo RC 
				 INNER JOIN Menu_Consumido MC ON RC.ID_Consumo = MC.ID_Consumo
				 WHERE RC.ID_Consumo = @ID_Consumo)
	WHERE ID_Consumo = @ID_Consumo
END
GO

--Procedimiento para actualizar el total de cargos de una reservación
CREATE PROC SP_ActualizarCargos
(
	@ID_Reservacion AS INT
)
AS
BEGIN
	UPDATE Reservacion
	SET Total_Cargos = (SELECT SUM(RC.Total)
						FROM Registro_Consumo RC
						INNER JOIN Reservacion R ON RC.ID_Reservacion = R.ID_Reservacion
						WHERE  R.ID_Reservacion = @ID_Reservacion)
	FROM Registro_Consumo RC
	INNER JOIN Reservacion R ON RC.ID_Reservacion = R.ID_Reservacion
	WHERE  R.ID_Reservacion = @ID_Reservacion
END
GO

--Trigger para actualizar el total de cargos al insertar un consumo
CREATE TRIGGER TR_ActualizarCargosIns
ON Registro_Consumo
AFTER INSERT
AS
BEGIN 
	DECLARE @ID_Reservacion INT
	SELECT @ID_Reservacion = [ID_Reservacion]
	FROM INSERTED

	EXEC SP_ActualizarCargos @ID_Reservacion
END
GO

--Trigger para actualizar el total de cargos al actualizar un consumo
CREATE TRIGGER TR_ActualizarCargosAct
ON Registro_Consumo
AFTER UPDATE
AS
BEGIN 
	DECLARE @ID_Reservacion INT
	SELECT @ID_Reservacion = [ID_Reservacion]
	FROM INSERTED

	EXEC SP_ActualizarCargos @ID_Reservacion
END
GO

--Trigger para actualizar el total de cargos al eliminar un consumo
CREATE TRIGGER TR_ActualizarCargosEl
ON Registro_Consumo
AFTER DELETE
AS
BEGIN 
	DECLARE @ID_Reservacion INT
	SELECT @ID_Reservacion = [ID_Reservacion]
	FROM DELETED

	EXEC SP_ActualizarCargos @ID_Reservacion
END
GO

--Trigger para actualizar el total del registro al insertar un consumo
CREATE TRIGGER TR_ActualizarConsumoIns
ON Menu_Consumido
FOR INSERT
AS
BEGIN

	DECLARE @ID_Consumo INT
	SELECT @ID_Consumo = [ID_Consumo]
	FROM INSERTED

	EXEC SP_ActualizarConsumo @ID_Consumo
END
GO

--Trigger para actualizar el total del registro al actualizar un consumo
CREATE TRIGGER TR_ActualizarConsumoAct
ON Menu_Consumido
AFTER UPDATE
AS
BEGIN

	DECLARE @ID_Consumo INT
	SELECT @ID_Consumo = [ID_Consumo]
	FROM INSERTED

	EXEC SP_ActualizarConsumo @ID_Consumo
END
GO

--Trigger para actualizar el total del registro al eliminar un consumo
CREATE TRIGGER TR_ActualizarConsumoEl
ON Menu_Consumido
AFTER DELETE
AS
BEGIN

	DECLARE @ID_Consumo INT
	SELECT @ID_Consumo = [ID_Consumo]
	FROM DELETED

	EXEC SP_ActualizarConsumo @ID_Consumo
END
GO

INSERT INTO Hotel VALUES ('La playa', 'Colonia centro', '911')
INSERT INTO Habitacion VALUES (5, 'Hab 1', 500, 1, 1)
INSERT INTO Habitacion VALUES (5, 'Hab 2', 1000, 1, 1)

INSERT INTO CategoriaRest VALUES
('Mexicana'),('Japonesa')


INSERT INTO Restaurante VALUES ('abc','La piñata', 1, 1)
SELECT * FROM Restaurante

INSERT INTO Menu VALUES('A', 'Tacos de bistec', 60)
INSERT INTO Menu VALUES('B', 'Tacos de trompo', 65)
INSERT INTO Menu VALUES('C', 'Tacos de guisos', 80)
SELECT * FROM Menu

INSERT INTO Menu_Restaurante VALUES ('abc', 'A')
INSERT INTO Menu_Restaurante VALUES ('abc', 'B')
INSERT INTO Menu_Restaurante VALUES ('abc', 'C')
SELECT * FROM Menu_Restaurante

--1. Procedimiento para registrar un huesped
EXEC SP_RegistrarHuesped 'Pedro', 'Saenz', 'Perez', '811', 'smdfs@gmail.com', 'DASDS', '454', NULL
EXEC SP_RegistrarHuesped 'Juan', 'Saenz', 'Perez', '811', 'smdfs@gmail.com', 'DASDS', '454', NULL
SELECT * FROM Cliente


--2. Procedimiento para registrar una reversación
SP_RegistrarReservacion '2022-05-05', '2022-05-06', '2022-05-05', '00:00:00', NULL, NULL, 1, 'PEDSP304'
SP_RegistrarReservacion '2022-05-05', '2022-05-10', '2022-05-05', '00:00:00', NULL, NULL, 2, 'JUASP502'
SELECT * FROM Reservacion

--Encabezado del consumo
INSERT INTO Registro_Consumo(ID_Reservacion, Fecha_Consumo) 
VALUES (1, '2022-05-05')

INSERT INTO Registro_Consumo(ID_Reservacion, Fecha_Consumo) 
VALUES (2, '2022-05-05')

INSERT INTO Registro_Consumo(ID_Reservacion, Fecha_Consumo) 
VALUES (2, '2022-05-05')

SELECT * FROM Registro_Consumo

--Lista de platillos consumidos
INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
VALUES (1,'abc', 'A', 10)

INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
VALUES (1,'abc', 'B', 10)

INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
VALUES (2,'abc', 'C', 2)

INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
VALUES (3,'abc', 'A', 2)

INSERT INTO Menu_Consumido(ID_Consumo, ID_Restaurante,ID_Platillo,Cantidad) 
VALUES (3,'abc', 'A', 2)

SELECT *
FROM Menu_Consumido

SELECT *
FROM Registro_Consumo

SELECT *
FROM Reservacion

--3. Procedimiento para consultar una reservacion por email o RFC y la fecha de inicio
EXEC SP_ConsultarReservacion '2022-05-05', 'smdfs@gmail.com', 'DASDS'

--4. Procedimiento para el registro de consumo de un platillo en un restaurant
EXEC SP_RegistrarConsumo 2, 'abc', 'A', 5, '2022-05-16'

--5. Procedimiento para consultar la cuenta de un restaurante
EXEC SP_ConsultarCuentaRestaurant 1, 'abc'

--6. Función para calcular la cuenta total (estadia + cargos)
SELECT dbo.FN_Cuenta(1) 
GO
--7. Procedimiento para consultar reservaciones en un invervalo de fechas de checkout
EXEC SP_ConsultarReservaciones '2022-05-05', '2022-05-06'

--8. Procedimiento para consultar habitaciones disponibles
EXEC SP_ConsultarHabDisp