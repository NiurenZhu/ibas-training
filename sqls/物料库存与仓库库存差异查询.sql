/* 比较物料与仓库库存差异 */
select T0.`Code`,T0.`DataSource`,T0.`CreateDate`,T0.`OnCommited`,T1.`OnCommited`,T0.`OnOrdered`,T1.`OnOrdered`,T0.`OnHand`,T1.`OnHand`
from `AVA_MM_OITM` T0 left join (
    select `ItemCode`,sum(`OnCommited`) as 'OnCommited',sum(`OnOrdered`) as 'OnOrdered',sum(`OnHand`) as 'OnHand'
    from `AVA_MM_OITW`
    group by `ItemCode`
) T1 on T0.`Code` = T1.`ItemCode`
where 
 ifnull(T0.`OnCommited`,0) <> ifnull(T1.`OnCommited`,0)
 or ifnull(T0.`OnOrdered`,0) <> ifnull(T1.`OnOrdered`,0)
 or ifnull(T0.`OnHand`,0) <> ifnull(T1.`OnHand`,0)
union all
select T0.`Code`,T0.`DataSource`,T0.`CreateDate`,T0.`OnCommited`,T1.`OnCommited`,T0.`OnOrdered`,T1.`OnOrdered`,T0.`OnHand`,T1.`OnHand`
from `AVA_MM_OITM` T0 right join (
    select `ItemCode`,sum(`OnCommited`) as 'OnCommited',sum(`OnOrdered`) as 'OnOrdered',sum(`OnHand`) as 'OnHand'
    from `AVA_MM_OITW`
    group by `ItemCode`
) T1 on T0.`Code` = T1.`ItemCode`
where
 ifnull(T0.`OnCommited`,0) <> ifnull(T1.`OnCommited`,0)
 or ifnull(T0.`OnOrdered`,0) <> ifnull(T1.`OnOrdered`,0)
 or ifnull(T0.`OnHand`,0) <> ifnull(T1.`OnHand`,0);