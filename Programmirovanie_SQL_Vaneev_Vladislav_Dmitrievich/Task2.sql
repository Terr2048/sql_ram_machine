-- = IT Planet, SQL 2017/18 =
-- = Task 2 =
--
-- with expressions as
--     (select 1 id, '2 3 4 + * 5 *' expr from dual
--       union all
--       select 2 id, '17 10 + 3 * 9 /' expr from dual
--       union all
--       select 3 id, '12.4 4 / 10 * 2 + 11 / 4 / 0.25 +' expr from dual
--      )
--
------ выполняет основные вычисления, решает задачу
---- expr - строка с выражениями в формате ' 1 2 +; 3 4 -; 5 6 *'
---- id - id выражения
, machine(expr, id) as (
	-- объединяем все строки с выражениями в одну
	select ' '||listagg(expr,'; ') within group(order by id), 1 from expressions
	union all
	select 
		case
			-- +
			when 							regexp_like(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \+(.*)')
			then 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \+(.*)', '\1') 
				|| to_char(		to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \+(.*)', '\2')) 
							+	to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \+(.*)', '\3'))) 
				|| 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \+(.*)', '\4')
			-- -
			when 							regexp_like(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \-(.*)')
			then 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \-(.*)', '\1') 
				|| to_char(		to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \-(.*)', '\2')) 
							-	to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \-(.*)', '\3'))) 
				|| 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \-(.*)', '\4')
			-- *
			when 							regexp_like(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \*(.*)')
			then 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \*(.*)', '\1') 
				|| to_char(		to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \*(.*)', '\2')) 
							*	to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \*(.*)', '\3'))) 
				|| 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \*(.*)', '\4')
			-- /
			when 							regexp_like(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \/(.*)')
			then 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \/(.*)', '\1') 
				|| to_char(		to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \/(.*)', '\2')) 
							/	to_number(	regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \/(.*)', '\3'))) 
				|| 							regexp_replace(	expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) \/(.*)', '\4')			
		end,
		id+1
		from machine
		-- продожать пока есть операторы и числа
		where regexp_like(expr, '(.* )(-?\d*\.?\d+) (-?\d*\.?\d+) [+-\*/](.*)')
)
------ парсит результаты, разбивает строку с ними на столбцы
---- str - строка с ответами в формате ' 1; 2; 3'
---- num - столбец с ответами
---- id - id выражения
, split(str, num, id) as (
	select expr, '', 0 
		from machine 
		where id = (select max(id) from machine)
	union all
	select
		-- удаляет результат первого выражения
		regexp_replace(str, '^ (-?\d*\.?\d+);?(.*)','\2'),
		-- сохраняет результат первого выражения в отдельный столбец
		regexp_replace(str, '^ (-?\d*\.?\d+);?(.*)','\1'),
		id+1
		from split
		-- продолжать пока есть числа
		where regexp_like(str, '(-?\d*\.?\d+)')
)
-- select expr from machine
-- select str from split
select split.id "ID", expr "EXPR", to_number(num) "RESULT"
	from split
	inner join expressions
	on split.id = expressions.id