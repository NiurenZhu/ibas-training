/* 修复销售订单的已承诺数量关系 */
drop procedure if exists `tmp_proc_material_estimate_commited`;
delimiter //
create procedure `tmp_proc_material_estimate_commited` (
)
begin
    declare done int default 0;
    declare docType varchar(30);
    declare docEntry int;
    declare docLine int;
    declare docQty decimal(19,6);
    declare itemCode varchar(20);
    declare itemName varchar(100);
    declare whsCode varchar(8);
    declare esKey int;
    declare estimate varchar(1) default 'C';
    declare esType varchar(30) default 'AVA_MM_ESTIMATEJOURNAL';

    declare docCursor cursor for 
        select T0.`ObjectCode`, T1.`DocEntry`, T1.`LineId`, T1.`Quantity` - T1.`ClosedQty` as 'OpenQty', T1.`ItemCode`, T1.`Dscription`, T1.`WhsCode`
        from `AVA_SL_ORDR` T0 inner join `AVA_SL_RDR1` T1 on T0.`DocEntry` = T1.`DocEntry`
        where (T0.`DocStatus` = 'R' or T0.`DocStatus` = 'F' or T0.`DocStatus` = 'C')        -- 单据状态（下达、完成、结算）
            and (T0.`ApvlStatus` = 'U' or T0.`ApvlStatus` = 'A')                            -- 审批状态（不影响、批准）
            and T0.`Deleted` = 'N' and T0.`Canceled` = 'N'                                  -- 未删除，未取消
            and (T1.`LineStatus` = 'R' or T1.`LineStatus` = 'F' or T1.`LineStatus` = 'C')   -- 行状态（下达、完成、结算）
            and T1.`Deleted` = 'N' and T1.`Canceled` = 'N'                                  -- 未删除，未取消
            and T1.`Quantity` > T1.`ClosedQty`;
    declare continue handler for not FOUND set done = 1;

    drop table if exists `~C_AVA_MM_OMEJ`;
    create table `~C_AVA_MM_OMEJ` (select T0.* from `AVA_MM_OMEJ` T0 where T0.`ObjectKey` > 0 and T0.`Estimate` = estimate);
    delete T0 from `AVA_MM_OMEJ` T0 where T0.`ObjectKey` > 0 and T0.`Estimate` = estimate;

    open docCursor;
    repeat
        fetch docCursor into docType, docEntry, docLine, docQty, itemCode, itemName, whsCode;
        if not done then
            if not exists (select 0 FROM `AVA_MM_OMEJ` where `BaseType` = docType and `BaseEntry` = docEntry and `BaseLine` = docLine and `Estimate` = estimate) then
                select `AutoKey` into esKey from `AVA_SYS_ONNM` where `ObjectCode` = esType limit 1;
                insert into `AVA_MM_OMEJ`(`ItemCode`, `ItemName`, `WhsCode`, `Estimate`, `Quantity`, `BaseType`, `BaseEntry`, `BaseLine`, `ObjectKey`, `ObjectCode`, `DataSource`)
                    values (itemCode, itemName, whsCode, estimate, docQty, docType, docEntry, docLine, esKey, esType, 'F');
                update `AVA_SYS_ONNM` set `AutoKey` = `AutoKey` + 1 where `ObjectCode` = esType limit 1;
            end if;
        end if;
    until done end repeat;
    close docCursor;

    update `AVA_MM_OITW` T0 inner join (
        select A.`ItemCode` as 'ItemCode',A.`WhsCode` as 'WhsCode',sum(A.`Quantity`) as 'Quantity'
        from `AVA_MM_OMEJ` A
        where A.`Estimate` = estimate
        group by A.`ItemCode`,A.`WhsCode`
    ) T1 on T0.`ItemCode` = T1.`ItemCode` and T0.`WhsCode` = T1.`WhsCode`
    set T0.`OnCommited` = T1.`Quantity` where T0.`ObjectKey` > 0;
        
    update `AVA_MM_OITM` T0 inner join (
        select A.`ItemCode` as 'ItemCode',sum(A.`OnCommited`) as 'Quantity'
        from `AVA_MM_OITW` A
        group by A.`ItemCode`
    ) T1 on T0.`Code` = T1.`ItemCode`
    set T0.`OnCommited` = T1.`Quantity` where T0.`DocEntry` > 0;
end;//
DELIMITER ;
call `tmp_proc_material_estimate_commited`();
drop procedure if exists `tmp_proc_material_estimate_commited`;
DELIMITER ;

/* 修复销采购的已订购数量关系 */
drop procedure if exists `tmp_proc_material_estimate_ordered`;
delimiter $$
create procedure `tmp_proc_material_estimate_ordered` (
)
begin
    declare done int default 0;
    declare docType varchar(30);
    declare docEntry int;
    declare docLine int;
    declare docQty decimal(19,6);
    declare itemCode varchar(20);
    declare itemName varchar(100);
    declare whsCode varchar(8);
    declare esKey int;
    declare estimate varchar(1) default 'O';
    declare esType varchar(30) default 'AVA_MM_ESTIMATEJOURNAL';
    
    declare docCursor cursor for 
        select T0.`ObjectCode`, T1.`DocEntry`, T1.`LineId`, T1.`Quantity` - T1.`ClosedQty` as 'OpenQty', T1.`ItemCode`, T1.`Dscription`, T1.`WhsCode`
        from `AVA_PH_OPOR` T0 inner join `AVA_PH_POR1` T1 on T0.`DocEntry` = T1.`DocEntry`
        where (T0.`DocStatus` = 'R' or T0.`DocStatus` = 'F' or T0.`DocStatus` = 'C')        -- 单据状态（下达、完成、结算）
            and (T0.`ApvlStatus` = 'U' or T0.`ApvlStatus` = 'A')                            -- 审批状态（不影响、批准）
            and T0.`Deleted` = 'N' and T0.`Canceled` = 'N'                                  -- 未删除，未取消
            and (T1.`LineStatus` = 'R' or T1.`LineStatus` = 'F' or T1.`LineStatus` = 'C')   -- 行状态（下达、完成、结算）
            and T1.`Deleted` = 'N' and T1.`Canceled` = 'N'                                  -- 未删除，未取消
            and T1.`Quantity` > T1.`ClosedQty`;
    declare continue handler for not found set done = 1;

    drop table if exists `~O_AVA_MM_OMEJ`;
    create table `~O_AVA_MM_OMEJ` (select T0.* from `AVA_MM_OMEJ` T0 where T0.`ObjectKey` > 0 and T0.`Estimate` = estimate);
    delete T0 from `AVA_MM_OMEJ` T0 where T0.`ObjectKey` > 0 and T0.`Estimate` = estimate;
    
    open docCursor;
    repeat
        fetch docCursor into docType, docEntry, docLine, docQty, itemCode, itemName, whsCode;
        if not done then
            if not exists (select 0 FROM `AVA_MM_OMEJ` where `BaseType` = docType and `BaseEntry` = docEntry and `BaseLine` = docLine and `Estimate` = estimate) then
                select `AutoKey` into esKey from `AVA_SYS_ONNM` where `ObjectCode` = esType limit 1;
                insert into `AVA_MM_OMEJ`(`ItemCode`, `ItemName`, `WhsCode`, `Estimate`, `Quantity`, `BaseType`, `BaseEntry`, `BaseLine`, `ObjectKey`, `ObjectCode`, `DataSource`)
                    values (itemCode, itemName, whsCode, estimate, docQty, docType, docEntry, docLine, esKey, esType, 'F');
                update `AVA_SYS_ONNM` set `AutoKey` = `AutoKey` + 1 where `ObjectCode` = esType limit 1;
            end if;
        end if;
    until done end repeat;
    close docCursor;
    
    update `AVA_MM_OITW` T0 inner join (
        select A.`ItemCode` as 'ItemCode',A.`WhsCode` as 'WhsCode',sum(A.`Quantity`) as 'Quantity'
        from `AVA_MM_OMEJ` A
        where A.`Estimate` = estimate
        group by A.`ItemCode`,A.`WhsCode`
    ) T1 on T0.`ItemCode` = T1.`ItemCode` and T0.`WhsCode` = T1.`WhsCode`
    set T0.`OnOrdered` = T1.`Quantity` where T0.`ObjectKey` > 0;
        
    update `AVA_MM_OITM` T0 inner join (
        select A.`ItemCode` as 'ItemCode',sum(A.`OnOrdered`) as 'Quantity'
        from `AVA_MM_OITW` A
        group by A.`ItemCode`
    ) T1 on T0.`Code` = T1.`ItemCode`
    set T0.`OnOrdered` = T1.`Quantity` where T0.`DocEntry` > 0;
end;$$
DELIMITER ;
call `tmp_proc_material_estimate_ordered`();
drop procedure if exists `tmp_proc_material_estimate_ordered`;
DELIMITER ;

/* 采购订单和已订购数量查询
-- 检查订单与预估数量
select T0.* 
from `AVA_MM_OMEJ` T0 inner join (
    select T0.`ObjectCode`, T1.`DocEntry`, T1.`LineId`, T1.`Quantity` - T1.`ClosedQty` as 'OpenQty', T1.`ItemCode`, T1.`Dscription`, T1.`WhsCode`
        from `AVA_PH_OPOR` T0 inner join `AVA_PH_POR1` T1 on T0.`DocEntry` = T1.`DocEntry`
        where (T0.`DocStatus` = 'R' or T0.`DocStatus` = 'F' or T0.`DocStatus` = 'C')
            and (T0.`ApvlStatus` = 'U' or T0.`ApvlStatus` = 'A')
            and T0.`Deleted` = 'N' and T0.`Canceled` = 'N'
            and (T1.`LineStatus` = 'R' or T1.`LineStatus` = 'F' or T1.`LineStatus` = 'C')
            and T1.`Deleted` = 'N' and T1.`Canceled` = 'N'
            and T1.`Quantity` > T1.`ClosedQty`
) T1 on T0.`BaseType` =  T1.`ObjectCode` and T0.`BaseEntry` =  T1.`DocEntry` and T0.`BaseLine` =  T1.`LineId`
where T0.`Estimate` = 'O' and T0.`Quantity` <> T1.`OpenQty`;
-- 检查预估与仓库数量
select T0.`ItemCode`,T0.`WhsCode`,T0.`OnOrdered`,T1.`Quantity`
from `AVA_MM_OITW` T0 inner join (
    select `ItemCode`,`WhsCode`,sum(`Quantity`) as 'Quantity'
    from `AVA_MM_OMEJ`
    where `Estimate` = 'O'
    group by `ItemCode`,`WhsCode`
) T1 on T0.`ItemCode` = T1.`ItemCode` and T0.`WhsCode` = T1.`WhsCode`
where T0.`OnOrdered` <> T1.`Quantity`;
-- 检查仓库预估与物料
select T0.`Code`,T0.`OnOrdered`,T1.`Quantity`
from `AVA_MM_OITM` T0 inner join (
    select `ItemCode`,sum(`OnOrdered`) as 'Quantity'
    from `AVA_MM_OITW`
    group by `ItemCode`
) T1 on T0.`Code` = T1.`ItemCode`
where T0.`OnOrdered` <> T1.`Quantity`;
*/
/* 销售订单和已承诺数量查询
-- 检查订单与预估数量
select T0.* 
from `AVA_MM_OMEJ` T0 inner join (
    select T0.`ObjectCode`, T1.`DocEntry`, T1.`LineId`, T1.`Quantity` - T1.`ClosedQty` as 'OpenQty', T1.`ItemCode`, T1.`Dscription`, T1.`WhsCode`
        from `AVA_SL_ORDR` T0 inner join `AVA_SL_RDR1` T1 on T0.`DocEntry` = T1.`DocEntry`
        where (T0.`DocStatus` = 'R' or T0.`DocStatus` = 'F' or T0.`DocStatus` = 'C')
            and (T0.`ApvlStatus` = 'U' or T0.`ApvlStatus` = 'A')
            and T0.`Deleted` = 'N' and T0.`Canceled` = 'N'
            and (T1.`LineStatus` = 'R' or T1.`LineStatus` = 'F' or T1.`LineStatus` = 'C')
            and T1.`Deleted` = 'N' and T1.`Canceled` = 'N'
            and T1.`Quantity` > T1.`ClosedQty`
) T1 on T0.`BaseType` =  T1.`ObjectCode` and T0.`BaseEntry` =  T1.`DocEntry` and T0.`BaseLine` =  T1.`LineId`
where T0.`Estimate` = 'C' and T0.`Quantity` <> T1.`OpenQty`;
-- 检查预估与仓库数量
select T0.`ItemCode`,T0.`WhsCode`,T0.`OnCommited`,T1.`Quantity`
from `AVA_MM_OITW` T0 inner join (
    select `ItemCode`,`WhsCode`,sum(`Quantity`) as 'Quantity'
    from `AVA_MM_OMEJ`
    where `Estimate` = 'C'
    group by `ItemCode`,`WhsCode`
) T1 on T0.`ItemCode` = T1.`ItemCode` and T0.`WhsCode` = T1.`WhsCode`
where T0.`OnCommited` <> T1.`Quantity`;
-- 检查仓库预估与物料
select T0.`Code`,T0.`OnCommited`,T1.`Quantity`
from `AVA_MM_OITM` T0 inner join (
    select `ItemCode`,sum(`OnCommited`) as 'Quantity'
    from `AVA_MM_OITW`
    group by `ItemCode`
) T1 on T0.`Code` = T1.`ItemCode`
where T0.`OnCommited` <> T1.`Quantity`;
*/