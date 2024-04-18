-- 定义变量
DECLARE 
	@ItemCode NVARCHAR(50),
	@ItemName NVARCHAR(100),
	@ManBtchNum NVARCHAR(1),
	@ManSerNum NVARCHAR(1),
    @OnHand NUMERIC(19,6),
    @InvntryUom NVARCHAR(8),
    @WhsCode NVARCHAR(8),
    @BatchCode NVARCHAR(30),
    @SerialCode NVARCHAR(30),
    @BOKey int,
    @BOCode NVARCHAR(30),
    @Count int,
   	@DocumentType NVARCHAR(30),
   	@DocumentEntry int,
   	@DocumentLine int;
-- 定义游标
DECLARE items_cursor CURSOR FOR
SELECT
	T0.[ItemCode],
	T1.ItemName,
	T1.ManBtchNum,
	T1.ManSerNum,
	T0.[OnHand],
	T1.InvntryUom,
	T0.[WhsCode]
FROM (
SELECT T0.[ItemCode], T0.[WhsCode], T0.[OnHand]
FROM OITW T0
WHERE T0.[OnHand] > 0
) T0 INNER JOIN OITM T1 ON T0.ItemCode = T1.ItemCode;

SET @Count = 0;
SET @DocumentType = 'AVA_MM_GOODSRECEIPT';
SET @DocumentEntry = 0;
SET @DocumentLine = 0;

-- 循环游标，并处理数据
OPEN items_cursor;
FETCH NEXT FROM items_cursor
	INTO @ItemCode, @ItemName, @ManBtchNum, @ManSerNum, @OnHand, @InvntryUom, @WhsCode;
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Count = @Count + 1;
	PRINT '#' + Cast(@Count as NVARCHAR) + ': ' + @ItemCode + '  ' + @ItemName;
-- 构建入库单据，每1000行物料，重新创建入库单
	IF @Count > 1000
	BEGIN
		SET @DocumentEntry = 0;
	END	
	IF @DocumentEntry = 0
	BEGIN
    	SET @DocumentEntry = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @DocumentType);
		INSERT INTO ibas_demo.dbo.AVA_MM_OIGN (DocEntry, Canceled, Status, ApvlStatus, DocStatus, ObjectCode, DataSource, DocDate, DocDueDate, TaxDate, Ref1)
			VALUES(@DocumentEntry, 'N', 'O', 'U', 'R', @DocumentType, 'SQL', GetDate(), GetDate(), GetDate(), N'期初');
		UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @DocumentEntry + 1 WHERE ObjectCode = @DocumentType;
		SET @DocumentLine = 0;
	END
	SET @DocumentLine = @DocumentLine + 1;
	INSERT INTO ibas_demo.dbo.AVA_MM_IGN1 (DocEntry, LineId, Canceled, Status, LineStatus, ObjectCode, ItemCode, Dscription, SerialMgment, BatchMgment, Quantity, UOM, WhsCode)
		VALUES(@DocumentEntry, @DocumentLine, 'N', 'O', 'R', @DocumentType, @ItemCode, @ItemName, @ManSerNum, @ManBtchNum, @OnHand, @InvntryUom, @WhsCode);
-- 入库记录
    SET @BOCode = 'AVA_MM_INVENTORYJOURNAL';
    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);
   	INSERT INTO ibas_demo.dbo.AVA_MM_OINM (ItemCode, ItemName, WhsCode, Direction, Quantity, DocDate, ObjectKey, ObjectCode, DataSource, BaseType, BaseEntry, BaseLine)
		VALUES(@ItemCode, @ItemName, @WhsCode, N'I', @OnHand, GetDate(), @BOKey, @BOCode, 'JNL-REG', @DocumentType, @DocumentEntry, @DocumentLine);
	UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
-- 增加仓库物料库存	
	IF NOT EXISTS (SELECT 0 FROM ibas_demo.dbo.AVA_MM_OITW WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode)
	BEGIN
		SET @BOCode = 'AVA_MM_INVENTORY';
	    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);
	   	INSERT INTO ibas_demo.dbo.AVA_MM_OITW (ItemCode, WhsCode, OnHand, OnCommited, OnOrdered, OnReserved, ObjectKey, ObjectCode, DataSource)
			VALUES(@ItemCode, @WhsCode, 0, 0, 0, 0, @BOKey, @BOCode, 'SQL');
		UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
	END
	UPDATE ibas_demo.dbo.AVA_MM_OITW SET OnHand = OnHand + @OnHand WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode;
-- 增加物料库存	
	IF NOT EXISTS (SELECT 0 FROM ibas_demo.dbo.AVA_MM_OITM WHERE Code = @ItemCode)
	BEGIN
		SET @BOCode = 'AVA_MM_MATERIAL';
	    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
	   	INSERT INTO ibas_demo.dbo.AVA_MM_OITM (Code, Name, Activated, Deleted, ApvlStatus, ItemType, InvntItem, PhantomItem, InvntUom, OnHand, OnCommited, OnOrdered, OnReserved, SerialMgment, BatchMgment, DocEntry, ObjectCode, DataSource)
			VALUES(@ItemCode, @ItemName, 'Y', 'N', 'U', 'I', 'Y', 'N', @InvntryUom, 0, 0, 0, 0, @ManSerNum, @ManBtchNum, @BOKey, @BOCode, 'SQL');
		UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
	END
	UPDATE ibas_demo.dbo.AVA_MM_OITM SET OnHand = OnHand + @OnHand WHERE Code = @ItemCode;
-- 批次管理物料
	IF @ManBtchNum = 'Y'
	BEGIN
		DECLARE batch_cursor CURSOR FOR
			SELECT T0.[BatchNum],SUM(T0.[Quantity])
			FROM OIBT T0
			WHERE T0.[ItemCode] = @ItemCode AND T0.[WhsCode] = @WhsCode AND T0.[Quantity] > 0
			GROUP BY T0.[ItemCode], T0.[WhsCode], T0.[BatchNum];
		
		OPEN batch_cursor;
		FETCH NEXT FROM batch_cursor INTO @BatchCode, @OnHand;
		WHILE @@FETCH_STATUS = 0
		BEGIN
-- 构建入库单据
		    SET @BOCode = 'AVA_MM_BATCHITEM';
		    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
			INSERT INTO ibas_demo.dbo.AVA_MM_OMBI (BatchCode, Quantity, BaseType, BaseEntry, BaseLine, ObjectKey, ObjectCode)
				VALUES(@BatchCode, @OnHand, @DocumentType, @DocumentEntry, @DocumentLine, @BOKey, @BOCode);
			UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
-- 入库记录
		    SET @BOCode = 'AVA_MM_BATCHJOURNAL';
		    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
		   	INSERT INTO ibas_demo.dbo.AVA_MM_MBT1 (ItemCode, BatchCode, WhsCode, Direction, Quantity, DocDate, ObjectKey, ObjectCode, DataSource, BaseType, BaseEntry, BaseLine)
				VALUES(@ItemCode, @BatchCode, @WhsCode, N'I', @OnHand, GetDate(), @BOKey, @BOCode, 'JNL-REG', @DocumentType, @DocumentEntry, @DocumentLine);
			UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
-- 增加批次库存
			IF NOT EXISTS (SELECT 0 FROM ibas_demo.dbo.AVA_MM_OMBT WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode AND BatchCode = @BatchCode)
			BEGIN				
			    SET @BOCode = 'AVA_MM_BATCH';
			    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
			   	INSERT INTO ibas_demo.dbo.AVA_MM_OMBT (ItemCode, BatchCode, WhsCode, Quantity, Locked, ReserveQty, ObjectKey, ObjectCode, DataSource)
					VALUES(@ItemCode, @BatchCode, @WhsCode, 0, 'N', 0, @BOKey, @BOCode, 'SQL');
				UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
			END	
			UPDATE ibas_demo.dbo.AVA_MM_OMBT SET Quantity = Quantity + @OnHand WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode AND BatchCode = @BatchCode;
		
			FETCH NEXT FROM batch_cursor INTO @BatchCode, @OnHand;
		END
		CLOSE batch_cursor;
		DEALLOCATE batch_cursor;
	END
-- 序列号管理物料
	IF @ManSerNum = 'Y'
	BEGIN
		DECLARE serial_cursor CURSOR FOR
			SELECT T0.[IntrSerial],1 [Quantity]
			FROM OSRI T0
			WHERE T0.[ItemCode] = @ItemCode AND T0.[WhsCode] = @WhsCode AND T0.[Status] = 1
			GROUP BY T0.[ItemCode], T0.[WhsCode], T0.[IntrSerial];
		
		OPEN serial_cursor;
		FETCH NEXT FROM serial_cursor INTO @SerialCode, @OnHand;
		WHILE @@FETCH_STATUS = 0
		BEGIN
-- 构建入库单据
		    SET @BOCode = 'AVA_MM_SERIALITEM';
		    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
			INSERT INTO ibas_demo.dbo.AVA_MM_OMSI (SerialCode, BaseType, BaseEntry, BaseLine, ObjectKey, ObjectCode)
				VALUES(@SerialCode, @DocumentType, @DocumentEntry, @DocumentLine, @BOKey, @BOCode);
			UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
-- 入库记录
		    SET @BOCode = 'AVA_MM_SERIALJOURNAL';
		    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
		   	INSERT INTO ibas_demo.dbo.AVA_MM_MSR1 (ItemCode, SerialCode, WhsCode, Direction, Quantity, DocDate, ObjectKey, ObjectCode, DataSource, BaseType, BaseEntry, BaseLine)
				VALUES(@ItemCode, @SerialCode, @WhsCode, N'I', @OnHand, GetDate(), @BOKey, @BOCode, 'JNL-REG', @DocumentType, @DocumentEntry, @DocumentLine);
			UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
-- 序列号在库
			IF NOT EXISTS (SELECT 0 FROM ibas_demo.dbo.AVA_MM_OMSR WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode AND SerialCode = @SerialCode)
			BEGIN				
			    SET @BOCode = 'AVA_MM_SERIAL';
			    SET @BOKey = (SELECT TOP 1 AutoKey FROM ibas_demo.dbo.AVA_SYS_ONNM WHERE ObjectCode = @BOCode);	
			   	INSERT INTO ibas_demo.dbo.AVA_MM_OMSR (ItemCode, SerialCode, WhsCode, InStock, Locked, Reserved, ObjectKey, ObjectCode, DataSource)
					VALUES(@ItemCode, @SerialCode, @WhsCode, 'N', 'N', 'N', @BOKey, @BOCode, 'SQL');
				UPDATE ibas_demo.dbo.AVA_SYS_ONNM SET AutoKey = @BOKey + 1 WHERE ObjectCode = @BOCode;
			END	
			UPDATE ibas_demo.dbo.AVA_MM_OMSR SET InStock = 'Y'  WHERE ItemCode = @ItemCode AND WhsCode = @WhsCode AND SerialCode = @SerialCode;
		
			FETCH NEXT FROM serial_cursor INTO @SerialCode, @OnHand;
		END
		CLOSE serial_cursor;
		DEALLOCATE serial_cursor;	
	END
-- 处理下一条
	FETCH NEXT FROM items_cursor
		INTO @ItemCode, @ItemName, @ManBtchNum, @ManSerNum, @OnHand, @InvntryUom, @WhsCode;
END
CLOSE items_cursor;
DEALLOCATE items_cursor;

